from pydantic import BaseModel
from typing import Optional, List, Literal
from datetime import date


# ============================================================
# チャット関連モデル
# ============================================================

ChatMode = Literal["fast", "thinking"]


class ChatRequest(BaseModel):
    """チャットリクエスト"""
    message: str
    image_base64: Optional[str] = None
    chat_history: Optional[List[dict]] = None
    user_context: Optional[dict] = None
    mode: ChatMode = "fast"
    chat_date: Optional[date] = None  # ai.py用に追加


class ChatResponse(BaseModel):
    """チャットレスポンス"""
    response: str
    mode: ChatMode


# ============================================================
# アドバイス関連モデル
# ============================================================

class AdviceRequest(BaseModel):
    """ホーム画面アドバイスリクエスト"""
    today_calories: int
    goal_calories: int
    today_protein: int = 0
    today_fat: int = 0
    today_carbs: int = 0
    today_meals: str = ""
    meal_count: int = 0


class AdviceResponse(BaseModel):
    """アドバイスレスポンス"""
    advice: str


# ============================================================
# 食事コメント関連モデル
# ============================================================

class MealCommentRequest(BaseModel):
    """食事詳細コメントリクエスト"""
    meal_name: str
    calories: int
    protein: float = 0
    fat: float = 0
    carbs: float = 0
    sugar: float = 0
    fiber: float = 0
    sodium: float = 0


class MealCommentResponse(BaseModel):
    """食事コメントレスポンス"""
    comment: str


# ============================================================
# 食事分析関連モデル
# ============================================================

class FoodItem(BaseModel):
    """食品アイテム（全栄養素対応）"""
    name: str
    amount: str
    calories: int
    protein: float
    fat: float
    carbs: float
    sugar: float = 0
    fiber: float = 0
    sodium: float = 0


class DetailedMealAnalysis(BaseModel):
    """詳細な食事分析結果（全栄養素対応）"""
    food_items: List[FoodItem]
    total_calories: int
    total_protein: float
    total_fat: float
    total_carbs: float
    total_sugar: float = 0
    total_fiber: float = 0
    total_sodium: float = 0
    character_comment: str


class MealAnalysisRequest(BaseModel):
    """食事分析リクエスト"""
    image_base64: Optional[str] = None
    description: Optional[str] = None


class MealAnalysisResponse(BaseModel):
    """食事分析レスポンス"""
    analysis: DetailedMealAnalysis


# ============================================================
# チャットメッセージDB関連モデル（ai.py用）
# ============================================================

class ChatMessageCreate(BaseModel):
    """チャットメッセージ作成用"""
    message: str
    is_user: bool
    image_url: Optional[str] = None
    chat_date: Optional[str] = None


class ChatMessageResponse(BaseModel):
    """チャットメッセージレスポンス"""
    id: str
    user_id: str
    is_user: bool
    message: str
    image_url: Optional[str] = None
    chat_date: str
    created_at: str


class ChatResponseWithMessages(BaseModel):
    """チャットレスポンス（メッセージ付き）- ai.py用"""
    response: str
    user_message: ChatMessageResponse
    ai_message: ChatMessageResponse