from fastapi import APIRouter, HTTPException, Depends, status
from app.database import get_supabase_admin
from app.middleware.auth import get_current_user
from app.services.gemini_service import gemini_service
from app.models.chat import (
    MealAnalysisRequest, DetailedMealAnalysis,
    ChatRequest, ChatResponse, ChatMessageCreate, ChatMessageResponse
)
from pydantic import BaseModel
from datetime import datetime, date

router = APIRouter(prefix="/ai", tags=["AI分析"])


# テスト用リクエスト/レスポンス
class TestChatRequest(BaseModel):
    message: str
    image_base64: str | None = None
    chat_history: list | None = None  # 会話履歴
    today_meals: str | None = None    # 今日食べたもの


class TestChatResponse(BaseModel):
    response: str


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


# ============================================
# テスト用エンドポイント（認証不要）
# ============================================

@router.post("/chat/test", response_model=TestChatResponse)
async def chat_test(request: TestChatRequest):
    """
    テスト用チャット（認証不要・履歴保存なし）
    開発/デバッグ用途のみ
    """
    try:
        # テスト用のユーザーコンテキスト
        user_context = {
            "today_calories": 1200,
            "goal_calories": 2000,
            "today_exercise": 150,
            "today_meals": request.today_meals or ""
        }
        
        # AIレスポンスを生成（会話履歴を渡す）
        ai_response = await gemini_service.chat(
            message=request.message,
            user_context=user_context,
            image_base64=request.image_base64,
            chat_history=request.chat_history
        )
        
        return TestChatResponse(response=ai_response)
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/analyze-meal/test", response_model=DetailedMealAnalysis)
async def analyze_meal_test(request: MealAnalysisRequest):
    """
    テスト用食事分析（認証不要）
    開発/デバッグ用途のみ
    """
    try:
        if request.image_base64:
            result = await gemini_service.analyze_meal_image(request.image_base64)
        elif request.description:
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


# ============================================
# ホームアドバイス用エンドポイント（認証不要）
# ============================================

class HomeAdviceRequest(BaseModel):
    today_calories: int = 0
    goal_calories: int = 2000
    today_protein: int = 0
    today_fat: int = 0
    today_carbs: int = 0
    today_meals: str | None = None
    meal_count: int = 0


class HomeAdviceResponse(BaseModel):
    advice: str


@router.post("/advice/test", response_model=HomeAdviceResponse)
async def get_home_advice(request: HomeAdviceRequest):
    """
    ホーム画面用のアドバイスを取得（認証不要）
    """
    try:
        advice = await gemini_service.generate_advice(
            today_calories=request.today_calories,
            goal_calories=request.goal_calories,
            today_protein=request.today_protein,
            today_fat=request.today_fat,
            today_carbs=request.today_carbs,
            today_meals=request.today_meals or "",
            meal_count=request.meal_count
        )
        
        return HomeAdviceResponse(advice=advice)
        
    except Exception as e:
        # エラー時はデフォルトメッセージ
        return HomeAdviceResponse(advice="今日も一緒にがんばろうにゃ！🐱")


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