from pydantic_settings import BaseSettings
from pydantic import Field
from functools import lru_cache


class Settings(BaseSettings):
    """アプリケーション設定"""
    
    # Supabase
    supabase_url: str
    supabase_key: str = Field(validation_alias="SUPABASE_ANON_KEY")  # anon key
    supabase_service_role_key: str
    supabase_jwt_secret: str
    
    # Gemini AI
    gemini_api_key: str
    
    # App - 環境変数 ENVIRONMENT から取得
    app_env: str = Field(default="development", validation_alias="ENVIRONMENT")
    
    @property
    def debug(self) -> bool:
        """本番環境ではデバッグを無効化"""
        return self.app_env != "production"
    
    @property
    def is_production(self) -> bool:
        """本番環境かどうか"""
        return self.app_env == "production"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """設定のシングルトンインスタンスを取得"""
    return Settings()