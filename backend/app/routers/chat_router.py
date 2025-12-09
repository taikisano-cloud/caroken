from fastapi import APIRouter, HTTPException
from app.models.chat import (
    ChatRequest, ChatResponse,
    AdviceRequest, AdviceResponse,
    MealCommentRequest, MealCommentResponse,
    MealAnalysisRequest, MealAnalysisResponse
)
from app.services.gemini_service import gemini_service

router = APIRouter(prefix="/api/v1", tags=["chat"])


# ============================================================
# チャットエンドポイント（2モデル対応）
# ============================================================

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    カロちゃんとチャット
    
    - mode: "fast"（高速モード - Flash）or "thinking"（思考モード - Pro）
    """
    try:
        response = await gemini_service.chat(
            message=request.message,
            user_context=request.user_context,
            image_base64=request.image_base64,
            chat_history=request.chat_history,
            mode=request.mode
        )
        
        return ChatResponse(
            response=response,
            mode=request.mode
        )
    except Exception as e:
        print(f"Chat error: {e}")
        raise HTTPException(status_code=500, detail="チャットエラーが発生しました")


# ============================================================
# ホーム画面アドバイスエンドポイント（Flash使用）
# ============================================================

@router.post("/advice", response_model=AdviceResponse)
async def generate_advice(request: AdviceRequest):
    """
    ホーム画面用のアドバイスを生成（Flashモデル使用）
    """
    try:
        advice = await gemini_service.generate_advice(
            today_calories=request.today_calories,
            goal_calories=request.goal_calories,
            today_protein=request.today_protein,
            today_fat=request.today_fat,
            today_carbs=request.today_carbs,
            today_meals=request.today_meals,
            meal_count=request.meal_count
        )
        
        return AdviceResponse(advice=advice)
    except Exception as e:
        print(f"Advice error: {e}")
        raise HTTPException(status_code=500, detail="アドバイス生成エラーが発生しました")


# ============================================================
# 食事詳細コメントエンドポイント（Flash使用）
# ============================================================

@router.post("/meal-comment", response_model=MealCommentResponse)
async def generate_meal_comment(request: MealCommentRequest):
    """
    食事詳細画面用のカロちゃんコメントを生成（Flashモデル使用）
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
        
        return MealCommentResponse(comment=comment)
    except Exception as e:
        print(f"Meal comment error: {e}")
        raise HTTPException(status_code=500, detail="コメント生成エラーが発生しました")


# ============================================================
# 食事分析エンドポイント（Pro使用）
# ============================================================

@router.post("/analyze-meal", response_model=MealAnalysisResponse)
async def analyze_meal(request: MealAnalysisRequest):
    """
    食事を分析してカロリー・栄養素を推定（Proモデル使用）
    
    - image_base64: 画像のBase64エンコード文字列
    - description: テキストでの食事説明（画像がない場合）
    """
    try:
        if request.image_base64:
            analysis = await gemini_service.analyze_meal_image(request.image_base64)
        elif request.description:
            analysis = await gemini_service.analyze_meal_text(request.description)
        else:
            raise HTTPException(status_code=400, detail="画像またはテキストが必要です")
        
        return MealAnalysisResponse(analysis=analysis)
    except HTTPException:
        raise
    except Exception as e:
        print(f"Meal analysis error: {e}")
        raise HTTPException(status_code=500, detail="食事分析エラーが発生しました")
