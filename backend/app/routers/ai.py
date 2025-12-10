from fastapi import APIRouter, HTTPException, Depends, status
from app.database import get_supabase_admin
from app.middleware.auth import get_current_user
from app.services.gemini_service import gemini_service
from app.models.chat import (
    MealAnalysisRequest, DetailedMealAnalysis,
    ChatRequest, ChatResponse, ChatMessageCreate, ChatMessageResponse
)
from datetime import datetime, date

router = APIRouter(prefix="/ai", tags=["AI分析"])


@router.post("/analyze-meal", response_model=DetailedMealAnalysis)
async def analyze_meal(
    request: MealAnalysisRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    食事画像またはテキストからカロリー・栄養素を分析
    """
    try:
        if request.image_base64:
            # 画像から分析
            result = await gemini_service.analyze_meal_image(request.image_base64)
        elif request.description:
            # テキストから分析
            result = await gemini_service.analyze_meal_text(request.description)
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Either image_base64 or description is required"
            )
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/chat", response_model=ChatResponse)
async def chat_with_calo(
    request: ChatRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    カロちゃんとチャット
    """
    try:
        supabase = get_supabase_admin()
        chat_date = request.chat_date or date.today()
        
        # ユーザーのコンテキストを取得（今日のカロリーなど）
        today_str = date.today().isoformat()
        
        # 今日の食事
        meals_response = supabase.table("meal_logs").select("calories").eq(
            "user_id", current_user["id"]
        ).gte(
            "logged_at", f"{today_str}T00:00:00"
        ).lt(
            "logged_at", f"{today_str}T23:59:59"
        ).execute()
        
        today_calories = sum(m["calories"] for m in meals_response.data) if meals_response.data else 0
        
        # 今日の運動
        exercises_response = supabase.table("exercise_logs").select("calories_burned").eq(
            "user_id", current_user["id"]
        ).gte(
            "logged_at", f"{today_str}T00:00:00"
        ).lt(
            "logged_at", f"{today_str}T23:59:59"
        ).execute()
        
        today_exercise = sum(e["calories_burned"] for e in exercises_response.data) if exercises_response.data else 0
        
        # 目標カロリー
        profile_response = supabase.table("profiles").select("daily_calorie_goal").eq(
            "id", current_user["id"]
        ).single().execute()
        
        goal_calories = 2000
        if profile_response.data:
            goal_calories = profile_response.data.get("daily_calorie_goal", 2000)
        
        user_context = {
            "today_calories": today_calories,
            "goal_calories": goal_calories,
            "today_exercise": today_exercise
        }
        
        # AIレスポンスを生成
        ai_response = await gemini_service.chat(
            message=request.message,
            user_context=user_context,
            image_base64=request.image_base64
        )
        
        # ユーザーメッセージを保存
        user_msg_data = {
            "user_id": current_user["id"],
            "is_user": True,
            "message": request.message,
            "image_url": None,  # 画像URLは別途実装
            "chat_date": chat_date.isoformat()
        }
        user_msg_response = supabase.table("chat_messages").insert(user_msg_data).execute()
        
        # AIメッセージを保存
        ai_msg_data = {
            "user_id": current_user["id"],
            "is_user": False,
            "message": ai_response,
            "image_url": None,
            "chat_date": chat_date.isoformat()
        }
        ai_msg_response = supabase.table("chat_messages").insert(ai_msg_data).execute()
        
        return ChatResponse(
            response=ai_response,
            user_message=ChatMessageResponse(**user_msg_response.data[0]),
            ai_message=ChatMessageResponse(**ai_msg_response.data[0])
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/chat/history")
async def get_chat_history(
    chat_date: str = None,
    limit: int = 50,
    current_user: dict = Depends(get_current_user)
):
    """
    チャット履歴を取得
    """
    try:
        supabase = get_supabase_admin()
        
        query = supabase.table("chat_messages").select("*").eq("user_id", current_user["id"])
        
        if chat_date:
            query = query.eq("chat_date", chat_date)
        
        query = query.order("created_at", desc=False).limit(limit)
        response = query.execute()
        
        return [ChatMessageResponse(**item) for item in response.data]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )