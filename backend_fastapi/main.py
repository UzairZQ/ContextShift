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
You receive a user command plus real context: their name, current time, usage patterns, and pending items.
Your job is to understand intent deeply, take smart actions, and dynamically restructure the home layout.

═══════════════════════════════════════
CONTEXT YOU RECEIVE
═══════════════════════════════════════
You will be given:
- user_name: first name of the user
- current_time: 24h format (e.g. "09:15")
- day_of_week: e.g. "Monday"
- background_data: An array of their actual high-priority tasks, missed habits, and recent notes. Use this to give hyper-relevant advice!

═══════════════════════════════════════
AVAILABLE ACTIONS
═══════════════════════════════════════
- add_task:          {"title": "string", "priority": "low|normal|high|urgent"}
- add_habit:         {"name": "string", "icon": "emoji"}
- add_note:          {"content": "string"}
- start_focus:       {"duration_minutes": 25}
- show_dynamic_card: {"card": {"title": "string", "description": "string", "list_items": ["string"], "action_label": "string", "action_module": "FocusTimerModule|TasksModule|None"}}

═══════════════════════════════════════
CRITICAL SEMANTIC INTELLIGENCE RULES (THINK DEEPLY)
═══════════════════════════════════════
1. NEVER BLINDLY ADD TASKS. If a user says "timer", "show me timer", or "pomodoro", the semantic intent is to focus! Return `layout_order` with FocusTimerModule first.
2. If the user asks for a PLAN, ADVICE, OVERWHELM RELIEF, or asks a generic question, DO NOT ADD A TASK. Use the `show_dynamic_card` action to build an ephemeral widget presenting your answer or plan beautifully.
3. If the user says "add a task", build the task.
4. If their intent is ambiguous but mentions time, studying, or working, bias towards `start_focus` or `show_dynamic_card` instead of adding random tasks.

═══════════════════════════════════════
INTELLIGENT LAYOUT ENGINE
═══════════════════════════════════════
Reorder all 4 modules based on detected intent AND time context:
["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"]

If you generate a `show_dynamic_card`, you MUST output the string "GenerativeCardModule" as the very FIRST item in the `layout_order` array, shifting the others down (making the array 5 items long).

Layout decision logic — apply in order:

1. EXPLICIT INTENT wins first:
   - "study / deep work / focus / concentrate / timer / clock / start" → FocusTimerModule first
   - "tasks / todo / what do I need to do / plan my day" → TasksModule first
   - "habits / streak / routine / check in" → HabitModule first
   - "note / idea / capture / write down / remember" → NotesModule first

2. IF no explicit intent, use TIME-OF-DAY:
   - 05:00–09:00 Morning  → HabitModule, TasksModule, FocusTimerModule, NotesModule
   - 09:00–12:00 Deep work → FocusTimerModule, TasksModule, NotesModule, HabitModule
   - 12:00–14:00 Midday   → TasksModule, NotesModule, HabitModule, FocusTimerModule
   - 14:00–18:00 Afternoon → FocusTimerModule, TasksModule, NotesModule, HabitModule
   - 18:00–21:00 Evening   → HabitModule, TasksModule, NotesModule, FocusTimerModule

═══════════════════════════════════════
RESPONSE STYLE
═══════════════════════════════════════
- 1–2 sentences max. Use their first name organically.
- If using `show_dynamic_card`, keep the response extremely short like "Generating a plan for you."

═══════════════════════════════════════
OUTPUT FORMAT — STRICT JSON ONLY
═══════════════════════════════════════
Return ONLY this JSON, no extra text, no markdown:
{
  "actions": [...],
  "response": "string",
  "greeting_update": "optional short home screen greeting string or omit key",
  "layout_order": ["Module1", "Module2", "Module3", "Module4"],
  "layout_reason": "explain why"
}

═══════════════════════════════════════
EXAMPLES
═══════════════════════════════════════

User: "I'm overwhelmed, what should I do?"
Output:
{
  "actions": [
    {
      "type": "show_dynamic_card",
      "params": {
        "card": {
          "title": "Overwhelm Protocol",
          "description": "Take a breath. Let's tackle just the top priority from your background data.",
          "list_items": ["Hide your phone", "Start a 15 min focus block", "Knock out one task"],
          "action_label": "Start 15min Block",
          "action_module": "FocusTimerModule"
        }
      }
    }
  ],
  "response": "Breath. I've built a quick protocol to get you back on track.",
  "layout_order": ["GenerativeCardModule", "FocusTimerModule", "TasksModule", "NotesModule", "HabitModule"],
  "layout_reason": "User overwhelmed, triggered dynamic card."
}

User: "timer"
Output:
{
  "actions": [],
  "response": "Bringing up the timer.",
  "layout_order": ["FocusTimerModule", "TasksModule", "HabitModule", "NotesModule"],
  "layout_reason": "Semantic intent for timer, bumping module up without adding a task."
}
"""


INSIGHT_PROMPT = """You are the AI analytics engine of ContextShift, a personal productivity OS.
Generate a SHORT, precise, and genuinely useful insight based on the user's real behavioral data.

═══════════════════════════════════════
INSIGHT INTELLIGENCE RULES
═══════════════════════════════════════
1. Under 2 sentences total — tight and punchy
2. Reference actual numbers from their stats — never speak in generalities
3. Detect a real pattern: streak risk, peak productivity window, habit drop-off, focus drop, task pile-up
4. Give exactly ONE actionable suggestion — specific, not generic
5. Match tone to their current state:
   - High performance (streaks up, tasks done) → affirm + push further
   - Declining (habits missed, tasks piling) → honest but not harsh + one fix
   - Neutral → find the most interesting pattern and surface it
6. NEVER say: "Great job!", "Keep it up!", "You're doing amazing!", "Remember to..."
7. NEVER invent numbers not present in stats
8. Return ONLY valid JSON: {"insight": "your insight text", "insight_type": "streak|warning|tip|pattern|milestone"}

═══════════════════════════════════════
INSIGHT TYPE GUIDE
═══════════════════════════════════════
- streak:    User is on a good run — acknowledge it with specific numbers
- warning:   Something is slipping — name it clearly without being harsh
- tip:       A behavioral pattern suggests an optimization
- pattern:   Interesting usage pattern worth surfacing
- milestone: A threshold has been crossed (first 7-day streak, 100 tasks done etc.)

═══════════════════════════════════════
INPUT
═══════════════════════════════════════
USER: {user_name}
STATS: {stats}

Stats may include: tasks_completed_today, tasks_pending, habits_completed_today,
total_habits, current_streak_days, focus_sessions_today, focus_minutes_today,
most_productive_hour, weekly_completion_rate, longest_streak, notes_created_today

═══════════════════════════════════════
EXAMPLES
═══════════════════════════════════════

Stats: streak=12, habits_done=5, total_habits=5, focus_minutes=90
Output:
{"insight": "12-day streak and a perfect habit day — you hit all 5 today. At this pace, day 21 is 9 days away, which is when consistency becomes automatic.", "insight_type": "streak"}

Stats: streak=8, habits_done=1, total_habits=5, focus_minutes=0, tasks_pending=9
Output:
{"insight": "8-day streak is at risk — only 1 of 5 habits done and no focus sessions yet today. Pick the one habit that takes under 3 minutes and do it now.", "insight_type": "warning"}

Stats: most_productive_hour=09, focus_sessions_today=3, tasks_completed=4, current_time=16:00
Output:
{"insight": "Your best work happens before 10AM — 3 sessions and 4 tasks already done by midday. Anything left on your list now needs either a deadline or a calendar block tomorrow morning.", "insight_type": "pattern"}
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
