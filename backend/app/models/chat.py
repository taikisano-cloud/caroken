from pydantic import BaseModel
from typing import Optional, List, Literal


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
    mode: ChatMode = "fast"  # "fast" or "thinking"


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
    sugar: float = 0       # 糖分 (g)
    fiber: float = 0       # 食物繊維 (g)
    sodium: float = 0      # ナトリウム (mg)


class DetailedMealAnalysis(BaseModel):
    """詳細な食事分析結果（全栄養素対応）"""
    food_items: List[FoodItem]
    total_calories: int
    total_protein: float
    total_fat: float
    total_carbs: float
    total_sugar: float = 0      # 糖分合計 (g)
    total_fiber: float = 0      # 食物繊維合計 (g)
    total_sodium: float = 0     # ナトリウム合計 (mg)
    character_comment: str


class MealAnalysisRequest(BaseModel):
    """食事分析リクエスト"""
    image_base64: Optional[str] = None
    description: Optional[str] = None


class MealAnalysisResponse(BaseModel):
    """食事分析レスポンス"""
    analysis: DetailedMealAnalysis