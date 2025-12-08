from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class WeightLogBase(BaseModel):
    """体重記録の基本モデル"""
    weight_kg: float


class WeightLogCreate(WeightLogBase):
    """体重記録作成用"""
    logged_at: Optional[datetime] = None


class WeightLogUpdate(BaseModel):
    """体重記録更新用"""
    weight_kg: Optional[float] = None
    logged_at: Optional[datetime] = None


class WeightLogResponse(WeightLogBase):
    """体重記録レスポンス"""
    id: str
    user_id: str
    logged_at: datetime
    created_at: datetime
    
    class Config:
        from_attributes = True


class WeightHistory(BaseModel):
    """体重履歴"""
    logs: List[WeightLogResponse]
    current_weight: Optional[float] = None
    start_weight: Optional[float] = None
    weight_change: Optional[float] = None
    target_weight: Optional[float] = None
