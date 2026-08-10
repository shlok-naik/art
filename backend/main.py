from fastapi import FastAPI
from pydantic import BaseModel, Field
from better_profanity import profanity

from fastapi.middleware.cors import CORSMiddleware

profanity.load_censor_words()

# The Flutter app talks to Supabase directly (supabase_flutter + RLS); this
# backend doesn't proxy CRUD. It exists for anything better run server-side.
# Today that's just comment moderation, via a local wordlist censor
# (better-profanity) rather than a paid/keyed external API; future
# server-side work (e.g. a RevenueCat webhook) would live here too.
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
    # Comments are capped at 500 chars client-side; 2000 gives headroom for
    # any future longer field while still bounding abuse of the endpoint.
    text: str = Field(max_length=2000)


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
