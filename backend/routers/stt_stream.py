# stt_stream.py
import time
import queue
import threading
import sys
import signal
import os
import asyncio

import pyaudio
from google.cloud import speech
from google.oauth2 import service_account

# FastAPI imports for WebSocket support
from fastapi import APIRouter, WebSocket, WebSocketDisconnect

# Create FastAPI router
router = APIRouter()

RATE = 16000
CHUNK = int(RATE / 10)  # 100ms

# Path to your JSON (local dev). Remove in production.
KEY_FILE = "dharma-cms-5cc89-b74e10595572.json"

# Load credentials (local dev). In production prefer default credentials / metadata server.
# Handle both running from backend folder (FastAPI) and routers folder (standalone)
import os
if os.path.exists(KEY_FILE):
    credentials = service_account.Credentials.from_service_account_file(KEY_FILE)
elif os.path.exists(f"../{KEY_FILE}"):
    credentials = service_account.Credentials.from_service_account_file(f"../{KEY_FILE}")
else:
    raise FileNotFoundError(f"Could not find credentials file: {KEY_FILE}")

client = speech.SpeechClient(credentials=credentials)

config = speech.RecognitionConfig(
    encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
    sample_rate_hertz=RATE,
    language_code="en-US",
    enable_automatic_punctuation=True,
)

streaming_config = speech.StreamingRecognitionConfig(
    config=config,
    interim_results=True,
)

# A thread-safe queue to pass raw audio from the pyaudio callback to the generator
audio_q = queue.Queue()

# Flag used to stop threads
stop_event = threading.Event()

def audio_thread_func():
    """Read microphone and push chunks into audio_q until stopped."""
    audio_interface = pyaudio.PyAudio()
    try:
        stream = audio_interface.open(
            format=pyaudio.paInt16,
            channels=1,
            rate=RATE,
            input=True,
            frames_per_buffer=CHUNK,
        )
    except Exception as e:
        print("Failed to open microphone stream:", e, file=sys.stderr)
        stop_event.set()
        return

    print("Microphone stream opened. Speak into your microphone.")
    try:
        while not stop_event.is_set():
            try:
                chunk = stream.read(CHUNK, exception_on_overflow=False)
                audio_q.put(chunk)
            except Exception as e:
                # transient error reading the device — print, continue or break depending on severity
                print("Audio read error:", e, file=sys.stderr)
                time.sleep(0.1)
    finally:
        try:
            stream.stop_stream()
            stream.close()
            audio_interface.terminate()
        except Exception:
            pass
        print("Microphone thread stopped.")


def request_generator():
    """Yields StreamingRecognizeRequest messages from audio_q. Stops when stop_event is set."""
    # The Speech API expects repeated StreamingRecognizeRequest with audio_content
    while not stop_event.is_set():
        try:
            chunk = audio_q.get(timeout=0.5)
            if chunk is None:
                continue
            yield speech.StreamingRecognizeRequest(audio_content=chunk)
        except queue.Empty:
            # nothing to send this cycle — still keep the stream alive
            continue

def handle_responses(responses):
    """Iterate responses from Google and print interim / final transcripts."""
    try:
        for response in responses:
            if stop_event.is_set():
                break
            if not response.results:
                continue
            result = response.results[0]
            if result.is_final:
                print("Final:", result.alternatives[0].transcript)
            else:
                # interim
                print("Interim:", result.alternatives[0].transcript, end="\r")
    except Exception as e:
        print("Error handling responses:", e, file=sys.stderr)


# ============================================================================
# FastAPI WebSocket Endpoint for Flutter Integration
# ============================================================================

