"""
Caloken Backend API
カロ研バックエンドサーバー
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.routers import chat_router

# ロギング設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """アプリケーションのライフサイクル管理"""
    logger.info("🚀 Caloken Backend starting...")
    yield
    logger.info("👋 Caloken Backend shutting down...")


app = FastAPI(
    title="Caloken API",
    description="カロ研（Caloken）- 健康管理アプリのバックエンドAPI",
    version="1.0.0",
    lifespan=lifespan
)

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 本番環境では適切に制限する
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ルーターの登録
app.include_router(
    chat_router.router,
    tags=["Chat & Analysis"]
)


@app.get("/")
async def root():
    """ヘルスチェック"""
    return {
        "status": "healthy",
        "app": "Caloken API",
        "version": "1.0.0"
    }


@app.get("/health")
async def health_check():
    """詳細ヘルスチェック"""
    return {
        "status": "healthy",
        "services": {
            "api": "running",
            "gemini": "configured"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )