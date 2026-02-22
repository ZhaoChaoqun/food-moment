"""Storage proxy endpoint for serving images from Azure Blob Storage / Azurite."""

import logging

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import Response

from app.services.storage_service import storage_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/storage", tags=["Storage"])


@router.get("/{blob_name}")
async def get_blob(blob_name: str):
    """Proxy-download an image from blob storage.

    This allows iOS clients to load images via the API base URL
    instead of needing direct access to Azure/Azurite.
    """
    try:
        data, content_type = await storage_service.download_image(blob_name)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Image not found",
        )

    return Response(
        content=data,
        media_type=content_type,
        headers={"Cache-Control": "public, max-age=86400"},
    )
