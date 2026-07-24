from fastapi import Header, HTTPException

def get_authorization(authorization: str = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    return authorization