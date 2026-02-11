import logging

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select, delete

from app.config import settings
from app.schemas.auth import AppleAuthRequest, DeviceAuthRequest, TokenResponse, RefreshTokenRequest
from app.api.deps import CurrentUserId, DbSession
from app.services import auth_service
from app.models.user import User
from app.models.meal import MealRecord
from app.models.water import WaterLog, WeightLog

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/device", response_model=TokenResponse)
async def device_auth(request: DeviceAuthRequest, db: DbSession):
    """Authenticate with a device UUID (anonymous auth).

    First-time: creates a new user associated with the device ID.
    Subsequent: finds existing user and returns a new token.
    No Apple Sign-In required.
    """
    if not request.device_id or len(request.device_id) < 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid device_id",
        )

    user = await auth_service.find_or_create_user_by_device_id(db, request.device_id)
    logger.info(f"Device auth for user: {user.id} (device_id={request.device_id[:8]}...)")

    access_token = auth_service.create_access_token(user.id)
    refresh_token = auth_service.create_refresh_token(user.id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.post("/apple", response_model=TokenResponse)
async def sign_in_with_apple(request: AppleAuthRequest, db: DbSession):
    """Sign in with Apple - verify identity token and create/login user."""
    # Step 1: Verify Apple identity token
    try:
        claims = await auth_service.verify_apple_identity_token(request.identity_token)
    except ValueError as e:
        logger.warning(f"Apple token verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Apple identity token: {e}",
        )

    apple_user_id = claims["sub"]

    # Step 2: Find or create user
    user = await auth_service.find_user_by_apple_id(db, apple_user_id)
    if user is None:
        user = await auth_service.create_user_from_apple(
            db=db,
            apple_user_id=apple_user_id,
            email=request.email or claims.get("email"),
            full_name=request.full_name,
        )
        await db.flush()
        logger.info(f"New user created: {user.id} (apple_user_id={apple_user_id})")
    else:
        # Update email/name if provided (Apple only sends these on first sign-in)
        if request.email and not user.email:
            user.email = request.email
        if request.full_name and user.display_name == "FoodMoment User":
            user.display_name = request.full_name
        logger.info(f"Existing user signed in: {user.id}")

    # Step 3: Generate tokens
    access_token = auth_service.create_access_token(user.id)
    refresh_token = auth_service.create_refresh_token(user.id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(request: RefreshTokenRequest, db: DbSession):
    """Refresh an expired access token."""
    try:
        user_id = auth_service.verify_refresh_token(request.refresh_token)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid refresh token: {e}",
        )

    # Verify user still exists
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    # Generate new tokens
    access_token = auth_service.create_access_token(user_id)
    new_refresh_token = auth_service.create_refresh_token(user_id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        expires_in=settings.access_token_expire_minutes * 60,
    )


@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(user_id: CurrentUserId, db: DbSession):
    """Delete user account and all associated data (App Store requirement).

    This cascades to delete all meal records, water logs, weight logs, etc.
    """
    # Delete water logs
    await db.execute(delete(WaterLog).where(WaterLog.user_id == user_id))

    # Delete weight logs
    await db.execute(delete(WeightLog).where(WeightLog.user_id == user_id))

    # Delete meal records (cascade will delete detected_foods)
    await db.execute(delete(MealRecord).where(MealRecord.user_id == user_id))

    # Delete user
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    await db.delete(user)

    logger.info(f"User account deleted: {user_id}")
