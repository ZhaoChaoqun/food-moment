from datetime import datetime, timezone

from pydantic import BaseModel, model_validator


class AppBaseModel(BaseModel):
    """所有 Response schema 的基类。

    统一将 naive datetime 转换为 UTC timezone-aware，
    确保序列化输出始终为 ISO 8601 带时区格式：
    "2026-02-20T14:07:49.969004Z"
    """

    model_config = {"from_attributes": True}

    @model_validator(mode="after")
    def _ensure_utc_datetimes(self) -> "AppBaseModel":
        for field_name in type(self).model_fields:
            value = getattr(self, field_name)
            if isinstance(value, datetime) and value.tzinfo is None:
                object.__setattr__(self, field_name, value.replace(tzinfo=timezone.utc))
        return self
