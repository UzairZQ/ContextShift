# 🚀 FastAPI Complete Learning Guide: Building Real Software, Not Just Vibes

Welcome! This guide teaches you FastAPI through your actual **ContextShift AI Engine** project. You'll learn not just HOW to write code, but **WHY** each piece matters.

---

## Table of Contents
1. [What is FastAPI?](#what-is-fastapi)
2. [Project Structure Overview](#project-structure-overview)
3. [Core Concepts](#core-concepts)
4. [Your Project Explained](#your-project-explained)
5. [Advanced Patterns](#advanced-patterns)
6. [Debugging & Best Practices](#debugging--best-practices)

---

## What is FastAPI?

FastAPI is a **modern web framework** for building APIs in Python. Think of it as the fastest, most developer-friendly way to create a backend service that:

- **Receives requests** from your Flutter app
- **Processes data** (validates, transforms, calls AI models, etc.)
- **Sends responses** back to your frontend

### Why FastAPI?

| Feature | Why It Matters |
|---------|----------------|
| **Fast** | Written with speed in mind; matches Node.js performance |
| **Type hints** | Python catches errors before they happen |
| **Auto docs** | `/docs` gives you free interactive API documentation |
| **Async support** | Handle thousands of requests simultaneously without blocking |
| **Pydantic validation** | Automatically validates incoming data; malformed requests rejected |

---

## Project Structure Overview

Your backend lives in `/backend_fastapi/`:

```
backend_fastapi/
├── main.py              # 👈 Your FastAPI app (we're studying this)
├── requirements.txt     # All dependencies listed
├── list_models.py       # Helper to list available Gemini models
└── service-account-key.json  # Google credentials
```

The **main.py** file is the core—it defines:
1. Your FastAPI app
2. API endpoints (routes)
3. Request/response models
4. Business logic (processing commands, generating insights)

---

## Core Concepts

### 1️⃣ The FastAPI App Object

```python
from fastapi import FastAPI

app = FastAPI(title="ContextShift AI Engine")
```

**What's happening?**
- `FastAPI()` creates your web application
- `title="ContextShift AI Engine"` labels your API (appears in `/docs`)

Think of `app` as the **master controller** that:
- Listens for incoming HTTP requests
- Decides which function should handle each request
- Sends responses back to the client

---

### 2️⃣ Middleware (The Gatekeeper)

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # Allow requests from ANY domain
    allow_methods=["*"],        # Allow any HTTP method
    allow_headers=["*"],        # Allow any headers
)
```

**What's CORS?**
- **CORS** = Cross-Origin Resource Sharing
- It's a security policy: "What domains are allowed to talk to my backend?"

**Why you need it:**
- Your Flutter app runs on your phone
- Your backend runs on a server
- They're different "origins" → blocked by default
- CORS allows them to communicate

**Analogy:** Like a bouncer checking IDs at a club. We're allowing everyone (`["*"]`).

⚠️ **Production Warning:** Never use `["*"]` in production! Be specific:
```python
allow_origins=["https://myapp.com", "https://app.vercel.app"]
```

---

### 3️⃣ Pydantic Models (Data Validation)

Pydantic models are **blueprints** for request data. They guarantee that incoming data matches expectations.

```python
from pydantic import BaseModel

class CommandRequest(BaseModel):
    command: str
    user_name: str
    context: dict = {}
```

**What does this do?**

When your Flutter app sends a request like:
```json
{
  "command": "add task meeting at 3pm",
  "user_name": "Uzair Khan",
  "context": {"mood": "focused"}
}
```

FastAPI automatically:
1. **Parses** the JSON
2. **Validates** it matches the model
3. **Converts** it to a Python object
4. **Rejects** it if anything is wrong

**Example: What happens if data is invalid?**

```json
{
  "user_name": "Uzair Khan"
  // Missing 'command'—required field!
}
```

FastAPI responds with a 422 error (auto-generated) without you writing any validation code!

**The `context: dict = {}` line:**
- `dict` = it's a dictionary
- `= {}` = if not provided, default to empty dictionary
- So `context` is **optional**

---

### 4️⃣ Endpoints (Routes)

An **endpoint** is a URL path your app responds to. Defined with decorators:

```python
@app.post("/command")
async def process_command(data: CommandRequest):
    # ... your code here
    return result
```

**Breaking this down:**

| Part | Meaning |
|------|---------|
| `@app.post()` | This function handles POST requests (sending data to the server) |
| `"/command"` | The URL path: `http://yourserver.com/command` |
| `async def` | Function runs **asynchronously** (non-blocking) |
| `data: CommandRequest` | Parameter receives validated request data |
| `return result` | Automatically converts to JSON response |

**HTTP Methods:**
- `@app.get()` — retrieve data (no side effects)
- `@app.post()` — create/submit data
- `@app.put()` — update existing data
- `@app.delete()` — remove data
- `@app.patch()` — partial update

Your project uses:
```python
@app.post("/command")        # Submit a voice command
@app.post("/ai-insight")     # Request an AI insight
@app.post("/summarize")      # Summarize a note
@app.get("/health")          # Check if server is running
```

---

### 5️⃣ Async/Await (The Game Changer)

```python
async def process_command(data: CommandRequest):
    response = await _invoke_with_fallback(messages)
    return response
```

**Why `async`?**

Without async, if you call the Gemini AI:
```python
# Without async (BLOCKS for 5 seconds)
def process_command(data):
    response = gemini.invoke(messages)  # Waits here... your server is stuck
    return response
```

If 10 users hit `/command` simultaneously, each waits 5 seconds. After 50 seconds, users are frustrated!

**With async:**
```python
async def process_command(data):
    response = await gemini.ainvoke(messages)  # "I'll wait for this, but let other requests run"
    return response
```

10 users hit it → all wait ~5 seconds (not 50!). FastAPI switches between them while waiting.

**Analogy:** 
- **Sync:** One cashier. Each customer waits for checkout to finish.
- **Async:** One cashier, but she takes your card, then serves the next customer while processing your payment. She comes back when ready.

**Key Rule:**
- If calling an **async function** (AI, database, external API), use `await`
- Always mark your endpoint `async def`

---

### 6️⃣ Try/Except Error Handling

```python
try:
    messages = [SystemMessage(...), HumanMessage(...)]
    response = await _invoke_with_fallback(messages)
    return result
except asyncio.TimeoutError:
    print("[AI Command Error] Timed out waiting for Gemini")
    return {"actions": [], "response": "JARVIS timed out..."}
except Exception as e:
    error_msg = str(e)
    print(f"[AI Command Error] {error_msg}")
    return {"actions": [], "response": "I had trouble processing that..."}
```

**What's happening?**

1. **try block:** Your main logic
2. **except asyncio.TimeoutError:** If Gemini takes >8 seconds, gracefully fail
3. **except Exception:** Catch any other error
4. **Always return something:** Never let an error crash the server

**Why this matters:**
- Users expect your app to handle problems gracefully
- Logging errors helps you debug later
- Returning a fallback response > crashing

---

## Your Project Explained

### The Big Picture: Flow of `/command` Endpoint

```
User speaks in Flutter app
        ↓
Flutter sends JSON to: POST /command
        ↓
FastAPI receives & validates with CommandRequest
        ↓
process_command() function runs
        ↓
1. Extract user's first name from full name
        ↓
2. Build system + user messages for AI
        ↓
3. Call Gemini API via _invoke_with_fallback()
        ↓
4. Parse AI response (extract JSON)
        ↓
5. Return actions + layout order to Flutter
        ↓
Flutter app updates UI with dynamic cards, new tasks, etc.
```

### Request Models Explained

**Your three request models:**

```python
class CommandRequest(BaseModel):
    command: str           # What user said: "add task meeting"
    user_name: str        # Who is using: "Uzair Khan"
    context: dict = {}    # Optional context: mood, recent events, etc.

class InsightRequest(BaseModel):
    user_name: str        # Who gets insight
    stats: dict = {}      # User's behavioral data: focus_minutes, tasks_completed, etc.

class SummarizeRequest(BaseModel):
    content: str          # The text to summarize
```

Each one is **specifically validated** for its endpoint.

---

### The AI Integration Pattern

Your project uses **LangChain + Google Gemini**. Here's why:

**Without LangChain:**
```python
import google.generativeai as genai

response = genai.GenerativeModel("gemini-2.0-flash").generate_content(text)
```

**With LangChain:**
```python
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import SystemMessage, HumanMessage

llm = ChatGoogleGenerativeAI(model="gemini-2.0-flash")
messages = [
    SystemMessage(content="You are JARVIS..."),
    HumanMessage(content="add task meeting at 3pm")
]
response = llm.invoke(messages)
```

**Benefits of LangChain:**
- **Unified interface** across different AI models (Gemini, Claude, OpenAI, etc.)
- **Message structure** is clearer and more maintainable
- **Tools/chains** for complex workflows
- **Easy to switch models** without rewriting code

---

### System Prompts: Your AI's Brain

```python
COMMAND_PROMPT = """You are JARVIS, the AI brain of ContextShift...
Your goal is to parse intent and return a JSON payload that adapts the UI.

ACTIONS (Select ONE or MORE):
- add_task: {"title": "str", "priority": "low|normal|high|urgent"}
- add_habit: {"name": "str", "icon": "emoji"}
- add_note: {"content": "str"}
- start_focus: {"duration_minutes": int}
- show_dynamic_card: ...
"""
```

**This is crucial!** The prompt tells the AI:
1. **Who you are:** "You are JARVIS"
2. **Your job:** "parse intent and return JSON"
3. **What you can do:** List of valid actions
4. **How to respond:** "Output ONLY valid JSON"

**Why JSON?** Your Flutter app parses the response as JSON to update the UI. If AI returns gibberish, your app breaks!

#### The Bulletproof JSON Parser

```python
raw = response.content.strip()

# Find the first { and last }
start_index = raw.find('{')
end_index = raw.rfind('}')

if start_index != -1 and end_index != -1 and end_index > start_index:
    json_str = raw[start_index:end_index + 1]
    try:
        result = json.loads(json_str)
    except json.JSONDecodeError:
        clean = json_str.replace("```json", "").replace("```", "").strip()
        result = json.loads(clean)
```

**Why is this complex?** LLMs sometimes wrap JSON in markdown:
```
Here's your response:
```json
{"action": "add_task", "title": "Meeting"}
```
```

Your parser **extracts just the JSON**, cleans markdown, and returns it.

---

### Model Fallback Pattern

```python
MODEL_PRIORITIES = [
    "gemini-2.0-flash",
    "gemini-2.0-flash-001",
    "gemini-2.0-flash-lite",
]

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
            if "RESOURCE_EXHAUSTED" in str(e) or "429" in str(e):
                last_error = e
                continue
            raise
    
    if last_error is not None:
        raise last_error
```

**What's this doing?**

1. **Try primary model:** `gemini-2.0-flash` (fast, high quality)
2. **If rate-limited (429/RESOURCE_EXHAUSTED):** Try next model
3. **If quota exhausted on all:** Return error

**Why?** Google Gemini has quotas. If you hit the limit on one model, try a cheaper/faster one.

**The `timeout=8`:** If Gemini doesn't respond in 8 seconds, give up and try the next model.

---

### Credentials Handling

```python
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
```

**Two ways to authenticate with Google API:**

1. **Service Account** (preferred for servers):
   - Long-lived credentials in a JSON file
   - No user interaction needed
   - For backend-to-backend communication

2. **API Key** (fallback):
   ```python
   google_api_key=GOOGLE_API_KEY
   ```
   - Simpler but less secure
   - Embedded in code/env variables

**Your code tries service account first, falls back to API key.** This is professional!

---

## Advanced Patterns

### 1️⃣ Dependency Injection

If your endpoints share common setup:

```python
from fastapi import Depends

async def get_db():
    # Connect to database
    db = connect_to_db()
    try:
        yield db  # Give to endpoint
    finally:
        db.close()  # Cleanup

@app.get("/tasks")
async def get_tasks(db = Depends(get_db)):
    return db.query("SELECT * FROM tasks")
```

**Benefit:** Shared logic, automatic cleanup. You don't need this yet, but it's powerful.

---

### 2️⃣ Response Models (Type Safety)

Your endpoints return dicts. You could also create response models:

```python
class CommandResponse(BaseModel):
    actions: list
    response: str
    greeting_update: Optional[str] = None
    layout_order: list

@app.post("/command")
async def process_command(data: CommandRequest) -> CommandResponse:
    # ...
    return CommandResponse(
        actions=result.get('actions', []),
        response=result.get('response', ''),
        greeting_update=result.get('greeting_update'),
        layout_order=result.get('layout_order', [])
    )
```

**Benefits:**
- Type hints help catch bugs
- Auto-validated responses
- Better IDE autocomplete
- Auto-generated docs are more accurate

---

### 3️⃣ Background Tasks

If you need to do work without waiting:

```python
from fastapi import BackgroundTasks

@app.post("/analyze")
async def analyze(data: AnalysisRequest, background_tasks: BackgroundTasks):
    # Return immediately
    background_tasks.add_task(run_analysis, data.id)
    return {"status": "Analysis queued"}

def run_analysis(analysis_id: str):
    # This runs in the background (doesn't block the response)
    pass
```

**Use case:** Send an email without making the user wait.

---

### 4️⃣ Streaming Responses

For long-running tasks (e.g., live AI output):

```python
from fastapi.responses import StreamingResponse
import asyncio

@app.get("/stream")
async def stream_output():
    async def generate():
        for i in range(5):
            yield f"data: Processing step {i}...\n"
            await asyncio.sleep(1)
    
    return StreamingResponse(generate(), media_type="text/event-stream")
```

**Use case:** Show AI thinking in real-time as it generates response.

---

## Debugging & Best Practices

### 🔍 How to Debug

**1. Check the `/docs` endpoint:**
```
http://localhost:8000/docs
```
This opens Swagger UI—try your endpoints with example data right in your browser!

**2. Print debug info (your code already does this):**
```python
print(f"[AI Command] '{data.command}' → {len(result.get('actions', []))} actions")
```
Shows in your terminal when the endpoint runs.

**3. Use `logger` instead of `print` (professional):**
```python
import logging
logger = logging.getLogger(__name__)

logger.info(f"Processing command: {data.command}")
logger.error(f"AI failed: {error_msg}")
```

**4. Run with reload during development:**
```bash
uvicorn main:app --reload
```
Automatically restarts when you change code.

---

### ✅ Best Practices

**1. Always return a response, even on error:**
```python
except Exception as e:
    return {"status": "error", "message": str(e)}  # Don't crash!
```

**2. Validate early, fail fast:**
```python
if not data.command.strip():
    return {"error": "Command cannot be empty"}
```

**3. Log important events:**
```python
logger.info(f"User {user_name} executed command: {user_input}")
```

**4. Use type hints everywhere:**
```python
def _build_llm(model: str) -> ChatGoogleGenerativeAI:
    # Return type explicitly declared
    pass
```

**5. Never expose secrets in logs/responses:**
```python
# ❌ BAD
logger.info(f"Using API key: {GOOGLE_API_KEY}")

# ✅ GOOD
logger.info("Using Google Gemini API")
```

**6. Set reasonable timeouts:**
```python
response = await asyncio.wait_for(gemini.ainvoke(messages), timeout=8)
```

**7. Handle partial failures gracefully:**
```python
# Your code does this perfectly!
except asyncio.TimeoutError:
    return fallback_response
except Exception:
    return generic_error_response
```

---

## Testing Your Endpoints

Create `test_main.py`:

```python
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_command_endpoint():
    response = client.post("/command", json={
        "command": "add task",
        "user_name": "Uzair",
        "context": {}
    })
    assert response.status_code == 200
    data = response.json()
    assert "actions" in data
    assert "response" in data
```

Run: `pytest test_main.py`

---

## Running Your Backend

**Start the server:**
```bash
cd backend_fastapi
uvicorn main:app --reload --port 8000
```

**Test an endpoint:**
```bash
curl -X POST http://localhost:8000/command \
  -H "Content-Type: application/json" \
  -d '{
    "command": "add task meeting at 3pm",
    "user_name": "Uzair Khan",
    "context": {}
  }'
```

**Interactive docs:**
```
http://localhost:8000/docs
http://localhost:8000/redoc
```

---

## Key Takeaways: You're Now a FastAPI Engineer! 🎯

| Concept | Your Project | Purpose |
|---------|--------------|---------|
| **FastAPI app** | `app = FastAPI(title="...")` | Creates the web server |
| **Middleware** | `CORSMiddleware` | Allows Flutter ↔ Backend communication |
| **Endpoints** | `@app.post("/command")` | Defines URLs your frontend calls |
| **Pydantic models** | `CommandRequest`, `InsightRequest` | Validates incoming data automatically |
| **Async/await** | `async def`, `await gemini.ainvoke()` | Handles thousands of users simultaneously |
| **Error handling** | `try/except` | Gracefully handles failures |
| **System prompts** | `COMMAND_PROMPT`, `INSIGHT_PROMPT` | Controls AI behavior |
| **JSON parsing** | Bulletproof parser | Handles LLM quirks |
| **Model fallback** | Try multiple models if one fails | Robust failure handling |

---

## Next Steps: Level Up! 🚀

1. **Add a database:** Use SQLAlchemy + PostgreSQL for persistent data
2. **Add authentication:** JWT tokens so only authorized users access endpoints
3. **Add rate limiting:** Prevent abuse of your API
4. **Deploy to production:** Use Docker + AWS/Google Cloud
5. **Add logging:** Use `logging` module instead of `print`
6. **Add tests:** pytest for automated testing
7. **Monitor performance:** Track response times, errors per endpoint
8. **Add caching:** Cache frequently-called endpoints (Redis)

---

## You're Not a Vibe Coder Anymore! 💪

You now understand:
- ✅ How FastAPI receives and validates requests
- ✅ Why async/await matters for performance
- ✅ How error handling makes apps reliable
- ✅ How LLM integration works with system prompts
- ✅ How to architect a real backend service

Now go build! Ask yourself:
- "What new endpoint can I add?"
- "How would I add a database to persist data?"
- "What if 10,000 users hit this endpoint simultaneously?"

That's the mindset of a software engineer. 🎓

---

### 📚 Resources to Deepen Knowledge

- [FastAPI Official Docs](https://fastapi.tiangolo.com/) - The best docs ever written
- [Pydantic Docs](https://docs.pydantic.dev/) - Data validation
- [Async/Await in Python](https://realpython.com/async-io-python/) - Deep dive
- [LangChain Docs](https://python.langchain.com/) - AI integration patterns
- Your `/docs` endpoint - Your actual API!

Good luck! 🚀
