from fastapi import APIRouter, HTTPException, Depends, Query, status
from app.database import get_supabase_admin
from app.middleware.auth import get_current_user
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, date, timedelta

router = APIRouter(prefix="/stats", tags=["統計"])


class DailySummary(BaseModel):
    """日次サマリー"""
    date: str
    calories_consumed: int
    calories_burned: int
    net_calories: int
    protein: float
    fat: float
    carbs: float
    meal_count: int
    exercise_count: int
    weight: Optional[float] = None


class WeeklySummary(BaseModel):
    """週次サマリー"""
    start_date: str
    end_date: str
    avg_calories_consumed: float
    avg_calories_burned: float
    total_calories_consumed: int
    total_calories_burned: int
    avg_protein: float
    avg_fat: float
    avg_carbs: float
    weight_change: Optional[float] = None
    daily_data: List[DailySummary]


class GoalProgress(BaseModel):
    """目標達成度"""
    calorie_goal: int
    calories_consumed: int
    calories_remaining: int
    calories_burned: int
    net_calories: int
    protein_goal: int
    protein_consumed: float
    fat_goal: int
    fat_consumed: float
    carbs_goal: int
    carbs_consumed: float
    calorie_progress_percent: float
    protein_progress_percent: float
    fat_progress_percent: float
    carbs_progress_percent: float


