from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.routers import auth, users, meals, exercises, weights, ai, stats, meal_analysis, chat_router
from app.routers.feature_requests_router import router as feature_requests_router
from app.config import get_settings
from app.middleware.rate_limit import RateLimitMiddleware
import logging

settings = get_settings()

# ロギング設定（本番では INFO、開発では DEBUG）
logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Caloken API",
    description="カロ研（カロリー研究）アプリのバックエンドAPI",
    version="1.0.0",
    # 本番では /docs と /redoc を無効化
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# Rate Limiting ミドルウェア（本番のみ有効）
app.add_middleware(
    RateLimitMiddleware,
    requests_per_minute=60,   # 1分あたり60リクエスト
    requests_per_hour=1000,   # 1時間あたり1000リクエスト
    enabled=settings.is_production  # 本番のみ有効
)

# CORS設定
if settings.is_production:
    # 本番環境: 必要なオリジンのみ許可
    # iOSアプリはオリジンを送信しないため、空リストでもOK
    # 管理画面等がある場合はそのURLを追加
    allowed_origins = [
        # "https://admin.caloken.app",  # 管理画面がある場合
        # "https://caloken.vercel.app", # Webアプリがある場合
    ]
else:
    # 開発環境: 全て許可
    allowed_origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins if allowed_origins else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ルーター登録
app.include_router(auth.router, prefix="/api")
app.include_router(users.router, prefix="/api")
app.include_router(meals.router, prefix="/api")
app.include_router(exercises.router, prefix="/api")
app.include_router(weights.router, prefix="/api")
app.include_router(ai.router, prefix="/api")
app.include_router(stats.router, prefix="/api")
app.include_router(meal_analysis.router, prefix="/api")
app.include_router(feature_requests_router, prefix="/api")

# chat_router登録（prefix="/api/v1"を持つので追加prefixなし）
app.include_router(chat_router.router)


@app.get("/")
async def root():
    """ヘルスチェック"""
    return {
        "message": "Caloken API is running 🐱",
        "version": "1.0.0",
        "status": "healthy",
        "environment": settings.app_env
    }


@app.get("/health")
async def health_check():
    """ヘルスチェック（Railway用）"""
    return {"status": "ok"}


# グローバル例外ハンドラー（本番では詳細エラーを隠す）
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    if settings.is_production:
        # 本番: 詳細を隠す
        logger.error(f"Unhandled error: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": "Internal server error"}
        )
    else:
        # 開発: 詳細を表示
        logger.error(f"Unhandled error: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": str(exc), "type": type(exc).__name__}
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)