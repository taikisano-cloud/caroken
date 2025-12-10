from supabase import create_client, Client
from app.config import get_settings

settings = get_settings()

# Supabaseクライアント（通常のRLS適用）
supabase: Client = create_client(
    settings.supabase_url,
    settings.supabase_key
)

# Supabaseクライアント（管理者用、RLSバイパス）
supabase_admin: Client = create_client(
    settings.supabase_url,
    settings.supabase_service_role_key
)


def get_supabase() -> Client:
    """通常のSupabaseクライアントを取得"""
    return supabase


def get_supabase_admin() -> Client:
    """管理者用Supabaseクライアントを取得"""
    return supabase_admin