@router.get("/daily/{date}", response_model=DailySummary)
async def get_daily_summary(
    date: str,
    current_user: dict = Depends(get_current_user)
):
    """
    日次サマリーを取得
    """
    try:
        supabase = get_supabase_admin()
        
        # 食事データ
        meals_response = supabase.table("meal_logs").select("*").eq(
            "user_id", current_user["id"]
        ).gte(
            "logged_at", f"{date}T00:00:00"
        ).lt(
            "logged_at", f"{date}T23:59:59"
        ).execute()
        
        meals = meals_response.data or []
        calories_consumed = sum(m["calories"] for m in meals)
        protein = sum(float(m["protein"]) for m in meals)
        fat = sum(float(m["fat"]) for m in meals)
        carbs = sum(float(m["carbs"]) for m in meals)
        
        # 運動データ
        exercises_response = supabase.table("exercise_logs").select("*").eq(
            "user_id", current_user["id"]
        ).gte(
            "logged_at", f"{date}T00:00:00"
        ).lt(
            "logged_at", f"{date}T23:59:59"
        ).execute()
        
        exercises = exercises_response.data or []
        calories_burned = sum(e["calories_burned"] for e in exercises)
        
        # 体重データ
        weight_response = supabase.table("weight_logs").select("weight_kg").eq(
            "user_id", current_user["id"]
        ).gte(
            "logged_at", f"{date}T00:00:00"
        ).lt(
            "logged_at", f"{date}T23:59:59"
        ).order("logged_at", desc=True).limit(1).execute()
        
        weight = None
        if weight_response.data:
            weight = float(weight_response.data[0]["weight_kg"])
        
        return DailySummary(
            date=date,
            calories_consumed=calories_consumed,
            calories_burned=calories_burned,
            net_calories=calories_consumed - calories_burned,
            protein=round(protein, 1),
            fat=round(fat, 1),
            carbs=round(carbs, 1),
            meal_count=len(meals),
            exercise_count=len(exercises),
            weight=weight
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/weekly", response_model=WeeklySummary)
async def get_weekly_summary(
    start_date: Optional[str] = Query(None, description="開始日（省略時は今週）"),
    current_user: dict = Depends(get_current_user)
):
    """
    週次サマリーを取得
    """
    try:
        if start_date:
            start = datetime.strptime(start_date, "%Y-%m-%d").date()
        else:
            today = date.today()
            start = today - timedelta(days=today.weekday())  # 今週の月曜日
        
        end = start + timedelta(days=6)
        
        # 日別データを取得
        daily_data = []
        total_calories_consumed = 0
        total_calories_burned = 0
        total_protein = 0
        total_fat = 0
        total_carbs = 0
        
        for i in range(7):
            current_date = start + timedelta(days=i)
            date_str = current_date.isoformat()
            
            # 各日のサマリーを取得（内部呼び出し）
            supabase = get_supabase_admin()
            
            # 食事
            meals_response = supabase.table("meal_logs").select("*").eq(
                "user_id", current_user["id"]
            ).gte(
                "logged_at", f"{date_str}T00:00:00"
            ).lt(
                "logged_at", f"{date_str}T23:59:59"
            ).execute()
            
            meals = meals_response.data or []
            day_calories = sum(m["calories"] for m in meals)
            day_protein = sum(float(m["protein"]) for m in meals)
            day_fat = sum(float(m["fat"]) for m in meals)
            day_carbs = sum(float(m["carbs"]) for m in meals)
            
            # 運動
            exercises_response = supabase.table("exercise_logs").select("*").eq(
                "user_id", current_user["id"]
            ).gte(
                "logged_at", f"{date_str}T00:00:00"
            ).lt(
                "logged_at", f"{date_str}T23:59:59"
            ).execute()
            
            exercises = exercises_response.data or []
            day_burned = sum(e["calories_burned"] for e in exercises)
            
            # 体重
            weight_response = supabase.table("weight_logs").select("weight_kg").eq(
                "user_id", current_user["id"]
            ).gte(
                "logged_at", f"{date_str}T00:00:00"
            ).lt(
                "logged_at", f"{date_str}T23:59:59"
            ).order("logged_at", desc=True).limit(1).execute()
            
            weight = None
            if weight_response.data:
                weight = float(weight_response.data[0]["weight_kg"])
            
            daily_data.append(DailySummary(
                date=date_str,
                calories_consumed=day_calories,
                calories_burned=day_burned,
                net_calories=day_calories - day_burned,
                protein=round(day_protein, 1),
                fat=round(day_fat, 1),
                carbs=round(day_carbs, 1),
                meal_count=len(meals),
                exercise_count=len(exercises),
                weight=weight
            ))
            
            total_calories_consumed += day_calories
            total_calories_burned += day_burned
            total_protein += day_protein
            total_fat += day_fat
            total_carbs += day_carbs
        
        # 体重変化を計算
        weights_with_data = [d for d in daily_data if d.weight is not None]
        weight_change = None
        if len(weights_with_data) >= 2:
            weight_change = round(weights_with_data[-1].weight - weights_with_data[0].weight, 2)
        
        return WeeklySummary(
            start_date=start.isoformat(),
            end_date=end.isoformat(),
            avg_calories_consumed=round(total_calories_consumed / 7, 1),
            avg_calories_burned=round(total_calories_burned / 7, 1),
            total_calories_consumed=total_calories_consumed,
            total_calories_burned=total_calories_burned,
            avg_protein=round(total_protein / 7, 1),
            avg_fat=round(total_fat / 7, 1),
            avg_carbs=round(total_carbs / 7, 1),
            weight_change=weight_change,
            daily_data=daily_data
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/today/progress", response_model=GoalProgress)
async def get_today_progress(
    current_user: dict = Depends(get_current_user)
):
    """
    今日の目標達成度を取得
    """
    try:
        supabase = get_supabase_admin()
        today_str = date.today().isoformat()
        
        # プロフィール（目標値）
        profile_response = supabase.table("profiles").select(
            "daily_calorie_goal, daily_protein_goal, daily_fat_goal, daily_carbs_goal"
        ).eq("id", current_user["id"]).single().execute()
        
        goals = profile_response.data or {}
        calorie_goal = goals.get("daily_calorie_goal", 2000)
        protein_goal = goals.get("daily_protein_goal", 60)
        fat_goal = goals.get("daily_fat_goal", 65)
        carbs_goal = goals.get("daily_carbs_goal", 300)
        
        # 今日の食事
        meals_response = supabase.table("meal_logs").select("*").eq(
            "user_id", current_user["id"]
        ).gte(
            "logged_at", f"{today_str}T00:00:00"
        ).lt(
            "logged_at", f"{today_str}T23:59:59"
        ).execute()
        
        meals = meals_response.data or []
        calories_consumed = sum(m["calories"] for m in meals)
        protein_consumed = sum(float(m["protein"]) for m in meals)
        fat_consumed = sum(float(m["fat"]) for m in meals)
        carbs_consumed = sum(float(m["carbs"]) for m in meals)
        
        # 今日の運動
        exercises_response = supabase.table("exercise_logs").select("calories_burned").eq(
            "user_id", current_user["id"]
        ).gte(
            "logged_at", f"{today_str}T00:00:00"
        ).lt(
            "logged_at", f"{today_str}T23:59:59"
        ).execute()
        
        exercises = exercises_response.data or []
        calories_burned = sum(e["calories_burned"] for e in exercises)
        
        # 進捗率を計算
        def calc_progress(consumed, goal):
            if goal == 0:
                return 0
            return min(round((consumed / goal) * 100, 1), 100)
        
        return GoalProgress(
            calorie_goal=calorie_goal,
            calories_consumed=calories_consumed,
            calories_remaining=max(0, calorie_goal - calories_consumed),
            calories_burned=calories_burned,
            net_calories=calories_consumed - calories_burned,
            protein_goal=protein_goal,
            protein_consumed=round(protein_consumed, 1),
            fat_goal=fat_goal,
            fat_consumed=round(fat_consumed, 1),
            carbs_goal=carbs_goal,
            carbs_consumed=round(carbs_consumed, 1),
            calorie_progress_percent=calc_progress(calories_consumed, calorie_goal),
            protein_progress_percent=calc_progress(protein_consumed, protein_goal),
            fat_progress_percent=calc_progress(fat_consumed, fat_goal),
            carbs_progress_percent=calc_progress(carbs_consumed, carbs_goal)
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
