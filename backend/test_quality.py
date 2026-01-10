import os
import re
from openai import OpenAI
from dotenv import load_dotenv

import sys
import codecs

# Force strict UTF-8 for stdout/stderr to avoid Windows cp1252 crash
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

# Load environment variables
load_dotenv()

HF_TOKEN = os.getenv("HF_TOKEN")
if not HF_TOKEN:
    print("Error: HF_TOKEN not found in .env")
    exit(1)

client = OpenAI(
    base_url="https://router.huggingface.co/v1",
    api_key=HF_TOKEN,
)

LLM_MODEL = "meta-llama/Meta-Llama-3-8B-Instruct"

def robust_clean_string(text):
    if not text:
        return ""
    # 1. Encode/Decode to valid UTF-8
    clean_text = text.encode("utf-8", "ignore").decode("utf-8")
    # 2. Hard clean
    clean_text = clean_text.replace("\ufffd", "").replace("\x00", "")
    # 3. Nuclear Logic (Allow Telugu + Basic Punctuation)
    # Range \u0C00-\u0C7F is Telugu.
    return re.sub(r'[^\u0C00-\u0C7F\x20-\x7E\n]', '', clean_text).strip()

def run_test_chat():
    print("=== STARTING TELUGU QUALITY TEST ===")
    
    initial_details = "నా బైక్ దొంగిలించబడింది" # "My bike was stolen"
    language = "te" # Telugu
    
    system_prompt = (
        "You are an expert Police Officer conducting an investigation in Telugu.\n\n"

        "GOAL: Ask relevant questions to understand the crime (Who, What, Where, When, How).\n"
        "RULES:\n"
        "1. NEVER repeat facts the user already said. (If user said 'Stolen at market', DO NOT ask 'Where was it stolen?').\n"
        "2. ASK SHORT, DIRECT QUESTIONS. One at a time.\n"
        "3. START DIRECTLY. Do not say 'Okay', 'I understand', 'Good'. Just ask.\n"
        "4. GRAMMAR: Ensure the sentence is complete and ends with '?'.\n\n"

        "LANGUAGE INSTRUCTIONS (TELUGU):\n"
        f"- You MUST respond in: {language}.\n"
        "- Speak like a human police officer, not a robot.\n"
        "- USE STANDARD QUESTIONS (Below):\n\n"

        "GOLDEN EXAMPLES (Copy these patterns):\n"
        "1. Location: 'ఘటన ఎక్కడ జరిగింది?' (Where did it happen?)\n"
        "2. Time: 'ఇది ఎప్పుడు జరిగింది?' (When did it happen?)\n"
        "3. Suspect: 'ఎవరైనా అనుమానంగా కనిపించారా?' (Did anyone look suspicious?)\n"
        "4. Details: 'బైక్ నంబర్ ఏంటి?' (What is the bike number?)\n"
        "5. Action: 'దొంగతనం జరిగినప్పుడు మీరు అక్కడ ఉన్నారా?' (Were you there?)\n\n"

        "BAD EXAMPLES (Avoid these):\n"
        "❌ 'మీరు చెప్పిన సమాచారం ప్రకారం...' (Do not summarize)\n"
        "❌ 'నేను ఒక ప్రశ్న అడుగుతాను...' (Do not announce)\n"
        "❌ 'దయచేసి చెప్పండి...' (Too formal/begging)\n\n"

        "If you have enough info (Incident, Place, Time, Lost Item), output: DONE"
    )

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": initial_details}
    ]

    print(f"\nUser: {initial_details}")

    # Simulate 3 turns
    for i in range(3):
        completion = client.chat.completions.create(
            model=LLM_MODEL,
            messages=messages,
            temperature=0.3,
            max_tokens=1024,
        )
        
        reply = completion.choices[0].message.content.strip()
        cleaned_reply = robust_clean_string(reply)
        
        print(f"\nAI (Raw): {reply}")
        print(f"AI (Cleaned): {cleaned_reply}")
        
        # Simulate user answer
        user_answer = "మార్కెట్ వద్ద"  # "At the market" (generic answer)
        if i == 1: user_answer = "నిన్న రాత్రి" # "Last night"
        
        print(f"User: {user_answer}")
        messages.append({"role": "assistant", "content": reply})
        messages.append({"role": "user", "content": user_answer})

if __name__ == "__main__":
    run_test_chat()
