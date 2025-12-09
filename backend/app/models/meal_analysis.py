from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import google.generativeai as genai
import os
import json
import base64
import re

router = APIRouter(prefix="/meal", tags=["meal"])

# Gemini設定
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# MARK: - リクエスト/レスポンスモデル
class MealAnalysisRequest(BaseModel):
    description: Optional[str] = None  # テキスト入力
    image_base64: Optional[str] = None  # 画像（Base64）

class FoodItem(BaseModel):
    name: str
    amount: str
    calories: int
    protein: float  # Doubleに対応
    fat: float
    carbs: float

class MealAnalysisResponse(BaseModel):
    food_items: List[FoodItem]
    total_calories: int
    total_protein: float  # Doubleに対応
    total_fat: float
    total_carbs: float
    total_sugar: float = 0
    total_fiber: float = 0
    total_sodium: float = 0
    character_comment: str

# MARK: - 食事分析エンドポイント
@router.post("/analyze", response_model=MealAnalysisResponse)
async def analyze_meal(request: MealAnalysisRequest):
    """
    テキストまたは画像から食事を分析し、栄養素を計算する
    """
    if not request.description and not request.image_base64:
        raise HTTPException(status_code=400, detail="description または image_base64 が必要です")
    
    try:
        if request.image_base64:
            # 画像分析
            result = await analyze_meal_image(request.image_base64)
        else:
            # テキスト分析
            result = await analyze_meal_text(request.description)
        
        return result
    except Exception as e:
        print(f"❌ Meal analysis error: {e}")
        # フォールバック結果を返す
        return create_fallback_response(request.description or "食事")

# MARK: - テキストから食事分析
async def analyze_meal_text(description: str) -> MealAnalysisResponse:
    """テキスト入力から食事を分析"""
    
    model = genai.GenerativeModel("gemini-2.5-pro")
    
    prompt = f"""あなたは栄養士AIです。以下の食事内容から栄養素を分析してください。

食事内容: {description}

以下のJSON形式で回答してください。必ずJSONのみを返してください：
{{
    "food_items": [
        {{
            "name": "食品名",
            "amount": "量（例: 1杯、100g）",
            "calories": 数値,
            "protein": 数値,
            "fat": 数値,
            "carbs": 数値
        }}
    ],
    "total_calories": 合計カロリー,
    "total_protein": 合計たんぱく質(g),
    "total_fat": 合計脂質(g),
    "total_carbs": 合計炭水化物(g),
    "total_sugar": 合計糖分(g),
    "total_fiber": 合計食物繊維(g),
    "total_sodium": 合計ナトリウム(mg),
    "character_comment": "猫キャラクターとしてのコメント（〜にゃ、で終わる短いコメント）"
}}

注意事項：
- 日本の一般的な食品データベースを参考に正確な栄養素を推定してください
- カロリーと栄養素は現実的な値にしてください
- コメントは可愛らしく、励ましの言葉を入れてください
- JSONのみを返し、説明文は不要です"""

    response = model.generate_content(prompt)
    return parse_analysis_response(response.text, description)

# MARK: - 画像から食事分析
async def analyze_meal_image(image_base64: str) -> MealAnalysisResponse:
    """画像から食事を分析"""
    
    model = genai.GenerativeModel("gemini-2.5-pro")
    
    # Base64をデコード
    try:
        image_data = base64.b64decode(image_base64)
    except Exception as e:
        print(f"❌ Base64 decode error: {e}")
        raise HTTPException(status_code=400, detail="画像のデコードに失敗しました")
    
    prompt = """あなたは栄養士AIです。この食事画像から食品を識別し、栄養素を分析してください。

以下のJSON形式で回答してください。必ずJSONのみを返してください：
{
    "food_items": [
        {
            "name": "食品名",
            "amount": "量（例: 1杯、100g）",
            "calories": 数値,
            "protein": 数値,
            "fat": 数値,
            "carbs": 数値
        }
    ],
    "total_calories": 合計カロリー,
    "total_protein": 合計たんぱく質(g),
    "total_fat": 合計脂質(g),
    "total_carbs": 合計炭水化物(g),
    "total_sugar": 合計糖分(g),
    "total_fiber": 合計食物繊維(g),
    "total_sodium": 合計ナトリウム(mg),
    "character_comment": "猫キャラクターとしてのコメント（〜にゃ、で終わる短いコメント）"
}

注意事項：
- 画像に写っている全ての食品を識別してください
- 量は見た目から推定してください
- 日本の一般的な食品データベースを参考に正確な栄養素を推定してください
- コメントは可愛らしく、食事の内容に合わせてください
- JSONのみを返し、説明文は不要です"""

    response = model.generate_content([
        prompt,
        {
            "mime_type": "image/jpeg",
            "data": image_base64
        }
    ])
    
    return parse_analysis_response(response.text, "食事")

# MARK: - レスポンスパース
def parse_analysis_response(response_text: str, fallback_name: str) -> MealAnalysisResponse:
    """Geminiのレスポンスをパースする"""
    try:
        # JSONを抽出（マークダウンコードブロック対応）
        json_match = re.search(r'```json\s*(.*?)\s*```', response_text, re.DOTALL)
        if json_match:
            json_str = json_match.group(1)
        else:
            # コードブロックがない場合はそのまま
            json_str = response_text.strip()
        
        data = json.loads(json_str)
        
        food_items = [
            FoodItem(
                name=item.get("name", "不明"),
                amount=item.get("amount", "1食分"),
                calories=int(item.get("calories", 0)),
                protein=float(item.get("protein", 0)),
                fat=float(item.get("fat", 0)),
                carbs=float(item.get("carbs", 0))
            )
            for item in data.get("food_items", [])
        ]
        
        return MealAnalysisResponse(
            food_items=food_items,
            total_calories=int(data.get("total_calories", 0)),
            total_protein=float(data.get("total_protein", 0)),
            total_fat=float(data.get("total_fat", 0)),
            total_carbs=float(data.get("total_carbs", 0)),
            total_sugar=float(data.get("total_sugar", 0)),
            total_fiber=float(data.get("total_fiber", 0)),
            total_sodium=float(data.get("total_sodium", 0)),
            character_comment=data.get("character_comment", "美味しそうだにゃ！🐱")
        )
    except json.JSONDecodeError as e:
        print(f"❌ JSON parse error: {e}")
        print(f"Response text: {response_text}")
        return create_fallback_response(fallback_name)

# MARK: - フォールバックレスポンス
def create_fallback_response(name: str) -> MealAnalysisResponse:
    """分析失敗時のフォールバック"""
    return MealAnalysisResponse(
        food_items=[
            FoodItem(
                name=name[:20] if len(name) > 20 else name,
                amount="1食分",
                calories=400,
                protein=20.0,
                fat=15.0,
                carbs=45.0
            )
        ],
        total_calories=400,
        total_protein=20.0,
        total_fat=15.0,
        total_carbs=45.0,
        total_sugar=5.0,
        total_fiber=3.0,
        total_sodium=500.0,
        character_comment="分析が難しかったにゃ...参考値だから調整してにゃ🐱"
    )


# MARK: - テスト用エンドポイント
@router.get("/test")
async def test_meal_endpoint():
    """エンドポイント動作確認"""
    return {
        "status": "ok",
        "message": "Meal analysis endpoint is working",
        "endpoints": {
            "POST /meal/analyze": "Analyze meal from text or image"
        }
    }
