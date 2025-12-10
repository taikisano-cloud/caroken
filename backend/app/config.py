from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """アプリケーション設定"""
    
    # Supabase
    supabase_url: str
    supabase_key: str  # anon key (環境変数: SUPABASE_KEY)
    supabase_service_role_key: str
    
    # Gemini AI
    gemini_api_key: str
    
    # App
    app_env: str = "development"
    debug: bool = True
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """設定のシングルトンインスタンスを取得"""
    return Settings()