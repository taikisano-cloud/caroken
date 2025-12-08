from fastapi import APIRouter, HTTPException, Depends, Query, status
from app.database import get_supabase_admin
from app.middleware.auth import get_current_user
from app.models.exercise import (
    ExerciseLogCreate, ExerciseLogUpdate, ExerciseLogResponse,
    SavedExerciseCreate, SavedExerciseResponse, DailyExerciseSummary
)
from datetime import datetime
from typing import List, Optional

router = APIRouter(prefix="/exercises", tags=["運動記録"])


@router.post("", response_model=ExerciseLogResponse)
async def create_exercise_log(
    exercise: ExerciseLogCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    運動を記録
    """
    try:
        supabase = get_supabase_admin()
        
        data = exercise.model_dump()
        data["user_id"] = current_user["id"]
        data["exercise_type"] = data["exercise_type"].value if data.get("exercise_type") else "other"
        
        if data.get("logged_at"):
            data["logged_at"] = data["logged_at"].isoformat()
        else:
            data["logged_at"] = datetime.now().isoformat()
        
        response = supabase.table("exercise_logs").insert(data).execute()
        
        return ExerciseLogResponse(**response.data[0])
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("", response_model=List[ExerciseLogResponse])
async def get_exercise_logs(
    date: Optional[str] = Query(None, description="日付（YYYY-MM-DD）"),
    start_date: Optional[str] = Query(None, description="開始日"),
    end_date: Optional[str] = Query(None, description="終了日"),
    limit: int = Query(50, le=100),
    current_user: dict = Depends(get_current_user)
):
    """
    運動記録を取得
    """
    try:
        supabase = get_supabase_admin()
        
        query = supabase.table("exercise_logs").select("*").eq("user_id", current_user["id"])
        
        if date:
            query = query.gte("logged_at", f"{date}T00:00:00").lt("logged_at", f"{date}T23:59:59")
        elif start_date and end_date:
            query = query.gte("logged_at", f"{start_date}T00:00:00").lte("logged_at", f"{end_date}T23:59:59")
        
        query = query.order("logged_at", desc=True).limit(limit)
        response = query.execute()
        
        return [ExerciseLogResponse(**item) for item in response.data]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/daily/{date}", response_model=DailyExerciseSummary)
async def get_daily_exercise_summary(
    date: str,
    current_user: dict = Depends(get_current_user)
):
    """
    日別運動サマリーを取得
    """
    try:
        supabase = get_supabase_admin()
        
        response = supabase.table("exercise_logs").select("*").eq(
            "user_id", current_user["id"]
        ).gte(
            "logged_at", f"{date}T00:00:00"
        ).lt(
            "logged_at", f"{date}T23:59:59"
        ).order("logged_at").execute()
        
        exercises = [ExerciseLogResponse(**item) for item in response.data]
        
        total_calories = sum(e.calories_burned for e in exercises)
        total_duration = sum(e.duration_minutes for e in exercises)
        
        return DailyExerciseSummary(
            date=date,
            total_calories_burned=total_calories,
            total_duration_minutes=total_duration,
            exercise_count=len(exercises),
            exercises=exercises
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/{exercise_id}", response_model=ExerciseLogResponse)
async def get_exercise_log(
    exercise_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    特定の運動記録を取得
    """
    try:
        supabase = get_supabase_admin()
        
        response = supabase.table("exercise_logs").select("*").eq(
            "id", exercise_id
        ).eq(
            "user_id", current_user["id"]
        ).single().execute()
        
        if response.data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exercise log not found"
            )
        
        return ExerciseLogResponse(**response.data)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.put("/{exercise_id}", response_model=ExerciseLogResponse)
async def update_exercise_log(
    exercise_id: str,
    exercise: ExerciseLogUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    運動記録を更新
    """
    try:
        supabase = get_supabase_admin()
        
        update_data = {k: v for k, v in exercise.model_dump().items() if v is not None}
        
        if "exercise_type" in update_data:
            update_data["exercise_type"] = update_data["exercise_type"].value
        if "logged_at" in update_data:
            update_data["logged_at"] = update_data["logged_at"].isoformat()
        
        response = supabase.table("exercise_logs").update(update_data).eq(
            "id", exercise_id
        ).eq(
            "user_id", current_user["id"]
        ).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exercise log not found"
            )
        
        return ExerciseLogResponse(**response.data[0])
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/{exercise_id}")
async def delete_exercise_log(
    exercise_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    運動記録を削除
    """
    try:
        supabase = get_supabase_admin()
        
        supabase.table("exercise_logs").delete().eq(
            "id", exercise_id
        ).eq(
            "user_id", current_user["id"]
        ).execute()
        
        return {"message": "Exercise log deleted successfully"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


# ========================================
# 保存済み運動
# ========================================

@router.post("/saved", response_model=SavedExerciseResponse)
async def create_saved_exercise(
    exercise: SavedExerciseCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    運動を保存（お気に入り）
    """
    try:
        supabase = get_supabase_admin()
        
        data = exercise.model_dump()
        data["user_id"] = current_user["id"]
        
        response = supabase.table("saved_exercises").insert(data).execute()
        
        return SavedExerciseResponse(**response.data[0])
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/saved", response_model=List[SavedExerciseResponse])
async def get_saved_exercises(
    current_user: dict = Depends(get_current_user)
):
    """
    保存済み運動一覧を取得
    """
    try:
        supabase = get_supabase_admin()
        
        response = supabase.table("saved_exercises").select("*").eq(
            "user_id", current_user["id"]
        ).order("created_at", desc=True).execute()
        
        return [SavedExerciseResponse(**item) for item in response.data]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/saved/{exercise_id}")
async def delete_saved_exercise(
    exercise_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    保存済み運動を削除
    """
    try:
        supabase = get_supabase_admin()
        
        supabase.table("saved_exercises").delete().eq(
            "id", exercise_id
        ).eq(
            "user_id", current_user["id"]
        ).execute()
        
        return {"message": "Saved exercise deleted successfully"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
