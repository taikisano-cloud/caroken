from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Literal
from app.services.gemini_service import gemini_service

router = APIRouter(prefix="/api/v1", tags=["chat"])


# ============================================================
# リクエスト/レスポンスモデル
# ============================================================

ChatMode = Literal["fast", "thinking"]


class ChatRequest(BaseModel):
    """チャットリクエスト"""
    message: str
    image_base64: Optional[str] = None
    chat_history: Optional[List[dict]] = None
    user_context: Optional[dict] = None
    mode: ChatMode = "fast"


class ChatResponse(BaseModel):
    """チャットレスポンス"""
    response: str
    mode: ChatMode


class AdviceRequest(BaseModel):
    """ホーム画面アドバイスリクエスト"""
    today_calories: int
    goal_calories: int
    today_protein: int = 0
    today_fat: int = 0
    today_carbs: int = 0
    today_meals: str = ""
    meal_count: int = 0


class AdviceResponse(BaseModel):
    """アドバイスレスポンス"""
    advice: str


class FoodItem(BaseModel):
    """食品アイテム"""
    name: str
    amount: str
    calories: int
    protein: float
    fat: float
    carbs: float
    sugar: float = 0
    fiber: float = 0
    sodium: float = 0


class DetailedMealAnalysis(BaseModel):
    """詳細な食事分析結果"""
    food_items: List[FoodItem]
    total_calories: int
    total_protein: float
    total_fat: float
    total_carbs: float
    total_sugar: float = 0
    total_fiber: float = 0
    total_sodium: float = 0
    character_comment: str


class MealAnalysisRequest(BaseModel):
    """食事分析リクエスト"""
    image_base64: Optional[str] = None
    description: Optional[str] = None


# ✅ 食事コメント生成用リクエスト
class MealCommentRequest(BaseModel):
    """食事コメントリクエスト"""
    meal_name: str
    calories: int
    protein: float = 0
    fat: float = 0
    carbs: float = 0
    sugar: float = 0
    fiber: float = 0
    sodium: float = 0


class MealCommentResponse(BaseModel):
    """食事コメントレスポンス"""
    comment: str


class ChatMessageCreate(BaseModel):
    """チャットメッセージ作成用"""
    message: str
    is_user: bool
    image_url: Optional[str] = None
    chat_date: Optional[str] = None


class ChatMessageResponse(BaseModel):
    """チャットメッセージレスポンス"""
    id: str
    user_id: str
    is_user: bool
    message: str
    image_url: Optional[str] = None
    chat_date: str
    created_at: str


class ChatResponseWithMessages(BaseModel):
    """チャットレスポンス（メッセージ付き）- ai.py用"""
    response: str
    user_message: ChatMessageResponse
    ai_message: ChatMessageResponse


# ============================================================
# チャットエンドポイント
# ============================================================

@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    カロちゃんとチャット
    
    - mode: "fast"（高速モード - Flash Lite）or "thinking"（思考モード - Pro）
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
        import traceback
        print(f"Chat error: {e}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"チャットエラー: {str(e)}")


# ============================================================
# ホーム画面アドバイスエンドポイント
# ============================================================

@router.post("/advice", response_model=AdviceResponse)
async def generate_advice(request: AdviceRequest):
    """
    ホーム画面用のアドバイスを生成（Flash Liteモデル使用 - 高速）
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
        import traceback
        print(f"Advice error: {e}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"アドバイス生成エラー: {str(e)}")


# ============================================================
# 食事分析エンドポイント
# ============================================================

@router.post("/analyze-meal", response_model=DetailedMealAnalysis)
async def analyze_meal(request: MealAnalysisRequest):
    """
    食事を分析してカロリー・栄養素を推定（Proモデル使用）
    """
    try:
        if request.image_base64:
            analysis = await gemini_service.analyze_meal_image(request.image_base64)
        elif request.description:
            analysis = await gemini_service.analyze_meal_text(request.description)
        else:
            raise HTTPException(status_code=400, detail="画像またはテキストが必要です")
        
        # ✅ gemini_serviceの結果を直接DetailedMealAnalysisに変換
        return DetailedMealAnalysis(
            food_items=[
                FoodItem(
                    name=item.name,
                    amount=item.amount,
                    calories=item.calories,
                    protein=item.protein,
                    fat=item.fat,
                    carbs=item.carbs,
                    sugar=getattr(item, 'sugar', 0),
                    fiber=getattr(item, 'fiber', 0),
                    sodium=getattr(item, 'sodium', 0)
                ) for item in analysis.food_items
            ],
            total_calories=analysis.total_calories,
            total_protein=analysis.total_protein,
            total_fat=analysis.total_fat,
            total_carbs=analysis.total_carbs,
            total_sugar=analysis.total_sugar,
            total_fiber=analysis.total_fiber,
            total_sodium=analysis.total_sodium,
            character_comment=analysis.character_comment
        )
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(f"Meal analysis error: {e}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"食事分析エラー: {str(e)}")


# ============================================================
# 食事コメント生成エンドポイント（新規追加）
# ============================================================

@router.post("/meal-comment", response_model=MealCommentResponse)
async def generate_meal_comment(request: MealCommentRequest):
    """
    食事に対するカロちゃんのコメントを生成（Flash Liteモデル使用 - 高速）
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
        import traceback
        print(f"Meal comment error: {e}")
        print(traceback.format_exc())
        # エラー時はデフォルトコメントを返す
        return MealCommentResponse(comment="美味しそうだにゃ！🐱")