@router.websocket("/ws/stt")
async def websocket_stt_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time speech-to-text streaming from Flutter.
    Client sends audio chunks (LINEAR16, 16kHz, mono), server responds with transcripts.
    """
    await websocket.accept()
    print("WebSocket client connected")
    
    # Send immediate confirmation
    try:
        await websocket.send_json({
            "transcript": "Connected (Waiting for audio...)",
            "is_final": False,
            "confidence": 1.0
        })
        print("Sent initial connection confirmation")
    except Exception as e:
        print(f"Failed to send initial confirmation: {e}")
        return
    
    # Configure speech recognition (same as standalone mode)
    config = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=RATE,
        language_code="en-US",  # TODO: Make dynamic based on client preference
        # language_code="te-IN",  # TODO: Make dynamic based on client preference

        enable_automatic_punctuation=True,
    )
    
    streaming_config = speech.StreamingRecognitionConfig(
        config=config,
        interim_results=True,
    )
    
    try:
        import queue as queue_module
        import threading
        
        # Queues for communication between async and sync worlds
        audio_queue = queue_module.Queue()
        transcript_queue = asyncio.Queue()
        stop_event = threading.Event()
        
        # Capture the main event loop to use in the thread
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            loop = asyncio.get_event_loop()
        
        # Thread function to handle Google Speech API (sync)
        def speech_recognition_thread():
            def audio_generator():
                while not stop_event.is_set():
                    try:
                        chunk = audio_queue.get(timeout=0.5)
                        if chunk is None:
                            break
                        yield speech.StreamingRecognizeRequest(audio_content=chunk)
                    except queue_module.Empty:
                        continue
            
            try:
                print("Speech recognition thread started")
                responses = client.streaming_recognize(
                    config=streaming_config,
                    requests=audio_generator()
                )
                
                for response in responses:
                    if stop_event.is_set():
                        break
                    if not response.results:
                        continue
                    
                    result = response.results[0]
                    if not result.alternatives:
                        continue
                    
                    transcript = result.alternatives[0].transcript
                    is_final = result.is_final
                    confidence = result.alternatives[0].confidence if is_final else 0.0
                    
                    # Put in async queue using the captured loop
                    asyncio.run_coroutine_threadsafe(
                        transcript_queue.put({
                            "transcript": transcript,
                            "is_final": is_final,
                            "confidence": confidence
                        }),
                        loop
                    )
                    
                    if is_final:
                        print(f"Final: {transcript} (confidence: {confidence:.2f})")
                    else:
                        print(f"Interim: {transcript}", end="\r")
                        
            except Exception as e:
                print(f"Speech recognition error: {e}", file=sys.stderr)
                import traceback
                traceback.print_exc()
            finally:
                print("Speech recognition thread ended")
        
        # Start speech recognition thread
        speech_thread = threading.Thread(target=speech_recognition_thread, daemon=True)
        speech_thread.start()
        
        # Async task to receive audio from WebSocket
        async def receive_audio():
            chunk_count = 0
            try:
                while True:
                    data = await websocket.receive_bytes()
                    chunk_count += 1
                    if chunk_count % 10 == 0:
                        print(f"Received {chunk_count} audio chunks ({len(data)} bytes)")
                    audio_queue.put(data)
            except WebSocketDisconnect:
                print(f"Client disconnected after {chunk_count} chunks")
            except Exception as e:
                print(f"Error receiving audio: {e}", file=sys.stderr)
            finally:
                audio_queue.put(None)  # Signal end
        
        # Async task to send transcripts to WebSocket
        async def send_transcripts():
            try:
                while True:
                    transcript_data = await transcript_queue.get()
                    print(f"Sending to client: {transcript_data}")
                    await websocket.send_json(transcript_data)
            except Exception as e:
                print(f"Error sending transcript: {e}", file=sys.stderr)
        
        # Run both tasks concurrently
        print("Starting audio reception and transcript sending...")
        await asyncio.gather(
            receive_audio(),
            send_transcripts(),
            return_exceptions=True
        )
        
    except WebSocketDisconnect:
        print("WebSocket disconnected normally")
    except Exception as e:
        print(f"STT WebSocket Error: {e}", file=sys.stderr)
        try:
            await websocket.send_json({"error": str(e)})
        except:
            pass
    finally:
        try:
            await websocket.close()
        except:
            pass
        print("WebSocket connection closed")


# ============================================================================
# Standalone Script Mode (Original Functionality Preserved)
# ============================================================================

def main():
    # Start mic reading thread
    t = threading.Thread(target=audio_thread_func, daemon=True)
    t.start()

    # Setup a graceful shutdown on Ctrl+C
    def shutdown(signum, frame):
        print("\nShutting down...")
        stop_event.set()

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    try:
        while not stop_event.is_set():
            # create a fresh generator for each streaming session
            requests = request_generator()
            responses = client.streaming_recognize(config=streaming_config, requests=requests)

            # process responses in main thread (blocking) until an exception or stop
            try:
                handle_responses(responses)
            except Exception as e:
                print("Streaming error, will attempt to reconnect:", e, file=sys.stderr)
                # backoff before reconnecting
                time.sleep(1.0)
                continue

            # If responses loop exits normally, sleep briefly and restart
            time.sleep(0.2)
    finally:
        stop_event.set()
        t.join(timeout=2.0)
        print("Exited.")

if __name__ == "__main__":
    main()
