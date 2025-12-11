from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, users, meals, exercises, weights, ai, stats, meal_analysis, chat_router
from app.routers.feature_requests_router import router as feature_requests_router  # ← この形式で追加
from app.config import get_settings



settings = get_settings()

app = FastAPI(
    title="Caloken API",
    description="カロ研（カロリー研究）アプリのバックエンドAPI",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",      # Next.js開発
        "https://*.vercel.app",       # Vercel本番
        "*"                           # iOS開発用（本番では制限する）
    ],
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

# ✅ chat_router登録（prefix="/api/v1"を持つので追加prefixなし）
app.include_router(chat_router.router)


@app.get("/")
async def root():
    """ヘルスチェック"""
    return {
        "message": "Caloken API is running 🐱",
        "version": "1.0.0",
        "status": "healthy"
    }


@app.get("/health")
async def health_check():
    """ヘルスチェック（Railway用）"""
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)