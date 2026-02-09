"""Apple Sign In token verification and JWT service."""

import uuid
from datetime import datetime, timedelta, timezone

import httpx
from jose import jwt as jose_jwt, jwk, JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.user import User


APPLE_PUBLIC_KEYS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"

# Cache Apple public keys to avoid repeated fetching
_apple_keys_cache: dict | None = None
_apple_keys_fetched_at: datetime | None = None
APPLE_KEYS_CACHE_DURATION = timedelta(hours=24)


async def _get_apple_public_keys() -> dict:
    """Fetch Apple's public keys with caching."""
    global _apple_keys_cache, _apple_keys_fetched_at

    now = datetime.now(timezone.utc)
    if (
        _apple_keys_cache is not None
        and _apple_keys_fetched_at is not None
        and now - _apple_keys_fetched_at < APPLE_KEYS_CACHE_DURATION
    ):
        return _apple_keys_cache

    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(APPLE_PUBLIC_KEYS_URL)
        response.raise_for_status()
        _apple_keys_cache = response.json()
        _apple_keys_fetched_at = now
        return _apple_keys_cache


async def verify_apple_identity_token(identity_token: str) -> dict:
    """Verify Apple identity token and return claims.

    Steps:
    1. Fetch Apple's public keys
    2. Get the key ID (kid) from the token header
    3. Match with Apple's keys and verify signature
    4. Return the claims (sub, email, etc.)

    Returns:
        dict with keys: sub (Apple user ID), email (optional)

    Raises:
        ValueError: If token verification fails
    """
    try:
        # Decode header to get kid (key ID)
        unverified_header = jose_jwt.get_unverified_header(identity_token)
        kid = unverified_header.get("kid")
        if not kid:
            raise ValueError("Token header missing 'kid'")

        # Fetch Apple's public keys
        apple_keys_data = await _get_apple_public_keys()
        keys = apple_keys_data.get("keys", [])

        # Find the matching key
        matching_key = None
        for key_data in keys:
            if key_data.get("kid") == kid:
                matching_key = key_data
                break

        if matching_key is None:
            raise ValueError(f"No matching Apple public key found for kid: {kid}")

        # Construct the public key
        public_key = jwk.construct(matching_key)

        # Decode and verify the token
        claims = jose_jwt.decode(
            identity_token,
            public_key,
            algorithms=["RS256"],
            issuer=APPLE_ISSUER,
            options={
                "verify_aud": False,  # Audience is app-specific, skip for flexibility
                "verify_exp": True,
                "verify_iss": True,
            },
        )

        apple_user_id = claims.get("sub")
        if not apple_user_id:
            raise ValueError("Token missing 'sub' claim")

        return {
            "sub": apple_user_id,
            "email": claims.get("email"),
            "email_verified": claims.get("email_verified", False),
        }

    except JWTError as e:
        raise ValueError(f"Apple identity token verification failed: {e}")


def create_access_token(user_id: uuid.UUID) -> str:
    """Generate a JWT access token.

    Args:
        user_id: The user's UUID

    Returns:
        Encoded JWT string
    """
    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {
        "sub": str(user_id),
        "iat": now,
        "exp": expire,
        "type": "access",
    }
    return jose_jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def create_refresh_token(user_id: uuid.UUID) -> str:
    """Generate a JWT refresh token (longer lived).

    Args:
        user_id: The user's UUID

    Returns:
        Encoded JWT string
    """
    now = datetime.now(timezone.utc)
    expire = now + timedelta(days=30)
    payload = {
        "sub": str(user_id),
        "iat": now,
        "exp": expire,
        "type": "refresh",
    }
    return jose_jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def verify_refresh_token(refresh_token: str) -> uuid.UUID:
    """Verify a refresh token and return the user_id.

    Args:
        refresh_token: The refresh token to verify

    Returns:
        The user's UUID

    Raises:
        ValueError: If the token is invalid or not a refresh token
    """
    try:
        payload = jose_jwt.decode(
            refresh_token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
        token_type = payload.get("type")
        if token_type != "refresh":
            raise ValueError("Token is not a refresh token")

        user_id = payload.get("sub")
        if user_id is None:
            raise ValueError("Token missing 'sub' claim")

        return uuid.UUID(user_id)
    except JWTError as e:
        raise ValueError(f"Invalid refresh token: {e}")


async def find_user_by_apple_id(db: AsyncSession, apple_user_id: str) -> User | None:
    """Find a user by their Apple user ID."""
    result = await db.execute(
        select(User).where(User.apple_user_id == apple_user_id)
    )
    return result.scalar_one_or_none()


async def create_user_from_apple(
    db: AsyncSession,
    apple_user_id: str,
    email: str | None = None,
    full_name: str | None = None,
) -> User:
    """Create a new user from Apple Sign In data.

    Args:
        db: Database session
        apple_user_id: Apple's unique user identifier (sub claim)
        email: User's email from Apple
        full_name: User's display name from Apple

    Returns:
        The newly created User
    """
    display_name = full_name or "FoodMoment User"

    user = User(
        apple_user_id=apple_user_id,
        display_name=display_name,
        email=email,
    )
    db.add(user)
    await db.flush()
    return user
