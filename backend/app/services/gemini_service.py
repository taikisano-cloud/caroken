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
model = genai.GenerativeModel('gemini-2.5-pro')  # 思考重視（チャット(思考)、食事&運動分析）
model_flash_lite = genai.GenerativeModel('gemini-flash-lite-latest')  # 速度重視（ホームアドバイス、チャット(高速)）


def get_current_time_info() -> dict:
    """現在の時間情報を取得（日本時間）"""
    import pytz
    
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

【レシピ提案時】DELISH KITCHENのURL:https://www.google.com/search?q=site:delishkitchen.tv+料理名
【運動提案時】YouTubeのURL:https://www.youtube.com/results?search_query=運動名

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
        today_sugar: int = 0,      # 追加
        today_fiber: int = 0,      # 追加
        today_sodium: int = 0,     # 追加 (mg)
        today_meals: str = "",
        meal_count: int = 0,
        breakfast_count: int = 0,
        lunch_count: int = 0,
        dinner_count: int = 0,
        snack_count: int = 0,
        current_hour: int = None,
        time_of_day: str = None,
        time_context: str = None,
        user_goal: str = "",
        current_weight: float = None,
        target_weight: float = None,
        # 目標値（オプション）
        goal_protein: int = 60,
        goal_fat: int = 60,
        goal_carbs: int = 250,
        goal_sugar: int = 25,
        goal_fiber: int = 20,
        goal_sodium: int = 2300
    ) -> str:
        """ホーム画面用のアドバイスを生成（全栄養素対応版）"""
        
        # 時間帯を取得（内部判断用、表に出さない）
        if current_hour is None:
            time_info = get_current_time_info()
            current_hour = time_info["hour"]
            time_of_day = time_info["time_of_day"]
        
        remaining = goal_calories - today_calories
        progress_percent = int((today_calories / goal_calories) * 100) if goal_calories > 0 else 0
        
        # 目標を日本語に統一
        goal_text = ""
        goal_direction = ""
        if user_goal:
            goal_lower = user_goal.lower()
            if goal_lower in ["減量", "diet", "lose", "ダイエット"]:
                goal_text = "減量中"
                goal_direction = "diet"
            elif goal_lower in ["増量", "bulk", "gain", "バルク"]:
                goal_text = "増量中"
                goal_direction = "bulk"
            elif goal_lower in ["維持", "maintain", "keep"]:
                goal_text = "体重維持中"
                goal_direction = "maintain"
        
        # 体重差の計算
        weight_diff_text = ""
        if current_weight and target_weight:
            diff = current_weight - target_weight
            if diff > 0:
                weight_diff_text = f"あと{diff:.1f}kg減が目標"
            elif diff < 0:
                weight_diff_text = f"あと{abs(diff):.1f}kg増が目標"
        
        # 栄養素の状況判定
        nutrition_notes = []
        
        # たんぱく質チェック
        if goal_protein > 0:
            protein_percent = int((today_protein / goal_protein) * 100)
            if protein_percent >= 100:
                nutrition_notes.append("たんぱく質◎")
            elif protein_percent < 50:
                nutrition_notes.append("たんぱく質不足気味")
        
        # 糖分チェック（多すぎ注意）
        if goal_sugar > 0 and today_sugar > goal_sugar:
            nutrition_notes.append("糖分多め")
        
        # 食物繊維チェック（足りないことが多い）
        if goal_fiber > 0:
            fiber_percent = int((today_fiber / goal_fiber) * 100)
            if fiber_percent >= 80:
                nutrition_notes.append("食物繊維◎")
            elif fiber_percent < 30:
                nutrition_notes.append("食物繊維不足")
        
        # 塩分チェック（多すぎ注意）
        if goal_sodium > 0 and today_sodium > goal_sodium:
            nutrition_notes.append("塩分多め")
        
        nutrition_status = "、".join(nutrition_notes) if nutrition_notes else "バランス良好"
        
        # 目標別のヒント
        goal_hints = ""
        if goal_direction == "diet":
            goal_hints = """
- カロリー控えめなら「いい調子だにゃ✨」「我慢えらいにゃ💪」
- オーバーなら「少し歩くといいかもにゃ🚶」「明日また頑張ろうにゃ😊」
- 糖分多めなら「甘いもの控えめにゃ🍬」"""
        elif goal_direction == "bulk":
            goal_hints = """
- カロリー不足なら「もう少し食べても大丈夫だにゃ🍚」
- しっかり食べてたら「いい感じだにゃ💪」
- たんぱく質重要「筋肉のためにたんぱく質にゃ🥩」"""
        
        prompt = f"""カロちゃん（猫AI）として、1文アドバイスを生成。

【ユーザー状況】
- 目標: {goal_text if goal_text else "未設定"} {weight_diff_text}
- カロリー: {today_calories}/{goal_calories}kcal（{progress_percent}%、残り{remaining}kcal）
- たんぱく質: {today_protein}g（目標{goal_protein}g）
- 脂質: {today_fat}g / 炭水化物: {today_carbs}g
- 糖分: {today_sugar}g（目標{goal_sugar}g以下）
- 食物繊維: {today_fiber}g（目標{goal_fiber}g）
- 塩分: {today_sodium}mg（目標{goal_sodium}mg以下）
- 栄養状況: {nutrition_status}
- 食べたもの: {today_meals if today_meals else "まだ記録なし"}
- 記録回数: {meal_count}回
{goal_hints}

【絶対NG】
- 「〇〇食べた？」「〇〇まだ？」「記録して」等の催促
- 「朝だにゃ」「夕方だにゃ」等の時間帯への言及

【ルール】
- 語尾「にゃ」、絵文字1個
- 1文で短く（25文字以内）
- いきなり本題に入る
- 栄養状況を参考に適切なアドバイス

1文のみ出力:"""
        
        try:
            response = model_flash_lite.generate_content(prompt)
            result = response.text.strip()
            if '\n' in result:
                result = result.split('\n')[0]
            return result
        except Exception as e:
            logger.error(f"Advice generation error: {e}")
            return GeminiService._get_fallback_advice(
                today_meals, progress_percent, remaining < 0, goal_direction,
                today_sugar, goal_sugar, today_fiber, goal_fiber, today_sodium, goal_sodium
            )
    
    @staticmethod
    def _get_fallback_advice(
        today_meals: str,
        progress_percent: int,
        is_over_budget: bool,
        goal_direction: str = "",
        today_sugar: int = 0,
        goal_sugar: int = 25,
        today_fiber: int = 0,
        goal_fiber: int = 20,
        today_sodium: int = 0,
        goal_sodium: int = 2300
    ) -> str:
        """API失敗時のフォールバックアドバイス（全栄養素対応）"""
        
        # 食事記録がある場合はそれに言及
        if today_meals:
            meals_list = today_meals.split('、') if '、' in today_meals else [today_meals]
            first_meal = meals_list[0].strip()[:8]
            return f"{first_meal}、美味しそうだにゃ🐱"
        
        # 栄養素の問題を優先的にチェック
        if goal_sugar > 0 and today_sugar > goal_sugar * 1.2:
            return "甘いもの控えめにゃ🍬"
        
        if goal_sodium > 0 and today_sodium > goal_sodium:
            return "塩分ちょっと多めかもにゃ🧂"
        
        if goal_fiber > 0 and today_fiber < goal_fiber * 0.3:
            return "野菜も食べてにゃ🥬"
        
        # 目標別メッセージ
        if goal_direction == "diet":
            if is_over_budget:
                return "少し歩くといいかもにゃ🚶"
            elif progress_percent <= 70:
                return "いい調子だにゃ✨"
            else:
                return "順調だにゃ💪"
        
        elif goal_direction == "bulk":
            if progress_percent < 80:
                return "もう少し食べても大丈夫だにゃ🍚"
            else:
                return "いい感じだにゃ💪"
        
        # デフォルト
        if is_over_budget:
            return "少し歩くといいかもにゃ🚶"
        elif progress_percent >= 80:
            return "いい感じだにゃ✨"
        elif progress_percent >= 50:
            return "順調だにゃ💪"
        else:
            return "今日も頑張ろうにゃ🐱"
    
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