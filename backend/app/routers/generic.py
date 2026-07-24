from fastapi import APIRouter, Depends, HTTPException, Request
from app.dependencies import get_authorization
from app.config import SUPABASE_URL, SUPABASE_ANON_KEY
import httpx

router = APIRouter()
ALLOWED_TABLES = ["profiles", "projects", "sessions"]


def check_table(table: str):
    if table not in ALLOWED_TABLES:
        raise HTTPException(status_code=400, detail=f"Table '{table}' is not allowed")


def build_headers(token: str, return_representation: bool = False):
    headers = {
        "Authorization": token,
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
    }
    if return_representation:
        headers["Prefer"] = "return=representation"
    return headers


@router.post("/{table}")
async def create_row(table: str, body: dict, token: str = Depends(get_authorization)):
    check_table(table)
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=body, headers=build_headers(token, return_representation=True))
    if not response.text:
        return {"status": "success"}
    return response.json()


@router.get("/{table}")
async def list_rows(table: str, request: Request, token: str = Depends(get_authorization)):
    check_table(table)
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    params = dict(request.query_params)
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params, headers=build_headers(token))
    return response.json()


@router.patch("/{table}/{id}")
async def update_row(table: str, id: str, body: dict, token: str = Depends(get_authorization)):
    check_table(table)
    url = f"{SUPABASE_URL}/rest/v1/{table}?id=eq.{id}"
    async with httpx.AsyncClient() as client:
        response = await client.patch(url, json=body, headers=build_headers(token))
    return response.json()


@router.delete("/{table}/{id}")
async def delete_row(table: str, id: str, token: str = Depends(get_authorization)):
    check_table(table)
    url = f"{SUPABASE_URL}/rest/v1/{table}?id=eq.{id}"
    async with httpx.AsyncClient() as client:
        response = await client.delete(url, headers=build_headers(token))
    return response.json()