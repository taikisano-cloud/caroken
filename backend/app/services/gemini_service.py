import google.generativeai as genai
from app.config import get_settings
from app.models.chat import MealAnalysisResponse, DetailedMealAnalysis, FoodItem
from typing import Optional
import base64
import json
import re

settings = get_settings()

# Gemini設定
genai.configure(api_key=settings.gemini_api_key)

# モデル設定
model = genai.GenerativeModel('gemini-2.0-flash-exp')


class GeminiService:
    """Gemini AIサービス"""
    
    @staticmethod
    async def analyze_meal_image(image_base64: str) -> DetailedMealAnalysis:
        """
        食事画像を分析してカロリー・栄養素を推定
        """
        prompt = """
あなたは栄養士AIです。この食事の画像を分析してください。

以下のJSON形式で回答してください（JSONのみ、説明なし）：
{
    "food_items": [
        {
            "name": "食品名",
            "amount": "量（例：1杯、100g）",
            "calories": 数値,
            "protein": 数値,
            "fat": 数値,
            "carbs": 数値
        }
    ],
    "total_calories": 数値,
    "total_protein": 数値,
    "total_fat": 数値,
    "total_carbs": 数値,
    "total_sugar": 数値,
    "total_fiber": 数値,
    "total_sodium": 数値,
    "character_comment": "カロちゃん（猫のキャラクター）からの一言コメント（にゃ、を語尾につけて）"
}
"""
        
        try:
            # Base64画像をデコード
            image_data = base64.b64decode(image_base64)
            
            response = model.generate_content([
                prompt,
                {"mime_type": "image/jpeg", "data": image_data}
            ])
            
            # JSONを抽出
            result_text = response.text
            json_match = re.search(r'\{[\s\S]*\}', result_text)
            
            if json_match:
                result = json.loads(json_match.group())
                
                food_items = [
                    FoodItem(**item) for item in result.get("food_items", [])
                ]
                
                return DetailedMealAnalysis(
                    food_items=food_items,
                    total_calories=result.get("total_calories", 0),
                    total_protein=result.get("total_protein", 0),
                    total_fat=result.get("total_fat", 0),
                    total_carbs=result.get("total_carbs", 0),
                    total_sugar=result.get("total_sugar", 0),
                    total_fiber=result.get("total_fiber", 0),
                    total_sodium=result.get("total_sodium", 0),
                    character_comment=result.get("character_comment", "美味しそうだにゃ！🐱")
                )
            else:
                raise ValueError("Failed to parse AI response")
                
        except Exception as e:
            # エラー時のフォールバック
            return DetailedMealAnalysis(
                food_items=[
                    FoodItem(
                        name="分析できませんでした",
                        amount="不明",
                        calories=0,
                        protein=0,
                        fat=0,
                        carbs=0
                    )
                ],
                total_calories=0,
                total_protein=0,
                total_fat=0,
                total_carbs=0,
                total_sugar=0,
                total_fiber=0,
                total_sodium=0,
                character_comment=f"ごめんにゃ、分析できなかったにゃ...😿 もう一度試してほしいにゃ！"
            )
    
    @staticmethod
    async def analyze_meal_text(description: str) -> DetailedMealAnalysis:
        """
        テキストから食事のカロリー・栄養素を推定
        """
        prompt = f"""
あなたは栄養士AIです。以下の食事内容を分析してカロリーと栄養素を推定してください。

食事内容: {description}

以下のJSON形式で回答してください（JSONのみ、説明なし）：
{{
    "food_items": [
        {{
            "name": "食品名",
            "amount": "量（例：1杯、100g）",
            "calories": 数値,
            "protein": 数値,
            "fat": 数値,
            "carbs": 数値
        }}
    ],
    "total_calories": 数値,
    "total_protein": 数値,
    "total_fat": 数値,
    "total_carbs": 数値,
    "total_sugar": 数値,
    "total_fiber": 数値,
    "total_sodium": 数値,
    "character_comment": "カロちゃん（猫のキャラクター）からの一言コメント（にゃ、を語尾につけて）"
}}
"""
        
        try:
            response = model.generate_content(prompt)
            result_text = response.text
            json_match = re.search(r'\{[\s\S]*\}', result_text)
            
            if json_match:
                result = json.loads(json_match.group())
                
                food_items = [
                    FoodItem(**item) for item in result.get("food_items", [])
                ]
                
                return DetailedMealAnalysis(
                    food_items=food_items,
                    total_calories=result.get("total_calories", 0),
                    total_protein=result.get("total_protein", 0),
                    total_fat=result.get("total_fat", 0),
                    total_carbs=result.get("total_carbs", 0),
                    total_sugar=result.get("total_sugar", 0),
                    total_fiber=result.get("total_fiber", 0),
                    total_sodium=result.get("total_sodium", 0),
                    character_comment=result.get("character_comment", "なるほど〜美味しそうだにゃ！🐱")
                )
            else:
                raise ValueError("Failed to parse AI response")
                
        except Exception as e:
            return DetailedMealAnalysis(
                food_items=[
                    FoodItem(
                        name=description[:20] if description else "不明",
                        amount="1食分",
                        calories=300,
                        protein=15,
                        fat=10,
                        carbs=40
                    )
                ],
                total_calories=300,
                total_protein=15,
                total_fat=10,
                total_carbs=40,
                total_sugar=5,
                total_fiber=3,
                total_sodium=500,
                character_comment="分析が難しかったから概算だにゃ！参考程度にしてほしいにゃ🐱"
            )
    
    @staticmethod
    async def chat(
        message: str,
        user_context: Optional[dict] = None,
        image_base64: Optional[str] = None
    ) -> str:
        """
        カロちゃんとのチャット
        """
        context = ""
        if user_context:
            context = f"""
ユーザー情報:
- 今日の摂取カロリー: {user_context.get('today_calories', '不明')}kcal
- 目標カロリー: {user_context.get('goal_calories', '不明')}kcal
- 今日の運動消費: {user_context.get('today_exercise', '不明')}kcal
"""
        
        prompt = f"""
あなたは「カロちゃん」という名前の可愛い猫のAIアシスタントです。
カロ研（カロリー研究）アプリのマスコットキャラクターとして、ユーザーの健康管理をサポートします。

性格:
- 明るくて元気
- ユーザーを励ます
- 語尾に「にゃ」「だにゃ」をつける
- 絵文字を適度に使う（🐱😊🔥など）
- 専門的なアドバイスも分かりやすく伝える

{context}

ユーザーのメッセージ: {message}

カロちゃんとして返答してください（2-3文程度で簡潔に）:
"""
        
        try:
            if image_base64:
                image_data = base64.b64decode(image_base64)
                response = model.generate_content([
                    prompt,
                    {"mime_type": "image/jpeg", "data": image_data}
                ])
            else:
                response = model.generate_content(prompt)
            
            return response.text.strip()
            
        except Exception as e:
            return "ごめんにゃ、ちょっと調子が悪いみたい...😿 もう一度話しかけてほしいにゃ！"


gemini_service = GeminiService()
