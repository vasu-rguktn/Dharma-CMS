import time
import json
from loguru import logger
from datetime import datetime
from typing import Optional, Dict, Any

class GeminiTracker:
    """
    Centralized tracker for Gemini API usage and costs.
    Costs based on Gemini 1.5 Flash: 
    - Input: $0.075 / 1M tokens
    - Output: $0.30 / 1M tokens
    """
    
    PRICE_INPUT_1M = 0.075
    PRICE_OUTPUT_1M = 0.30

    def __init__(self):
        self.sessions: Dict[str, Dict[str, Any]] = {}

    def _get_session(self, session_id: Optional[str]) -> Dict[str, Any]:
        if not session_id:
            return None
        if session_id not in self.sessions:
            self.sessions[session_id] = {
                "total_calls": 0,
                "total_input_tokens": 0,
                "total_output_tokens": 0,
                "total_cost": 0.0,
                "start_time": time.time(),
                "calls": []
            }
        return self.sessions[session_id]

    def log_call(
        self,
        model: str,
        endpoint: str,
        prompt_chars: int,
        session_id: Optional[str] = None,
        tier: str = "Free"
    ):
        """Log the start of a Gemini call."""
        est_input_tokens = prompt_chars // 4
        
        logger.info(f"\n[GEMINI CALL] session={session_id} tier={tier}")
        logger.info(f"endpoint: {endpoint}")
        logger.info(f"model: {model}")
        logger.info(f"prompt_chars: {prompt_chars}")
        logger.info(f"est_input_tokens: {est_input_tokens}")
        
        return {
            "start_time": time.time(),
            "est_input_tokens": est_input_tokens
        }

    def log_response(
        self,
        call_info: Dict[str, Any],
        response: Any,
        session_id: Optional[str] = None
    ):
        """Log the response of a Gemini call and update session stats."""
        duration = time.time() - call_info["start_time"]
        
        # Exact values from metadata if available
        usage_meta = getattr(response, 'usage_metadata', None)
        input_tokens = usage_meta.prompt_token_count if usage_meta else call_info["est_input_tokens"]
        output_tokens = usage_meta.candidates_token_count if usage_meta else 0
        
        cost = (input_tokens * self.PRICE_INPUT_1M / 1_000_000) + \
               (output_tokens * self.PRICE_OUTPUT_1M / 1_000_000)
        
        logger.info(f"[GEMINI RESPONSE]")
        logger.info(f"input_tokens: {input_tokens}")
        logger.info(f"output_tokens: {output_tokens}")
        logger.info(f"duration: {duration:.2f}s")
        logger.info(f"estimated_cost: ${cost:.6f}\n")
        
        # Update session
        session = self._get_session(session_id)
        if session:
            session["total_calls"] += 1
            session["total_input_tokens"] += input_tokens
            session["total_output_tokens"] += output_tokens
            session["total_cost"] += cost
            session["calls"].append({
                "duration": duration,
                "cost": cost,
                "input": input_tokens,
                "output": output_tokens
            })

    def get_session_summary(self, session_id: str) -> str:
        """Generate a formatted report for a complaint session."""
        session = self.sessions.get(session_id)
        if not session:
            return f"No data found for session: {session_id}"
        
        duration = time.time() - session["start_time"]
        
        report = [
            "## Complaint Session Report",
            f"Complaint ID: {session_id.replace('complaint-session-', '')}",
            f"Gemini Calls: {session['total_calls']}",
            f"Total Input Tokens: {session['total_input_tokens']}",
            f"Total Output Tokens: {session['total_output_tokens']}",
            f"Estimated Cost: ${session['total_cost']:.6f}",
            f"Duration: {duration:.1f}s"
        ]
        return "\n".join(report)

# Singleton
gemini_tracker = GeminiTracker()
