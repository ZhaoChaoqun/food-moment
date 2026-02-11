from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # App
    app_name: str = "FoodMoment API"
    debug: bool = True
    api_v1_prefix: str = "/api/v1"

    # Database
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/foodmoment"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # JWT
    jwt_secret_key: str = "your-secret-key-change-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days

    # AI Service - Anthropic Claude (via Agent Maestro proxy)
    anthropic_base_url: str = "http://localhost:23333/api/anthropic"
    anthropic_model: str = "claude-opus-4.6-fast"
    anthropic_enabled: bool = True

    # Storage - MinIO / S3 兼容
    storage_provider: str = "minio"  # minio, s3, azure
    minio_endpoint: str = "localhost:9000"
    minio_access_key: str = "minioadmin"
    minio_secret_key: str = "minioadmin123"
    minio_bucket: str = "uploads"
    minio_secure: bool = False
    storage_public_url: str = "http://localhost:9000/uploads"

    # Legacy OSS config (阿里云 OSS)
    oss_endpoint: str = ""
    oss_bucket: str = ""
    oss_access_key: str = ""
    oss_secret_key: str = ""

    # Logging
    log_level: str = "INFO"

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
