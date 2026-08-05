import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from fastapi.middleware.cors import CORSMiddleware

from app.config import OPENAI_API_KEY

# The Flutter app talks to Supabase directly (supabase_flutter + RLS); this
# backend no longer proxies CRUD. It exists for server-side work that can't
# live in the app: the RevenueCat webhook and the league promotion/relegation
# job, plus anything that needs a secret key kept off the client — currently
# just comment moderation via OpenAI.
app = FastAPI(title="art backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok"}


class ModerationRequest(BaseModel):
    text: str


class ModerationResponse(BaseModel):
    flagged: bool
    categories: list[str]


@app.post("/moderate", response_model=ModerationResponse)
async def moderate(body: ModerationRequest):
    if not OPENAI_API_KEY:
        raise HTTPException(status_code=500, detail="OPENAI_API_KEY is not configured")

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api.openai.com/v1/moderations",
            headers={"Authorization": f"Bearer {OPENAI_API_KEY}"},
            json={"model": "omni-moderation-latest", "input": body.text},
            timeout=10,
        )
    if response.status_code != 200:
        raise HTTPException(status_code=502, detail="Moderation request failed")

    result = response.json()["results"][0]
    categories = [name for name, flagged in result["categories"].items() if flagged]
    return ModerationResponse(flagged=result["flagged"], categories=categories)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
