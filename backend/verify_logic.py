import sys
import os
import asyncio
from dotenv import load_dotenv

# Load env vars first
load_dotenv(r"c:\Users\MYPC\Desktop\intern\Dharma-CMS\backend\.env")

# Ensure backend in path
sys.path.append(r"c:\Users\MYPC\Desktop\intern\Dharma-CMS\backend")

# Import the function
from routers.cases import transliterate_fields

async def test():
    print("Testing Hybrid Transliteration...")
    
    data = {
        "title": "Theft Case",
        "district": "Hyderabad",         # Phonetic -> హైదరాబాద్
        "incidentDetails": "He ran away from the station.", # Semantic -> అతను స్టేషన్ నుండి పారిపోయాడు
        "accusedPersons": [
            {
                "name": "Ravi",          # Phonetic -> రవి
                "deformities": "Broken leg" # Semantic -> విరిగిన కాలు
            }
        ]
    }
    
    try:
        result = await transliterate_fields(data)
        import json
        with open("verification_output.json", "w", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        print("Output written to verification_output.json")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(test())
