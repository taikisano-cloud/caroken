from pydantic import BaseModel
from typing import Optional, List
from datetime import date, datetime


class ChatMessageBase(BaseModel):
    """チャットメッセージの基本モデル"""
    message: Optional[str] = None
    image_url: Optional[str] = None
    is_user: bool = True


class ChatMessageCreate(ChatMessageBase):
    """チャットメッセージ作成用"""
    chat_date: Optional[date] = None


class ChatMessageResponse(ChatMessageBase):
    """チャットメッセージレスポンス"""
    id: str
    user_id: str
    chat_date: date
    created_at: datetime
    
    class Config:
        from_attributes = True


class ChatRequest(BaseModel):
    """AIチャットリクエスト"""
    message: str
    image_base64: Optional[str] = None
    chat_date: Optional[date] = None


class ChatResponse(BaseModel):
    """AIチャットレスポンス"""
    response: str
    user_message: ChatMessageResponse
    ai_message: ChatMessageResponse


class MealAnalysisRequest(BaseModel):
    """食事分析リクエスト"""
    image_base64: Optional[str] = None
    description: Optional[str] = None


class MealAnalysisResponse(BaseModel):
    """食事分析レスポンス"""
    name: str
    calories: int
    protein: float
    fat: float
    carbs: float
    sugar: float = 0
    fiber: float = 0
    sodium: float = 0
    emoji: str = "🍽️"
    comment: str
    confidence: float = 0.8


class FoodItem(BaseModel):
    """個別食品"""
    name: str
    amount: str
    calories: int
    protein: float
    fat: float
    carbs: float


class DetailedMealAnalysis(BaseModel):
    """詳細な食事分析"""
    food_items: List[FoodItem]
    total_calories: int
    total_protein: float
    total_fat: float
    total_carbs: float
    total_sugar: float = 0
    total_fiber: float = 0
    total_sodium: float = 0
    character_comment: str
