from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import json
from dotenv import load_dotenv
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
llm = ChatGoogleGenerativeAI(
    model="gemini-2.0-flash",
    google_api_key=os.getenv("GOOGLE_API_KEY"),
    temperature=0.7,
)


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
Analyze the user's command and return structured actions PLUS an optimal layout order for the home screen.

AVAILABLE ACTIONS:
- add_task: {{"title": "task description", "priority": "normal|medium|high"}}
- add_habit: {{"name": "habit name", "icon": "single emoji"}}
- add_note: {{"content": "note text"}}
- start_focus: {{"duration_minutes": 25}}
- navigate: {{"tab": "tasks|habits|focus|notes"}}
- motivate: {{}}

LAYOUT ORDER:
Based on intent, reorder these 4 modules: ["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"]
- "Study/Deep Work": FocusTimerModule first.
- "Capture/Ideate": NotesModule first.
- "Review/Organize": TasksModule first.

RULES:
1. Return ONLY valid JSON: {{"actions": [...], "response": "...", "greeting_update": "optional", "layout_order": [...]}}
2. "response": 1-2 sentences, energetic, use the user's first name.
3. If conversational, return 0 actions.
4. "layout_order" MUST contain all 4 modules.

EXAMPLES:
User: "I need to study for physics"
{{"actions": [{{"type": "add_task", "params": {{"title": "Study physics", "priority": "high"}}}}, {{"type": "start_focus", "params": {{"duration_minutes": 45}}}}], "response": "Study mode activated. 45-min focus session ready.", "greeting_update": "Deep study mode, {{name}}.", "layout_order": ["FocusTimerModule", "TasksModule", "NotesModule", "HabitModule"]}}

User: "good morning"
{{"actions": [], "response": "Good morning, {{name}}. Ready to own the day?", "layout_order": ["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"]}}
"""

INSIGHT_PROMPT = """You are the AI analytics engine of ContextShift, a personal productivity OS.
Generate a SHORT, personalized productivity insight based on the user's stats.

RULES:
1. Keep it under 2 sentences.
2. Be specific — reference their actual numbers.
3. Give one actionable suggestion.
4. Be encouraging but not generic. Avoid clichés.
5. Return ONLY valid JSON: {{"insight": "your insight text"}}

USER: {user_name}
STATS: {stats}
"""


# ─── Endpoints ──────────────────────────────────────────────────────────────────

@app.post("/ai-command")
async def process_command(data: CommandRequest):
    first_name = data.user_name.split(' ')[0] if data.user_name else "Friend"
    prompt = COMMAND_PROMPT.replace("{name}", first_name)

    user_input = f"User: {first_name}\nCommand: \"{data.command}\""
    if data.context:
        user_input += f"\nContext: {json.dumps(data.context)}"

    try:
        messages = [
            SystemMessage(content=prompt),
            HumanMessage(content=user_input),
        ]
        response = await llm.ainvoke(messages)
        raw = response.content.strip()

        # Strip markdown code fences if present
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]

        result = json.loads(raw.strip())
        print(f"[AI Command] '{data.command}' → {len(result.get('actions', []))} actions")
        return result

    except Exception as e:
        print(f"[AI Command Error] {e}")
        return {
            "actions": [],
            "response": f"I had trouble processing that, {first_name}. Try something like 'add task buy groceries' or 'focus 25 min'.",
            "greeting_update": None,
            "layout_order": ["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"]
        }


@app.post("/ai-insight")
async def generate_insight(data: InsightRequest):
    first_name = data.user_name.split(' ')[0] if data.user_name else "Friend"
    prompt = INSIGHT_PROMPT.format(
        user_name=first_name,
        stats=json.dumps(data.stats) if data.stats else "No stats available yet",
    )

    try:
        messages = [
            SystemMessage(content=prompt),
            HumanMessage(content=f"Generate an insight for {first_name}."),
        ]
        response = await llm.ainvoke(messages)
        raw = response.content.strip()

        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]

        result = json.loads(raw.strip())
        return {"insight": result.get("insight", f"Keep going, {first_name}!")}

    except Exception as e:
        print(f"[AI Insight Error] {e}")
        return {"insight": f"Stay consistent, {first_name}. Small wins compound into big results."}


@app.post("/summarize")
async def summarize_note(data: SummarizeRequest):
    prompt = "Summarize this thought in exactly ONE short, punchy sentence. Focus on the core intent. Avoid 'The user wants...' style."
    try:
        messages = [
            SystemMessage(content=prompt),
            HumanMessage(content=data.content),
        ]
        response = await llm.ainvoke(messages)
        return {"summary": response.content.strip()}
    except Exception as e:
        print(f"[Summarize Error] {e}")
        return {"summary": "Unable to summarize at this time."}


@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "ContextShift AI Engine"}
