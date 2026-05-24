import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import json
import re
from dotenv import load_dotenv
from google.oauth2 import service_account
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import SystemMessage, HumanMessage

load_dotenv()

app = FastAPI(title="ContextShift AI Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Gemini via LangChain
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
SERVICE_ACCOUNT_FILE = os.getenv("SERVICE_ACCOUNT_FILE", "service-account-key.json")
MODEL_PRIORITIES = [
    "gemini-2.0-flash",
    "gemini-2.0-flash-001",
    "gemini-2.0-flash-lite",
]

# Try to load service account credentials first
CREDENTIALS = None
if os.path.exists(SERVICE_ACCOUNT_FILE):
    try:
        CREDENTIALS = service_account.Credentials.from_service_account_file(
            SERVICE_ACCOUNT_FILE,
            scopes=['https://www.googleapis.com/auth/cloud-platform']
        )
        print(f"[Init] Using service account credentials from {SERVICE_ACCOUNT_FILE}")
    except Exception as e:
        print(f"[Init] Failed to load service account: {e}")
        CREDENTIALS = None


def _build_llm(model: str) -> ChatGoogleGenerativeAI:
    if CREDENTIALS:
        return ChatGoogleGenerativeAI(
            model=model,
            credentials=CREDENTIALS,
            temperature=0.1,
            max_retries=0,
        )
    else:
        return ChatGoogleGenerativeAI(
            model=model,
            google_api_key=GOOGLE_API_KEY,
            temperature=0.1,
            max_retries=0,
        )


async def _invoke_with_fallback(messages):
    last_error = None
    for model in MODEL_PRIORITIES:
        try:
            response = await asyncio.wait_for(
                _build_llm(model).ainvoke(messages),
                timeout=8,
            )
            return response
        except Exception as e:
            error_text = str(e)
            print(f"[Gemini Fallback] model={model} failed: {error_text}")
            if "RESOURCE_EXHAUSTED" in error_text or "429" in error_text:
                last_error = e
                continue
            raise

    if last_error is not None:
        raise last_error
    raise Exception("Unable to invoke Gemini with any fallback model.")


# ─── Request Models ─────────────────────────────────────────────────────────────

class CommandRequest(BaseModel):
    command: str
    user_name: str
    context: dict = {}


class InsightRequest(BaseModel):
    user_name: str
    stats: dict = {}


class SummarizeRequest(BaseModel):
    content: str


# ─── System Prompts ─────────────────────────────────────────────────────────────

COMMAND_PROMPT = """You are JARVIS, the AI brain of ContextShift — a personal productivity life OS.
Your goal is to parse intent and return a JSON payload that adapts the UI.

═══════════════════════════════════════
ACTIONS (Select ONE or MORE):
- add_task: {{"title": "str", "priority": "low|normal|high|urgent"}}
- add_habit: {{"name": "str", "icon": "emoji"}}
- add_note: {{"content": "str"}}
- start_focus: {{"duration_minutes": int}}
- show_dynamic_card: {{"card": {{"title": "str", "type": "workout|planner|advice", "description": "str", "list_items": [{{"text": "str", "task_payload": {{"title": "str", "priority": "normal"}}}}], "action_label": "str", "action_module": "FocusTimerModule|TasksModule|None"}}}}

═══════════════════════════════════════
LAYOUT ENGINE: Reorder these 4 modules based on intent:
["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"]

If you call `show_dynamic_card`, you MUST put "GenerativeCardModule" at the START of the `layout_order` array.

═══════════════════════════════════════
RULES:
1. "timer/focus/pomodoro" intent → FocusTimerModule first.
2. "plan/routine/workout/advice" intent → use `show_dynamic_card` + GenerativeCardModule first.
3. For workouts/routines, include at least 3-4 specific actionable steps in `list_items`, each with a `task_payload`.
4. Keep `response` short and punchy.
5. Use the provided user context to personalize the response. Consider profile, mood, top tasks, missing habits, recent notes, recent commands, and recent behavior events.
6. Output ONLY valid JSON."""


INSIGHT_PROMPT = """You are the AI analytics engine of ContextShift, a personal productivity OS.
Generate a SHORT, precise, and genuinely useful insight based on the user's real behavioral data.

═══════════════════════════════════════
INSIGHT INTELLIGENCE RULES
═══════════════════════════════════════
1. Under 2 sentences total — tight and punchy
2. Reference actual numbers from their stats
3. Detect a real pattern: streak risk, peak productivity window, habit drop-off, focus drop, task pile-up
4. Give exactly ONE actionable suggestion
5. Return ONLY valid JSON: {{"insight": "your insight text", "insight_type": "streak|warning|tip|pattern|milestone"}}
6. User name: {user_name}
7. Stats payload: {stats}
"""

# ─── Endpoints ───────────────────────────────────────────────────────────────

@app.post("/command")
async def process_command(data: CommandRequest):
    user_input = data.command
    first_name = data.user_name.split(' ')[0] if data.user_name else "Uzair"
    
    try:
        messages = [
            SystemMessage(content=COMMAND_PROMPT),
            HumanMessage(
                content=json.dumps(
                    {
                        "command": user_input,
                        "user_name": first_name,
                        "context": data.context or {},
                    },
                    ensure_ascii=False,
                )
            ),
        ]
        response = await _invoke_with_fallback(messages)
        raw = response.content.strip()

        # Bulletproof JSON discovery: Find the first { and the last }
        start_index = raw.find('{')
        end_index = raw.rfind('}')
        
        if start_index != -1 and end_index != -1 and end_index > start_index:
            json_str = raw[start_index:end_index + 1]
            try:
                result = json.loads(json_str)
            except json.JSONDecodeError:
                # Cleanup common LLM artifacts if simple parse fails
                clean = json_str.replace("```json", "").replace("```", "").strip()
                result = json.loads(clean)
        else:
            result = json.loads(raw.strip())

        print(f"[AI Command] '{data.command}' → {len(result.get('actions', []))} actions")
        return result

    except asyncio.TimeoutError:
        print("[AI Command Error] Timed out waiting for Gemini")
        return {
            "actions": [],
            "response": f"JARVIS timed out, {first_name}. I can still help locally.",
            "greeting_update": None,
            "layout_order": ["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"]
        }
    except Exception as e:
        error_msg = str(e)
        print(f"[AI Command Error] {error_msg}")
        
        response_text = f"I had trouble processing that, {first_name}."
        if "RESOURCE_EXHAUSTED" in error_msg or "429" in error_msg:
            response_text = f"It looks like JARVIS has reached his thinking quota for now, {first_name}. Please try again in a few minutes or check your Gemini API limits."
            
        return {
            "actions": [],
            "response": response_text,
            "greeting_update": None,
            "layout_order": ["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"]
        }


@app.post("/ai-command")
async def process_ai_command_alias(data: CommandRequest):
    return await process_command(data)


@app.post("/ai-insight")
async def generate_insight(data: InsightRequest):
    first_name = data.user_name.split(' ')[0] if data.user_name else "Friend"
    try:
        prompt = INSIGHT_PROMPT.format(
            user_name=first_name,
            stats=json.dumps(data.stats) if data.stats else "No stats available yet",
        )

        messages = [
            SystemMessage(content=prompt),
            HumanMessage(content=f"Generate an insight for {first_name}."),
        ]
        response = await _invoke_with_fallback(messages)
        raw = response.content.strip()

        # Bulletproof JSON discovery
        start_index = raw.find('{')
        end_index = raw.rfind('}')
        
        if start_index != -1 and end_index != -1:
            json_str = raw[start_index:end_index + 1]
            result = json.loads(json_str)
        else:
            result = json.loads(raw.strip())

        return {"insight": result.get("insight", f"Keep going, {first_name}!")}

    except asyncio.TimeoutError:
        print("[AI Insight Error] Timed out waiting for Gemini")
        return {"insight": f"Stay consistent, {first_name}. Small wins compound into big results."}
    except Exception as e:
        error_msg = str(e)
        print(f"[AI Insight Error] {error_msg}")
        insight_text = f"Stay consistent, {first_name}. Small wins compound into big results."
        if "RESOURCE_EXHAUSTED" in error_msg or "429" in error_msg:
            insight_text = "JARVIS is taking a breather (Quota reached). Keep up the great work locally!"
        return {"insight": insight_text}


@app.post("/summarize")
async def summarize_note(data: SummarizeRequest):
    prompt = "Summarize this thought in exactly ONE short, punchy sentence. Focus on the core intent. Avoid 'The user wants...' style."
    try:
        messages = [
            SystemMessage(content=prompt),
            HumanMessage(content=data.content),
        ]
        response = await _invoke_with_fallback(messages)
        return {"summary": response.content.strip()}
    except asyncio.TimeoutError:
        print("[Summarize Error] Timed out waiting for Gemini")
        return {"summary": "Unable to summarize at this time."}
    except Exception as e:
        print(f"[Summarize Error] {e}")
        return {"summary": "Unable to summarize at this time."}


@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "ContextShift AI Engine"}
