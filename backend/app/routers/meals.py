from fastapi import APIRouter, HTTPException, Depends, Query, status
from app.database import get_supabase_admin
from app.middleware.auth import get_current_user
from app.models.meal import (
    MealLogCreate, MealLogUpdate, MealLogResponse,
    SavedMealCreate, SavedMealResponse, DailyMealSummary
)
from datetime import datetime, date
from typing import List, Optional

router = APIRouter(prefix="/meals", tags=["食事記録"])


@router.post("", response_model=MealLogResponse)
async def create_meal_log(
    meal: MealLogCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    食事を記録
    """
    try:
        supabase = get_supabase_admin()
        
        data = meal.model_dump()
        data["user_id"] = current_user["id"]
        
        if data.get("logged_at"):
            data["logged_at"] = data["logged_at"].isoformat()
        else:
            data["logged_at"] = datetime.now().isoformat()
        
        response = supabase.table("meal_logs").insert(data).execute()
        
        return MealLogResponse(**response.data[0])
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("", response_model=List[MealLogResponse])
async def get_meal_logs(
    date: Optional[str] = Query(None, description="日付（YYYY-MM-DD）"),
    start_date: Optional[str] = Query(None, description="開始日"),
    end_date: Optional[str] = Query(None, description="終了日"),
    limit: int = Query(50, le=100),
    current_user: dict = Depends(get_current_user)
):
    """
    食事記録を取得
    """
    try:
        supabase = get_supabase_admin()
        
        query = supabase.table("meal_logs").select("*").eq("user_id", current_user["id"])
        
        if date:
            # 特定の日付のみ
            query = query.gte("logged_at", f"{date}T00:00:00").lt("logged_at", f"{date}T23:59:59")
        elif start_date and end_date:
            query = query.gte("logged_at", f"{start_date}T00:00:00").lte("logged_at", f"{end_date}T23:59:59")
        
        query = query.order("logged_at", desc=True).limit(limit)
        response = query.execute()
        
        return [MealLogResponse(**item) for item in response.data]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/daily/{date}", response_model=DailyMealSummary)
async def get_daily_meal_summary(
    date: str,
    current_user: dict = Depends(get_current_user)
):
    """
    日別食事サマリーを取得
    """
    try:
        supabase = get_supabase_admin()
        
        response = supabase.table("meal_logs").select("*").eq(
            "user_id", current_user["id"]
        ).gte(
            "logged_at", f"{date}T00:00:00"
        ).lt(
            "logged_at", f"{date}T23:59:59"
        ).order("logged_at").execute()
        
        meals = [MealLogResponse(**item) for item in response.data]
        
        total_calories = sum(m.calories for m in meals)
        total_protein = sum(m.protein for m in meals)
        total_fat = sum(m.fat for m in meals)
        total_carbs = sum(m.carbs for m in meals)
        
        return DailyMealSummary(
            date=date,
            total_calories=total_calories,
            total_protein=total_protein,
            total_fat=total_fat,
            total_carbs=total_carbs,
            meal_count=len(meals),
            meals=meals
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/{meal_id}", response_model=MealLogResponse)
async def get_meal_log(
    meal_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    特定の食事記録を取得
    """
    try:
        supabase = get_supabase_admin()
        
        response = supabase.table("meal_logs").select("*").eq(
            "id", meal_id
        ).eq(
            "user_id", current_user["id"]
        ).single().execute()
        
        if response.data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meal log not found"
            )
        
        return MealLogResponse(**response.data)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.put("/{meal_id}", response_model=MealLogResponse)
async def update_meal_log(
    meal_id: str,
    meal: MealLogUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    食事記録を更新
    """
    try:
        supabase = get_supabase_admin()
        
        update_data = {k: v for k, v in meal.model_dump().items() if v is not None}
        
        if "logged_at" in update_data and update_data["logged_at"]:
            update_data["logged_at"] = update_data["logged_at"].isoformat()
        
        response = supabase.table("meal_logs").update(update_data).eq(
            "id", meal_id
        ).eq(
            "user_id", current_user["id"]
        ).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meal log not found"
            )
        
        return MealLogResponse(**response.data[0])
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/{meal_id}")
async def delete_meal_log(
    meal_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    食事記録を削除
    """
    try:
        supabase = get_supabase_admin()
        
        response = supabase.table("meal_logs").delete().eq(
            "id", meal_id
        ).eq(
            "user_id", current_user["id"]
        ).execute()
        
        return {"message": "Meal log deleted successfully"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# ========================================
# 保存済み食事
# ========================================

@router.post("/saved", response_model=SavedMealResponse)
async def create_saved_meal(
    meal: SavedMealCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    食事を保存（お気に入り）
    """
    try:
        supabase = get_supabase_admin()
        
        data = meal.model_dump()
        data["user_id"] = current_user["id"]
        
        response = supabase.table("saved_meals").insert(data).execute()
        
        return SavedMealResponse(**response.data[0])
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/saved", response_model=List[SavedMealResponse])
async def get_saved_meals(
    current_user: dict = Depends(get_current_user)
):
    """
    保存済み食事一覧を取得
    """
    try:
        supabase = get_supabase_admin()
        
        response = supabase.table("saved_meals").select("*").eq(
            "user_id", current_user["id"]
        ).order("created_at", desc=True).execute()
        
        return [SavedMealResponse(**item) for item in response.data]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/saved/{meal_id}")
async def delete_saved_meal(
    meal_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    保存済み食事を削除
    """
    try:
        supabase = get_supabase_admin()
        
        supabase.table("saved_meals").delete().eq(
            "id", meal_id
        ).eq(
            "user_id", current_user["id"]
        ).execute()
        
        return {"message": "Saved meal deleted successfully"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
