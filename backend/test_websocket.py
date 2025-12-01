"""
Quick test script to verify WebSocket STT endpoint is working
Run this while the backend is running to test the connection
"""
import asyncio
import websockets
import json

async def test_stt_websocket():
    uri = "ws://localhost:8000/ws/stt"
    print(f"Connecting to {uri}...")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected! WebSocket is working.")
            
            # Send a small test audio chunk (just zeros)
            test_audio = b'\x00' * 1600  # 0.1 second of silence at 16kHz
            print(f"Sending test audio chunk ({len(test_audio)} bytes)...")
            await websocket.send(test_audio)
            
            # Wait for response
            print("Waiting for response...")
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                print(f"Received response: {response}")
                data = json.loads(response)
                print(f"Parsed: {data}")
            except asyncio.TimeoutError:
                print("No response received (timeout) - this is normal for silence")
            
            print("\nWebSocket test completed successfully!")
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_stt_websocket())
