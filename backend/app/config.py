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
    anthropic_proxy_key: str = ""

    # Storage - Azure Blob Storage（本地 Azurite / 生产 Azure）
    azure_storage_connection_string: str = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"
    azure_storage_container: str = "uploads"
    storage_public_url: str = "http://127.0.0.1:10000/devstoreaccount1/uploads"

    # Logging
    log_level: str = "INFO"

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
