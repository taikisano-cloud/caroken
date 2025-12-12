import google.generativeai as genai
from app.config import get_settings
from app.models.chat import MealAnalysisResponse, DetailedMealAnalysis, FoodItem
from typing import Optional
from datetime import datetime
import base64
import json
import re
import logging

settings = get_settings()
logger = logging.getLogger(__name__)

# Gemini設定
genai.configure(api_key=settings.gemini_api_key)

# モデル設定
model = genai.GenerativeModel('gemini-2.5-pro')  # メイン（チャット、分析）
model_flash_lite = genai.GenerativeModel('gemini-flash-lite-latest')  # 軽量（ホームアドバイス）


def get_current_time_info() -> dict:
    """現在の時間情報を取得（日本時間）"""
    import pytz
    
    # 日本時間を取得
    jst = pytz.timezone('Asia/Tokyo')
    now = datetime.now(jst)
    hour = now.hour
    
    if hour < 10:
        time_of_day = "morning"
        time_context = "朝"
    elif hour < 14:
        time_of_day = "noon"
        time_context = "昼"
    elif hour < 18:
        time_of_day = "afternoon"
        time_context = "夕方"
    else:
        time_of_day = "evening"
        time_context = "夜"
    
    return {
        "hour": hour,
        "minute": now.minute,
        "time_of_day": time_of_day,
        "time_context": time_context,
        "formatted": now.strftime("%H:%M")
    }


