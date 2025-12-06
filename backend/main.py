from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from pydantic import BaseModel
from typing import Optional
from datetime import date
import os
from supabase import create_client, Client

# 環境変数を読み込み
load_dotenv()

# Supabaseクライアント初期化
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)

# FastAPIアプリ作成
app = FastAPI(title="Caloken API")

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== モデル定義 ====================

class SignUpRequest(BaseModel):
    email: str
    password: str

class SignInRequest(BaseModel):
    email: str
    password: str

class MealCreate(BaseModel):
    date: date
    meal_type: str  # breakfast, lunch, dinner, snack
    calories: int
    photo_url: Optional[str] = None
    memo: Optional[str] = None

class ActivityCreate(BaseModel):
    date: date
    activity_type: str
    calories_burned: int
    duration_minutes: Optional[int] = None
    steps: Optional[int] = None

class WeightCreate(BaseModel):
    date: date
    weight_kg: float

# ==================== 認証ヘルパー ====================

async def get_current_user(authorization: str = Header(...)):
    """トークンからユーザーIDを取得"""
    try:
        token = authorization.replace("Bearer ", "")
        user = supabase.auth.get_user(token)
        return user.user.id
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")

# ==================== 基本エンドポイント ====================

@app.get("/")
def read_root():
    return {"message": "Caloken API is running!"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# ==================== 認証API ====================

@app.post("/auth/signup")
def sign_up(request: SignUpRequest):
    try:
        response = supabase.auth.sign_up({
            "email": request.email,
            "password": request.password
        })
        return {
            "message": "User created successfully",
            "user": response.user.email if response.user else None
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/auth/signin")
def sign_in(request: SignInRequest):
    try:
        response = supabase.auth.sign_in_with_password({
            "email": request.email,
            "password": request.password
        })
        return {
            "access_token": response.session.access_token,
            "refresh_token": response.session.refresh_token,
            "user": response.user.email
        }
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid credentials")

# ==================== 食事記録API ====================

@app.post("/meals")
async def create_meal(meal: MealCreate, user_id: str = Depends(get_current_user)):
    """食事記録を追加"""
    try:
        response = supabase.table("meals").insert({
            "user_id": user_id,
            "date": str(meal.date),
            "meal_type": meal.meal_type,
            "calories": meal.calories,
            "photo_url": meal.photo_url,
            "memo": meal.memo
        }).execute()
        return {"message": "Meal recorded", "data": response.data}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/meals")
async def get_meals(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    user_id: str = Depends(get_current_user)
):
    """食事記録を取得"""
    try:
        query = supabase.table("meals").select("*").eq("user_id", user_id)
        
        if start_date:
            query = query.gte("date", str(start_date))
        if end_date:
            query = query.lte("date", str(end_date))
        
        response = query.order("date", desc=True).execute()
        return {"data": response.data}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# ==================== 活動記録API ====================

@app.post("/activities")
async def create_activity(activity: ActivityCreate, user_id: str = Depends(get_current_user)):
    """活動記録を追加"""
    try:
        response = supabase.table("activities").insert({
            "user_id": user_id,
            "date": str(activity.date),
            "activity_type": activity.activity_type,
            "calories_burned": activity.calories_burned,
            "duration_minutes": activity.duration_minutes,
            "steps": activity.steps
        }).execute()
        return {"message": "Activity recorded", "data": response.data}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/activities")
async def get_activities(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    user_id: str = Depends(get_current_user)
):
    """活動記録を取得"""
    try:
        query = supabase.table("activities").select("*").eq("user_id", user_id)
        
        if start_date:
            query = query.gte("date", str(start_date))
        if end_date:
            query = query.lte("date", str(end_date))
        
        response = query.order("date", desc=True).execute()
        return {"data": response.data}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# ==================== 体重記録API ====================

@app.post("/weight")
async def create_weight(weight: WeightCreate, user_id: str = Depends(get_current_user)):
    """体重を記録"""
    try:
        response = supabase.table("weight_logs").insert({
            "user_id": user_id,
            "date": str(weight.date),
            "weight_kg": weight.weight_kg
        }).execute()
        return {"message": "Weight recorded", "data": response.data}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/weight")
async def get_weight(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    user_id: str = Depends(get_current_user)
):
    """体重履歴を取得"""
    try:
        query = supabase.table("weight_logs").select("*").eq("user_id", user_id)
        
        if start_date:
            query = query.gte("date", str(start_date))
        if end_date:
            query = query.lte("date", str(end_date))
        
        response = query.order("date", desc=True).execute()
        return {"data": response.data}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# ==================== サマリーAPI ====================

@app.get("/summary/daily")
async def get_daily_summary(
    target_date: date,
    user_id: str = Depends(get_current_user)
):
    """日別サマリーを取得"""
    try:
        # 食事データ取得
        meals = supabase.table("meals")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("date", str(target_date))\
            .execute()
        
        # 活動データ取得
        activities = supabase.table("activities")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("date", str(target_date))\
            .execute()
        
        # 体重データ取得
        weight = supabase.table("weight_logs")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("date", str(target_date))\
            .execute()
        
        # カロリー計算
        total_calories_in = sum(meal["calories"] or 0 for meal in meals.data)
        total_calories_burned = sum(act["calories_burned"] or 0 for act in activities.data)
        total_steps = sum(act["steps"] or 0 for act in activities.data)
        
        return {
            "date": str(target_date),
            "calories_in": total_calories_in,
            "calories_burned": total_calories_burned,
            "net_calories": total_calories_in - total_calories_burned,
            "total_steps": total_steps,
            "weight_kg": weight.data[0]["weight_kg"] if weight.data else None,
            "meals": meals.data,
            "activities": activities.data
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# ==================== ニュースAPI ====================

@app.get("/news")
def get_news():
    """ニュース一覧を取得"""
    response = supabase.table("news").select("*").order("published_at", desc=True).execute()
    return {"data": response.data}