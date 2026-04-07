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
    temperature=0.3,
)

# ─── System Prompt ──────────────────────────────────────────────────────────────
SYSTEM_PROMPT = """You are the AI brain of ContextShift, a personal life OS app.
Your job is to analyze the user's recent behavior events or EXPLICIT COMMANDS and decide the optimal
home screen layout for them RIGHT NOW.

The app has 5 modules available (registered in the custom GenUI catalog):
- GreetingModule  → always shown first
- FocusTimerModule → Pomodoro-style focus timer
- TasksModule → daily task list
- HabitModule → habit tracker
- NotesModule → quick thoughts and capture

COMMAND PRIORITY:
If the user provides an 'explicit_command', you MUST prioritize it.
- "Study mode": Prioritize FocusTimerModule and TasksModule. Hide distractions.
- "Capture mode": Prioritize NotesModule.
- "Planning mode": Prioritize TasksModule and HabitModule.

If no command, use behavior analysis:
- If the user opened Focus a lot recently → put FocusTimerModule first
- If they completed many tasks → put TasksModule first  
- If it's morning (before 12:00) → prioritize FocusTimerModule
- If it's evening (after 18:00) → prioritize HabitModule

Return ONLY valid JSON in this exact format (no markdown, no extra text):

{
  "greeting": "A short personalized greeting (max 10 words)",
  "order": ["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"]
}

Rules:
- GreetingModule is ALWAYS first and NOT included in "order"
- "order" MUST contain at least 3 of the other modules, but can contain all 4.
"""


class BehaviorData(BaseModel):
    user_id: str
    events: list
    command: str | None = None


def build_a2ui_payload(greeting: str, order: list[str]) -> dict:
    """Converts AI layout decision into valid GenUI v0.9 A2UI payloads."""
    component_ids = ["comp_greeting"] + [f"comp_{i}" for i in range(len(order))]
    children_ids = component_ids  # root's children

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
        comp: dict = {"id": f"comp_{i}", "component": module_name}
        components.append(comp)

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


@app.get("/")
def read_root():
    return {"message": "ContextShift Behavior Engine v2 — Gemini AI Active"}


@app.post("/analyze-behavior")
async def analyze_behavior(data: BehaviorData):
    """
    Main AI endpoint. Reads user behavior events, sends to Gemini,
    parses layout decision, broadcasts update through Node.js Socket.io.
    """
    # Summarize events for the AI prompt
    event_summary = "No events logged yet (first launch)."
    if data.events:
        event_counts: dict = {}
        for event in data.events:
            module = event.get("module", "unknown")
            event_counts[module] = event_counts.get(module, 0) + 1
        event_summary = "Recent activity: " + ", ".join(
            f"{mod} ({count} interactions)" for mod, count in event_counts.items()
        )

    # Get current time context
    from datetime import datetime
    now = datetime.now()
    time_context = f"Current time: {now.strftime('%H:%M')} on {now.strftime('%A, %B %d')}."

    print(f"[AI] Analyzing behavior. {time_context} {event_summary}")

    # Call Gemini
    try:
        user_input = f"{time_context}\n\n{event_summary}\n\n"
        if data.command:
            user_input += f"EXPLICIT USER COMMAND: '{data.command}'\n\n"
        user_input += "Decide the optimal layout now."

        messages = [
            SystemMessage(content=SYSTEM_PROMPT),
            HumanMessage(content=user_input),
        ]
        response = await llm.ainvoke(messages)
        raw = response.content.strip()

        # Parse JSON response
        # Remove markdown code blocks if present
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        
        layout = json.loads(raw.strip())
        greeting = layout.get("greeting", f"Good day, Uzair")
        order = layout.get("order", ["FocusTimerModule", "TasksModule", "HabitModule"])
        
        print(f"[AI] Gemini layout decision: greeting='{greeting}', order={order}")

    except Exception as e:
        print(f"[AI] Gemini error, using smart fallback: {e}")
        # Smart time-based fallback
        hour = now.hour
        if hour < 12:
            greeting = f"Good morning, Uzair ✨\nTime to focus"
            order = ["FocusTimerModule", "TasksModule", "HabitModule"]
        elif hour < 18:
            greeting = f"Good afternoon, Uzair ☀️\nYou're doing great"
            order = ["TasksModule", "FocusTimerModule", "HabitModule"]
        else:
            greeting = f"Good evening, Uzair 🌙\nReview your day"
            order = ["HabitModule", "TasksModule", "FocusTimerModule"]

    # Build the GenUI A2UI payload
    payload = build_a2ui_payload(greeting, order)

    # Broadcast through Node.js to Flutter
    try:
        async with httpx.AsyncClient() as client:
            r = await client.post(NODE_SERVER_URL, json=payload, timeout=5.0)
            r.raise_for_status()
            print(f"[Node] Layout broadcasted successfully.")
    except Exception as e:
        print(f"[Node] Error broadcasting: {e}")

    return {"status": "success", "greeting": greeting, "order": order}
