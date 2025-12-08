from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date, datetime
from enum import Enum


class Gender(str, Enum):
    male = "male"
    female = "female"
    other = "other"


class ActivityLevel(str, Enum):
    sedentary = "sedentary"
    light = "light"
    moderate = "moderate"
    active = "active"
    very_active = "very_active"


class Goal(str, Enum):
    lose = "lose"
    maintain = "maintain"
    gain = "gain"


class ProfileBase(BaseModel):
    """プロフィールの基本モデル"""
    display_name: Optional[str] = None
    gender: Optional[Gender] = None
    birth_date: Optional[date] = None
    height_cm: Optional[float] = None
    target_weight_kg: Optional[float] = None
    activity_level: Optional[ActivityLevel] = None
    goal: Optional[Goal] = None
    daily_calorie_goal: Optional[int] = 2000
    daily_protein_goal: Optional[int] = 60
    daily_fat_goal: Optional[int] = 65
    daily_carbs_goal: Optional[int] = 300


class ProfileCreate(ProfileBase):
    """プロフィール作成用"""
    pass


class ProfileUpdate(ProfileBase):
    """プロフィール更新用"""
    pass


class ProfileResponse(ProfileBase):
    """プロフィールレスポンス"""
    id: str
    email: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class UserAuth(BaseModel):
    """認証用"""
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """トークンレスポンス"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user_id: str
