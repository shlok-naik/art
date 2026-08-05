from fastapi import FastAPI
from pydantic import BaseModel
from better_profanity import profanity

from fastapi.middleware.cors import CORSMiddleware

profanity.load_censor_words()

# The Flutter app talks to Supabase directly (supabase_flutter + RLS); this
# backend no longer proxies CRUD. It exists for server-side work that can't
# live in the app: the RevenueCat webhook and the league promotion/relegation
# job, plus anything better run server-side — currently comment moderation,
# via a local wordlist censor (better-profanity) rather than a paid/keyed
# external API.
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
    censored: str


@app.post("/moderate", response_model=ModerationResponse)
def moderate(body: ModerationRequest):
    flagged = profanity.contains_profanity(body.text)
    censored = profanity.censor(body.text) if flagged else body.text
    return ModerationResponse(flagged=flagged, censored=censored)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
