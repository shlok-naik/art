from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# The Flutter app talks to Supabase directly (supabase_flutter + RLS); this
# backend no longer proxies CRUD. It exists for server-side work that can't
# live in the app: the RevenueCat webhook and the league promotion/relegation
# job, both still to come.
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


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
