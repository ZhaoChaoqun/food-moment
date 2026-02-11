from pydantic import BaseModel


class AppleAuthRequest(BaseModel):
    identity_token: str
    authorization_code: str
    full_name: str | None = None
    email: str | None = None


class DeviceAuthRequest(BaseModel):
    device_id: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshTokenRequest(BaseModel):
    refresh_token: str
