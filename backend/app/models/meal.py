from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class MealLogBase(BaseModel):
    """食事記録の基本モデル"""
    name: str
    calories: int = 0
    protein: float = 0
    fat: float = 0
    carbs: float = 0
    sugar: float = 0
    fiber: float = 0
    sodium: float = 0
    emoji: str = "🍽️"
    image_url: Optional[str] = None


class MealLogCreate(MealLogBase):
    """食事記録作成用"""
    logged_at: Optional[datetime] = None


class MealLogUpdate(BaseModel):
    """食事記録更新用"""
    name: Optional[str] = None
    calories: Optional[int] = None
    protein: Optional[float] = None
    fat: Optional[float] = None
    carbs: Optional[float] = None
    sugar: Optional[float] = None
    fiber: Optional[float] = None
    sodium: Optional[float] = None
    emoji: Optional[str] = None
    image_url: Optional[str] = None
    logged_at: Optional[datetime] = None


class MealLogResponse(MealLogBase):
    """食事記録レスポンス"""
    id: str
    user_id: str
    logged_at: datetime
    created_at: datetime
    
    class Config:
        from_attributes = True


class SavedMealBase(BaseModel):
    """保存済み食事の基本モデル"""
    name: str
    calories: int = 0
    protein: float = 0
    fat: float = 0
    carbs: float = 0
    emoji: str = "🍽️"
    image_url: Optional[str] = None


class SavedMealCreate(SavedMealBase):
    """保存済み食事作成用"""
    pass


class SavedMealResponse(SavedMealBase):
    """保存済み食事レスポンス"""
    id: str
    user_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class DailyMealSummary(BaseModel):
    """日別食事サマリー"""
    date: str
    total_calories: int
    total_protein: float
    total_fat: float
    total_carbs: float
    meal_count: int
    meals: List[MealLogResponse]
