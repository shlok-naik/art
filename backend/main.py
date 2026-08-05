from fastapi import FastAPI
from pydantic import BaseModel
from profanity_check import predict, predict_prob

from fastapi.middleware.cors import CORSMiddleware

# The Flutter app talks to Supabase directly (supabase_flutter + RLS); this
# backend no longer proxies CRUD. It exists for server-side work that can't
# live in the app: the RevenueCat webhook and the league promotion/relegation
# job, plus anything better run server-side — currently comment moderation,
# via a local scikit-learn classifier (alt-profanity-check) rather than a
# paid/keyed external API.
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
    score: float


@app.post("/moderate", response_model=ModerationResponse)
def moderate(body: ModerationRequest):
    # predict() is a trained linear classifier (not substring matching), so
    # it catches obfuscation like "f u c k" or "sh1t" that a wordlist misses.
    flagged = bool(predict([body.text])[0])
    score = float(predict_prob([body.text])[0])
    return ModerationResponse(flagged=flagged, score=score)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
