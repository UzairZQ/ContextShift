from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
import os
import json
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import SystemMessage, HumanMessage

load_dotenv()

app = FastAPI(title="ContextShift Behavior Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

NODE_SERVER_URL = "http://localhost:3000/api/layout-update"

# Initialize Gemini via LangChain
llm = ChatGoogleGenerativeAI(
    model="gemini-1.5-pro",
    google_api_key=os.getenv("GOOGLE_API_KEY"),
    temperature=0.7,  # Increased temperature for more creative greetings
)

# ─── System Prompt ──────────────────────────────────────────────────────────────
SYSTEM_PROMPT = """You are the AI brain of ContextShift, a high-end personal life OS.
Your goals:
1. Analyze user behavior and commands to decide the optimal module order.
2. Generate a highly personalized, creative greeting that feels alive and context-aware.

AVAILABLE MODULES:
- GreetingModule (Always first, contains your dynamic 'greeting' text)
- FocusTimerModule (Deep work, Pomodoro)
- TasksModule (Daily to-do lists)
- HabitModule (Routine and tracking)
- NotesModule (Quick capture of thoughts)

GREETING GUIDELINES:
- Use the user's name: {user_name}
- Be context-aware: Mention the time of day, current focus, or recent achievements.
- Be creative: Avoid generic "Hello". Use personas like a mentor, a co-pilot, or a serene sanctuary guide.
- Keep it under 12 words.

LAYOUT RULES:
- PRIORITIZE the 'explicit_command' if provided.
- "Study/Deep Work": Leads with FocusTimerModule + TasksModule.
- "Capture/Ideate": Leads with NotesModule.
- "Review/Routine": Leads with HabitModule + TasksModule.
- If no command, use time-of-day:
    - 05:00 - 11:00: Prioritize FocusTimerModule (Fresh start)
    - 11:00 - 17:00: Prioritize TasksModule (Execution)
    - 17:00 - 05:00: Prioritize HabitModule (Reflection)

Return ONLY valid JSON:
{{
  "greeting": "Your creative, personalized greeting here",
  "order": ["ModuleName1", "ModuleName2", "ModuleName3", "ModuleName4"]
}}
"""


class BehaviorData(BaseModel):
    user_id: str
    user_name: str
    events: list
    command: str | None = None


def build_a2ui_payload(greeting: str, order: list[str]) -> dict:
    """Converts AI layout decision into valid GenUI v0.9 A2UI payloads."""
    component_ids = ["comp_greeting"] + [f"comp_{i}" for i in range(len(order))]
    children_ids = component_ids

    components = [
        {
            "id": "root",
            "component": "RootLayout",
            "children": children_ids,
        },
        {
            "id": "comp_greeting",
            "component": "GreetingModule",
            "greetingText": greeting,
        },
    ]

    for i, module_name in enumerate(order):
        components.append({"id": f"comp_{i}", "component": module_name})

    create_surface = json.dumps({
        "version": "v0.9",
        "createSurface": {
            "surfaceId": "home_surf",
            "catalogId": "context_shift_catalog"
        }
    })

    update_components = json.dumps({
        "version": "v0.9",
        "updateComponents": {
            "surfaceId": "home_surf",
            "components": components
        }
    })

    return {"a2ui_payloads": [create_surface, update_components]}


@app.post("/analyze-behavior")
async def analyze_behavior(data: BehaviorData):
    from datetime import datetime
    now = datetime.now()
    time_context = f"Current time: {now.strftime('%H:%M')} on {now.strftime('%A, %B %d')}."
    
    event_summary = "First launch" if not data.events else f"Recent activity: {len(data.events)} interactions recorded."
    
    prompt = SYSTEM_PROMPT.format(user_name=data.user_name)
    user_input = f"{time_context}\n{event_summary}\n"
    if data.command:
        user_input += f"USER COMMAND: '{data.command}'\n"
    user_input += "Reconstruct the sanctuary."

    try:
        messages = [
            SystemMessage(content=prompt),
            HumanMessage(content=user_input),
        ]
        response = await llm.ainvoke(messages)
        raw = response.content.strip()
        
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"): raw = raw[4:]
        
        layout = json.loads(raw.strip())
        greeting = layout.get("greeting", f"Welcome back, {data.user_name}")
        order = layout.get("order", ["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"])
    
    except Exception as e:
        print(f"[AI Error] {e}")
        # Dynamic fallback
        hour = now.hour
        greeting = f"Ready for the morning, {data.user_name}?" if hour < 12 else f"Good evening, {data.user_name}."
        order = ["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"]

    payload = build_a2ui_payload(greeting, order)

    try:
        async with httpx.AsyncClient() as client:
            await client.post(NODE_SERVER_URL, json=payload, timeout=5.0)
    except Exception as e:
        print(f"[Node Error] {e}")

    return {"status": "success", "greeting": greeting, "order": order}
