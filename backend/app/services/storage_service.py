"""Azure Blob Storage service (compatible with Azurite for local dev)."""

import logging
import uuid

from azure.storage.blob.aio import BlobServiceClient

from app.config import settings

logger = logging.getLogger(__name__)


class StorageService:
    """Azure Blob Storage 异步服务。

    本地开发使用 Azurite 模拟器，生产环境使用 Azure Blob Storage。
    通过 AZURE_STORAGE_CONNECTION_STRING 环境变量切换。
    """

    def __init__(self) -> None:
        self._client: BlobServiceClient | None = None

    async def init(self) -> None:
        """初始化 BlobServiceClient 并确保容器存在。"""
        self._client = BlobServiceClient.from_connection_string(
            settings.azure_storage_connection_string
        )
        container = self._client.get_container_client(settings.azure_storage_container)
        try:
            await container.create_container(public_access="blob")
            logger.info(f"Created storage container: {settings.azure_storage_container}")
        except Exception:
            # Container already exists
            logger.debug(f"Storage container already exists: {settings.azure_storage_container}")

    async def upload_image(
        self,
        image_data: bytes,
        content_type: str = "image/jpeg",
    ) -> str:
        """上传图片到 Blob Storage。

        Returns:
            公开访问 URL
        """
        assert self._client is not None, "StorageService not initialized"

        ext = "jpg"
        if content_type == "image/png":
            ext = "png"
        elif content_type == "image/webp":
            ext = "webp"

        blob_name = f"{uuid.uuid4().hex}.{ext}"
        container = self._client.get_container_client(settings.azure_storage_container)
        blob = container.get_blob_client(blob_name)

        await blob.upload_blob(
            image_data,
            content_settings={"content_type": content_type},
            overwrite=True,
        )

        url = f"{settings.storage_public_url}/{blob_name}"
        logger.info(f"Uploaded image: {blob_name} ({len(image_data)} bytes) -> {url}")
        return url

    async def delete_image(self, blob_name: str) -> None:
        """删除 Blob。"""
        assert self._client is not None, "StorageService not initialized"

        container = self._client.get_container_client(settings.azure_storage_container)
        blob = container.get_blob_client(blob_name)
        try:
            await blob.delete_blob()
            logger.info(f"Deleted image: {blob_name}")
        except Exception as e:
            logger.warning(f"Failed to delete image {blob_name}: {e}")

    async def close(self) -> None:
        """关闭连接。"""
        if self._client:
            await self._client.close()
            self._client = None


storage_service = StorageService()
