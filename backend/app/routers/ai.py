from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from typing import Optional
from app.services.gemini_service import gemini_service

router = APIRouter(tags=["AI"])


# MARK: - リクエストモデル

class AdviceRequest(BaseModel):
    """ホームアドバイス用リクエスト"""
    today_calories: int
    goal_calories: int
    today_protein: int = 0
    today_fat: int = 0
    today_carbs: int = 0
    today_meals: str = ""
    meal_count: int = 0
    # 新しいパラメータ（時間帯・各食事タイプ）
    breakfast_count: int = 0
    lunch_count: int = 0
    dinner_count: int = 0
    snack_count: int = 0
    current_hour: Optional[int] = None
    time_of_day: Optional[str] = None
    time_context: Optional[str] = None


class MealCommentRequest(BaseModel):
    """食事コメント用リクエスト"""
    meal_name: str
    calories: int
    protein: float = 0
    fat: float = 0
    carbs: float = 0
    sugar: float = 0
    fiber: float = 0
    sodium: float = 0


class ChatRequest(BaseModel):
    """チャット用リクエスト"""
    message: str
    image_base64: Optional[str] = None
    chat_history: Optional[list] = None
    user_context: Optional[dict] = None
    mode: str = "fast"  # "fast" or "thinking"


class MealAnalysisRequest(BaseModel):
    """食事分析用リクエスト"""
    image_base64: Optional[str] = None
    description: Optional[str] = None


# MARK: - エンドポイント

@router.post("/v1/advice")
async def get_home_advice(request: AdviceRequest):
    """
    ホーム画面用のアドバイスを生成（時間帯・食事状況対応）
    Flash Liteモデルを使用（高速）
    """
    try:
        print(f"📝 Advice Request:")
        print(f"  - Time: {request.time_context} ({request.current_hour}時)")
        print(f"  - Meals: 朝{request.breakfast_count} 昼{request.lunch_count} 夕{request.dinner_count} 間食{request.snack_count}")
        print(f"  - Calories: {request.today_calories}/{request.goal_calories}")
        
        advice = await gemini_service.generate_advice(
            today_calories=request.today_calories,
            goal_calories=request.goal_calories,
            today_protein=request.today_protein,
            today_fat=request.today_fat,
            today_carbs=request.today_carbs,
            today_meals=request.today_meals,
            meal_count=request.meal_count,
            breakfast_count=request.breakfast_count,
            lunch_count=request.lunch_count,
            dinner_count=request.dinner_count,
            snack_count=request.snack_count,
            current_hour=request.current_hour,
            time_of_day=request.time_of_day,
            time_context=request.time_context
        )
        
        print(f"  ✅ Advice: {advice}")
        return {"advice": advice}
        
    except Exception as e:
        print(f"❌ Advice Error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/v1/meal-comment")
async def get_meal_comment(request: MealCommentRequest):
    """
    食事に対するカロちゃんのコメントを生成
    Flash Liteモデルを使用（高速）
    """
    try:
        comment = await gemini_service.generate_meal_comment(
            meal_name=request.meal_name,
            calories=request.calories,
            protein=request.protein,
            fat=request.fat,
            carbs=request.carbs,
            sugar=request.sugar,
            fiber=request.fiber,
            sodium=request.sodium
        )
        
        return {"comment": comment}
        
    except Exception as e:
        print(f"❌ Meal Comment Error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/v1/chat")
async def chat_with_calo(request: ChatRequest):
    """
    カロちゃんとチャット
    - mode="fast": Flash Liteモデル（高速）
    - mode="thinking": Proモデル（高品質）
    """
    try:
        print(f"💬 Chat Request:")
        print(f"  - Mode: {request.mode}")
        print(f"  - Message: {request.message[:50]}...")
        print(f"  - Has Image: {request.image_base64 is not None}")
        print(f"  - History Count: {len(request.chat_history) if request.chat_history else 0}")
        
        response = await gemini_service.chat(
            message=request.message,
            user_context=request.user_context,
            image_base64=request.image_base64,
            chat_history=request.chat_history,
            mode=request.mode
        )
        
        print(f"  ✅ Response: {response[:100]}...")
        return {"response": response}
        
    except Exception as e:
        print(f"❌ Chat Error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/v1/analyze-meal")
async def analyze_meal(request: MealAnalysisRequest):
    """
    食事画像またはテキストからカロリー・栄養素を分析
    Proモデルを使用（高品質）
    """
    try:
        if request.image_base64:
            print("🍽️ Analyzing meal image...")
            result = await gemini_service.analyze_meal_image(request.image_base64)
        elif request.description:
            print(f"🍽️ Analyzing meal text: {request.description}")
            result = await gemini_service.analyze_meal_text(request.description)
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Either image_base64 or description is required"
            )
        
        print(f"  ✅ Analysis complete: {result.total_calories}kcal")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Analysis Error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )