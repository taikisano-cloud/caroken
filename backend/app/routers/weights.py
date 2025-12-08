from fastapi import APIRouter, HTTPException, Depends, Query, status
from app.database import get_supabase_admin
from app.middleware.auth import get_current_user
from app.models.weight import (
    WeightLogCreate, WeightLogUpdate, WeightLogResponse, WeightHistory
)
from datetime import datetime
from typing import List, Optional

router = APIRouter(prefix="/weights", tags=["体重記録"])


@router.post("", response_model=WeightLogResponse)
async def create_weight_log(
    weight: WeightLogCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    体重を記録
    """
    try:
        supabase = get_supabase_admin()
        
        data = weight.model_dump()
        data["user_id"] = current_user["id"]
        
        if data.get("logged_at"):
            data["logged_at"] = data["logged_at"].isoformat()
        else:
            data["logged_at"] = datetime.now().isoformat()
        
        response = supabase.table("weight_logs").insert(data).execute()
        
        return WeightLogResponse(**response.data[0])
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("", response_model=List[WeightLogResponse])
async def get_weight_logs(
    start_date: Optional[str] = Query(None, description="開始日"),
    end_date: Optional[str] = Query(None, description="終了日"),
    limit: int = Query(30, le=100),
    current_user: dict = Depends(get_current_user)
):
    """
    体重記録を取得
    """
    try:
        supabase = get_supabase_admin()
        
        query = supabase.table("weight_logs").select("*").eq("user_id", current_user["id"])
        
        if start_date and end_date:
            query = query.gte("logged_at", f"{start_date}T00:00:00").lte("logged_at", f"{end_date}T23:59:59")
        
        query = query.order("logged_at", desc=True).limit(limit)
        response = query.execute()
        
        return [WeightLogResponse(**item) for item in response.data]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/history", response_model=WeightHistory)
async def get_weight_history(
    days: int = Query(30, le=365, description="取得する日数"),
    current_user: dict = Depends(get_current_user)
):
    """
    体重履歴を取得（集計付き）
    """
    try:
        supabase = get_supabase_admin()
        
        # 体重記録を取得
        response = supabase.table("weight_logs").select("*").eq(
            "user_id", current_user["id"]
        ).order("logged_at", desc=True).limit(days).execute()
        
        logs = [WeightLogResponse(**item) for item in response.data]
        
        # 目標体重を取得
        profile_response = supabase.table("profiles").select("target_weight_kg").eq(
            "id", current_user["id"]
        ).single().execute()
        
        target_weight = None
        if profile_response.data:
            target_weight = profile_response.data.get("target_weight_kg")
        
        current_weight = logs[0].weight_kg if logs else None
        start_weight = logs[-1].weight_kg if logs else None
        weight_change = None
        
        if current_weight and start_weight:
            weight_change = round(current_weight - start_weight, 2)
        
        return WeightHistory(
            logs=logs,
            current_weight=current_weight,
            start_weight=start_weight,
            weight_change=weight_change,
            target_weight=target_weight
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/latest", response_model=Optional[WeightLogResponse])
async def get_latest_weight(
    current_user: dict = Depends(get_current_user)
):
    """
    最新の体重記録を取得
    """
    try:
        supabase = get_supabase_admin()
        
        response = supabase.table("weight_logs").select("*").eq(
            "user_id", current_user["id"]
        ).order("logged_at", desc=True).limit(1).execute()
        
        if not response.data:
            return None
        
        return WeightLogResponse(**response.data[0])
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.put("/{weight_id}", response_model=WeightLogResponse)
async def update_weight_log(
    weight_id: str,
    weight: WeightLogUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    体重記録を更新
    """
    try:
        supabase = get_supabase_admin()
        
        update_data = {k: v for k, v in weight.model_dump().items() if v is not None}
        
        if "logged_at" in update_data:
            update_data["logged_at"] = update_data["logged_at"].isoformat()
        
        response = supabase.table("weight_logs").update(update_data).eq(
            "id", weight_id
        ).eq(
            "user_id", current_user["id"]
        ).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Weight log not found"
            )
        
        return WeightLogResponse(**response.data[0])
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/{weight_id}")
async def delete_weight_log(
    weight_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    体重記録を削除
    """
    try:
        supabase = get_supabase_admin()
        
        supabase.table("weight_logs").delete().eq(
            "id", weight_id
        ).eq(
            "user_id", current_user["id"]
        ).execute()
        
        return {"message": "Weight log deleted successfully"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
