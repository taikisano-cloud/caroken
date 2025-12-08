from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum


class ExerciseType(str, Enum):
    running = "running"
    strength = "strength"
    manual = "manual"
    other = "other"


class ExerciseLogBase(BaseModel):
    """運動記録の基本モデル"""
    name: str
    exercise_type: ExerciseType = ExerciseType.other
    duration_minutes: int = 0
    calories_burned: int = 0
    distance_km: Optional[float] = None
    steps: Optional[int] = None


class ExerciseLogCreate(ExerciseLogBase):
    """運動記録作成用"""
    logged_at: Optional[datetime] = None


class ExerciseLogUpdate(BaseModel):
    """運動記録更新用"""
    name: Optional[str] = None
    exercise_type: Optional[ExerciseType] = None
    duration_minutes: Optional[int] = None
    calories_burned: Optional[int] = None
    distance_km: Optional[float] = None
    steps: Optional[int] = None
    logged_at: Optional[datetime] = None


class ExerciseLogResponse(ExerciseLogBase):
    """運動記録レスポンス"""
    id: str
    user_id: str
    logged_at: datetime
    created_at: datetime
    
    class Config:
        from_attributes = True


class SavedExerciseBase(BaseModel):
    """保存済み運動の基本モデル"""
    name: str
    exercise_type: Optional[str] = None
    duration_minutes: int = 0
    calories_burned: int = 0


class SavedExerciseCreate(SavedExerciseBase):
    """保存済み運動作成用"""
    pass


class SavedExerciseResponse(SavedExerciseBase):
    """保存済み運動レスポンス"""
    id: str
    user_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class DailyExerciseSummary(BaseModel):
    """日別運動サマリー"""
    date: str
    total_calories_burned: int
    total_duration_minutes: int
    exercise_count: int
    exercises: List[ExerciseLogResponse]
