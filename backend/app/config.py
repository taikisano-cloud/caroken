"""
Caloken Backend Configuration
環境設定
"""

from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    """アプリケーション設定"""
    
    # Gemini API
    gemini_api_key: str = ""
    
    # サーバー設定
    debug: bool = False
    
    # データベース（将来用）
    database_url: Optional[str] = None
    
    # Supabase（将来用）
    supabase_url: Optional[str] = None
    supabase_key: Optional[str] = None
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"


@lru_cache()
def get_settings() -> Settings:
    """設定をキャッシュして返す"""
    return Settings()