class GeminiService:
    """Gemini AIサービス"""
    
    @staticmethod
    async def analyze_meal_image(image_base64: str) -> DetailedMealAnalysis:
        """食事画像を分析してカロリー・栄養素を推定"""
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
            image_data = base64.b64decode(image_base64)
            response = model.generate_content([
                prompt,
                {"mime_type": "image/jpeg", "data": image_data}
            ])
            
            result_text = response.text
            json_match = re.search(r'\{[\s\S]*\}', result_text)
            
            if json_match:
                result = json.loads(json_match.group())
                food_items = [FoodItem(**item) for item in result.get("food_items", [])]
                
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
            logger.error(f"Image analysis error: {e}")
            return DetailedMealAnalysis(
                food_items=[FoodItem(name="分析できませんでした", amount="不明", calories=0, protein=0, fat=0, carbs=0)],
                total_calories=0, total_protein=0, total_fat=0, total_carbs=0,
                total_sugar=0, total_fiber=0, total_sodium=0,
                character_comment="ごめんにゃ、分析できなかったにゃ...😿"
            )
    
    @staticmethod
    async def analyze_meal_text(description: str) -> DetailedMealAnalysis:
        """テキストから食事のカロリー・栄養素を推定"""
        prompt = f"""
あなたは栄養士AIです。以下の食事内容を分析してカロリーと栄養素を推定してください。

食事内容: {description}

以下のJSON形式で回答してください（JSONのみ、説明なし）：
{{
    "food_items": [
        {{"name": "食品名", "amount": "量", "calories": 数値, "protein": 数値, "fat": 数値, "carbs": 数値}}
    ],
    "total_calories": 数値,
    "total_protein": 数値,
    "total_fat": 数値,
    "total_carbs": 数値,
    "total_sugar": 数値,
    "total_fiber": 数値,
    "total_sodium": 数値,
    "character_comment": "カロちゃんからの一言（語尾に「にゃ」）"
}}
"""
        
        try:
            response = model.generate_content(prompt)
            result_text = response.text
            json_match = re.search(r'\{[\s\S]*\}', result_text)
            
            if json_match:
                result = json.loads(json_match.group())
                food_items = [FoodItem(**item) for item in result.get("food_items", [])]
                
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
            logger.error(f"Text analysis error: {e}")
            return DetailedMealAnalysis(
                food_items=[FoodItem(name=description[:20] if description else "不明", amount="1食分", calories=300, protein=15, fat=10, carbs=40)],
                total_calories=300, total_protein=15, total_fat=10, total_carbs=40,
                total_sugar=5, total_fiber=3, total_sodium=500,
                character_comment="分析が難しかったから概算だにゃ！🐱"
            )
    
    @staticmethod
    async def chat(
        message: str,
        user_context: Optional[dict] = None,
        image_base64: Optional[str] = None,
        chat_history: Optional[list] = None,
        mode: str = "fast"
    ) -> str:
        """カロちゃんとのチャット（時間帯対応）"""
        
        # 現在時刻を取得
        time_info = get_current_time_info()
        
        context = f"\n【現在時刻】{time_info['formatted']}（{time_info['time_context']}）\n"
        
        if user_context:
            context += "\n【ユーザー情報】\n"
            
            if user_context.get('name'):
                context += f"- 名前: {user_context.get('name')}\n"
            if user_context.get('gender'):
                context += f"- 性別: {user_context.get('gender')}\n"
            if user_context.get('age'):
                context += f"- 年齢: {user_context.get('age')}歳\n"
            if user_context.get('height'):
                context += f"- 身長: {user_context.get('height')}cm\n"
            if user_context.get('current_weight'):
                context += f"- 体重: {user_context.get('current_weight')}kg\n"
            if user_context.get('target_weight'):
                context += f"- 目標体重: {user_context.get('target_weight')}kg\n"
            if user_context.get('goal'):
                context += f"- 目標: {user_context.get('goal')}\n"
            
            context += "\n【今日の状況】\n"
            if user_context.get('today_calories') is not None:
                goal = user_context.get('calorie_goal', user_context.get('goal_calories', 2000))
                context += f"- カロリー: {user_context.get('today_calories')}/{goal}kcal\n"
            if user_context.get('today_protein') is not None:
                context += f"- たんぱく質: {user_context.get('today_protein')}g\n"
            if user_context.get('today_meals'):
                context += f"- 今日食べたもの: {user_context.get('today_meals')}\n"
        
        # 会話履歴
        history_text = ""
        if chat_history and len(chat_history) > 0:
            history_text = "\n【これまでの会話】\n"
            for msg in chat_history[-6:]:
                role = "ユーザー" if msg.get('is_user') else "カロちゃん"
                history_text += f"{role}: {msg.get('message', '')}\n"
        
        system_prompt = f"""あなたは「カロちゃん」という猫のAIアシスタント。カロ研アプリのマスコット。

【性格】明るく元気、語尾に「にゃ」「だにゃ」、絵文字を適度に使う（🐱😊🔥💪🍽️など）

【重要】現在時刻は{time_info['formatted']}（{time_info['time_context']}）。時間に関する質問には正確に答える。

【レシピ提案時】DELISH KITCHENのURL: https://www.google.com/search?q=site:delishkitchen.tv+料理名
【運動提案時】YouTubeのURL: https://www.youtube.com/results?search_query=運動名

{context}
{history_text}

ユーザー: {message}

カロちゃんとして自然に返答（2-4文）:"""
        
        try:
            use_pro = image_base64 is not None or mode == "thinking"
            selected_model = model if use_pro else model_flash_lite
            
            if image_base64:
                image_data = base64.b64decode(image_base64)
                response = selected_model.generate_content([
                    system_prompt,
                    {"mime_type": "image/jpeg", "data": image_data}
                ])
            else:
                response = selected_model.generate_content(system_prompt)
            
            return response.text.strip()
            
        except Exception as e:
            logger.error(f"Chat error: {e}")
            return "ごめんにゃ、ちょっと調子が悪いみたい...😿 もう一度話しかけてほしいにゃ！"
    
    @staticmethod
    async def generate_advice(
        today_calories: int,
        goal_calories: int,
        today_protein: int = 0,
        today_fat: int = 0,
        today_carbs: int = 0,
        today_meals: str = "",
        meal_count: int = 0,
        breakfast_count: int = 0,
        lunch_count: int = 0,
        dinner_count: int = 0,
        snack_count: int = 0,
        current_hour: int = None,
        time_of_day: str = None,
        time_context: str = None
    ) -> str:
        """ホーム画面用のアドバイスを生成（多様なコンテキスト対応）"""
        
        # 時間帯を取得
        if current_hour is None:
            time_info = get_current_time_info()
            current_hour = time_info["hour"]
            time_of_day = time_info["time_of_day"]
            time_context = time_info["time_context"]
        
        remaining = goal_calories - today_calories
        progress_percent = int((today_calories / goal_calories) * 100) if goal_calories > 0 else 0
        
        # プロンプトを改善：食事催促ではなく、状況に応じた多様なアドバイス
        prompt = f"""カロちゃん（猫AI）として、ホーム画面に表示する1文アドバイスを生成。

【現在】{time_context}（{current_hour}時）

【今日の記録】
- カロリー: {today_calories}/{goal_calories}kcal（{progress_percent}%達成、残り{remaining}kcal）
- たんぱく質: {today_protein}g
- 食べたもの: {today_meals if today_meals else "まだ記録なし"}
- 記録回数: 朝{breakfast_count} 昼{lunch_count} 夕{dinner_count} 間食{snack_count}

【アドバイスの方向性】以下から状況に合うものを1つ選んで:
1. 食べたものへのコメント（記録がある場合）「〇〇食べたんだにゃ！」「〇〇美味しそうだにゃ」
2. 栄養バランスのヒント「たんぱく質いい感じだにゃ」
3. カロリー進捗への励まし「順調だにゃ！」「ちょっと控えめにするにゃ」
4. 水分補給のリマインド「お水も忘れずにゃ💧」
5. 軽い運動の提案（カロリーオーバー時）「少し歩くといいかもにゃ」
6. 時間帯に合った挨拶（朝なら「おはよう」夜なら「お疲れ様」）
7. ポジティブな応援メッセージ

【重要ルール】
- 「〇〇食べた？」「〇〇まだ？」「記録して」等の催促はNG
- 語尾「にゃ」、絵文字1-2個
- 1文で短く（30文字以内推奨）
- 明るくポジティブに

1文のみ出力:"""
        
        try:
            response = model_flash_lite.generate_content(prompt)
            result = response.text.strip()
            # 改行があれば最初の行だけ取る
            if '\n' in result:
                result = result.split('\n')[0]
            return result
        except Exception as e:
            logger.error(f"Advice generation error: {e}")
            # フォールバック（状況に応じた定型文）
            return GeminiService._get_fallback_advice(
                time_of_day, today_meals, progress_percent, remaining < 0
            )
    
    @staticmethod
    def _get_fallback_advice(
        time_of_day: str,
        today_meals: str,
        progress_percent: int,
        is_over_budget: bool
    ) -> str:
        """API失敗時のフォールバックアドバイス"""
        
        # 食事記録がある場合はそれに言及
        if today_meals:
            meals_list = today_meals.split(',') if ',' in today_meals else [today_meals]
            first_meal = meals_list[0].strip()[:10]  # 最初の食事、10文字まで
            return f"{first_meal}、美味しそうだにゃ🐱"
        
        # カロリー進捗に応じたメッセージ
        if is_over_budget:
            return "ちょっと歩いてみるにゃ？🚶"
        elif progress_percent >= 80:
            return "今日もいい感じだにゃ✨"
        elif progress_percent >= 50:
            return "順調に進んでるにゃ💪"
        
        # 時間帯に応じたメッセージ
        if time_of_day == "morning":
            return "今日も一緒にがんばろうにゃ🌅"
        elif time_of_day == "noon":
            return "午後もファイトだにゃ💪"
        elif time_of_day == "afternoon":
            return "お水飲んでるかにゃ？💧"
        else:
            return "今日もお疲れ様だにゃ🌙"
    
    @staticmethod
    async def generate_meal_comment(
        meal_name: str,
        calories: int,
        protein: float = 0,
        fat: float = 0,
        carbs: float = 0,
        sugar: float = 0,
        fiber: float = 0,
        sodium: float = 0
    ) -> str:
        """食事に対するカロちゃんのコメントを生成"""
        prompt = f"""カロちゃん（猫AI）として食事コメント1文。
料理: {meal_name}（{calories}kcal）
ルール: 語尾「にゃ」、絵文字1-2個、ポジティブに"""
        
        try:
            response = model_flash_lite.generate_content(prompt)
            return response.text.strip()
        except Exception as e:
            logger.error(f"Meal comment error: {e}")
            return "美味しそうだにゃ！🐱"


gemini_service = GeminiService()