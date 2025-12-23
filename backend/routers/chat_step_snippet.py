
@router.post(
    "/chat-step",
    response_model=ChatStepResponse,
    status_code=status.HTTP_200_OK,
)
async def chat_step(payload: ChatStepRequest):
    """
    Dynamic chat turn.
    Decides whether to ask another question or finalize the complaint.
    """
    try:
        # 1. Resolve Language
        language = resolve_language(payload.language)
        
        # 2. Build Context for LLM
        # We need to present the current state to the LLM
        # "You are a police officer taking a complaint..."
        
        system_prompt = (
            "You are an expert police officer (Virtual Station Writer) taking a formal complaint (FIR) or petition details from a citizen. "
            "Your goal is to collect ALL necessary details to file a complete report. "
            "\n\n"
            "CURRENT KNOWN DETAILS:\n"
            f"Name: {payload.full_name}\n"
            f"Address: {payload.address}\n"
            f"Phone: {payload.phone}\n"
            f"Type: {payload.complaint_type}\n"
            f"Initial Description: {payload.initial_details}\n"
            "\n"
            "INSTRUCTIONS:\n"
            "1. Analyze the 'Initial Description' and the 'Conversation History' below.\n"
            "2. Decide if you have sufficient information to file a formal complaint (Who, What, When, Where, Why/How, Evidence).\n"
            "3. If details are missing, ask ONE specific, clear follow-up question to get that information.\n"
            "4. If you have enough information, rely ONLY with the word 'DONE'. Do not ask more questions.\n"
            "5. If the user is uncooperative or vague, ask for clarification.\n"
            f"6. IMPORTANT: You must respond in the language: {language} (if 'te' is Telugu, if 'en' is English).\n"
            "7. Keep questions short and professional.\n"
        )
        
        # Convert Pydantic chat history to LLM format
        messages = [{"role": "system", "content": system_prompt}]
        for msg in payload.chat_history:
            messages.append({"role": msg.role, "content": msg.content})
            
        # 3. Call LLM
        if not HF_TOKEN:
             # Fallback if no token (demo mode) -> just say DONE or ask generic
             return ChatStepResponse(status="done", final_response=None)

        completion = client.chat.completions.create(
            model=LLM_MODEL,
            messages=messages,
            temperature=0.3,
            max_tokens=150,
        )
        
        reply = completion.choices[0].message.content.strip()
        
        # 4. Check for DONE
        # Remove punctuation to be safe "DONE." or "Done"
        clean_reply = re.sub(r"[^a-zA-Z]", "", reply).upper()
        
        if clean_reply == "DONE" or "DONE" in clean_reply.split():
            # Generate final summary
            # We need to combine initial details + chat history into one big "details" string for the summarizer
            full_transcript = f"{payload.initial_details}\n\nTranscript:\n"
            for msg in payload.chat_history:
                role_label = "User" if msg.role == "user" else "Officer"
                full_transcript += f"{role_label}: {msg.content}\n"
            
            # Create a mock ComplaintRequest to reuse existing logic
            final_req = ComplaintRequest(
                full_name=payload.full_name,
                address=payload.address,
                phone=payload.phone,
                complaint_type=payload.complaint_type,
                details=full_transcript,
                language=payload.language
            )
            
            # Use existing summarization logic
            # We can call process_complaint logic directly or refactor. 
            # Ideally refactor process_complaint to be a helper, but for now let's reuse valid parts.
            
            formal_summary, localized_fields = generate_summary_text(final_req)
            
            classification_context = _build_classification_context(
                final_req.complaint_type,
                final_req.details,
                language,
                localized_fields,
            )
            
            classification = classify_offence(
                formal_summary,
                complaint_type=final_req.complaint_type,
                details=final_req.details,
                classification_text=classification_context,
            )
            
            classification_display = classification
            if language == "te" and classification:
                classification_display = translate_to_telugu(classification)

            final_response_obj = ComplaintResponse(
                formal_summary=formal_summary,
                classification=classification_display,
                original_classification=classification,
                raw_conversation=build_conversation(final_req), # Use the unified transcript
                timestamp=get_timestamp(),
                localized_fields=localized_fields,
            )
            
            return ChatStepResponse(status="done", final_response=final_response_obj)
            
        else:
            # It's a question
            return ChatStepResponse(status="question", message=reply)

    except Exception as e:
        logger.error(f"Chat step failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
