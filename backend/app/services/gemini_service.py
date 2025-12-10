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
model = genai.GenerativeModel('gemini-2.5-pro')  # メイン（チャット、分析）
model_flash_lite = genai.GenerativeModel('gemini-2.0-flash-lite')  # 軽量（ホームアドバイス）


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
        image_base64: Optional[str] = None,
        chat_history: Optional[list] = None,
        mode: str = "fast"
    ) -> str:
        """
        カロちゃんとのチャット（会話履歴対応・フルユーザーコンテキスト）
        
        mode:
        - "fast": Flash Lite使用（高速）
        - "thinking": Pro使用（高品質）
        """
        context = ""
        if user_context:
            # 基本情報
            context = "\n【ユーザー情報】\n"
            
            # 身体情報
            if user_context.get('gender'):
                context += f"- 性別: {user_context.get('gender')}\n"
            if user_context.get('age'):
                context += f"- 年齢: {user_context.get('age')}歳\n"
            if user_context.get('height'):
                context += f"- 身長: {user_context.get('height')}cm\n"
            if user_context.get('current_weight'):
                context += f"- 現在の体重: {user_context.get('current_weight')}kg\n"
            if user_context.get('target_weight'):
                context += f"- 目標体重: {user_context.get('target_weight')}kg\n"
            if user_context.get('bmi'):
                context += f"- BMI: {user_context.get('bmi')} ({user_context.get('bmi_status', '')})\n"
            
            # 目標
            if user_context.get('goal'):
                context += f"- 目標: {user_context.get('goal')}\n"
            if user_context.get('exercise_frequency'):
                context += f"- 運動頻度: {user_context.get('exercise_frequency')}\n"
            
            # 栄養目標
            context += "\n【今日の状況】\n"
            if user_context.get('today_calories') is not None:
                context += f"- 摂取カロリー: {user_context.get('today_calories')}kcal"
                if user_context.get('calorie_goal'):
                    context += f" / 目標{user_context.get('calorie_goal')}kcal"
                context += "\n"
            
            if user_context.get('today_protein') is not None:
                context += f"- たんぱく質: {user_context.get('today_protein')}g"
                if user_context.get('protein_goal'):
                    context += f" / 目標{user_context.get('protein_goal')}g"
                context += "\n"
            
            if user_context.get('today_fat') is not None:
                context += f"- 脂質: {user_context.get('today_fat')}g"
                if user_context.get('fat_goal'):
                    context += f" / 目標{user_context.get('fat_goal')}g"
                context += "\n"
            
            if user_context.get('today_carbs') is not None:
                context += f"- 炭水化物: {user_context.get('today_carbs')}g"
                if user_context.get('carb_goal'):
                    context += f" / 目標{user_context.get('carb_goal')}g"
                context += "\n"
            
            if user_context.get('today_exercise'):
                context += f"- 運動消費: {user_context.get('today_exercise')}kcal\n"
            
            if user_context.get('remaining_calories') is not None:
                remaining = user_context.get('remaining_calories')
                if remaining > 0:
                    context += f"- 残りカロリー: あと{remaining}kcal食べられる\n"
                else:
                    context += f"- 残りカロリー: {abs(remaining)}kcalオーバー⚠️\n"
            
            # 今日の食事内容があれば追加
            if user_context.get('today_meals'):
                context += f"\n今日食べたもの: {user_context.get('today_meals')}\n"
        
        # 会話履歴を構築
        history_text = ""
        if chat_history and len(chat_history) > 0:
            history_text = "\n\n【これまでの会話】\n"
            for msg in chat_history[-10:]:  # 直近10件まで
                role = "ユーザー" if msg.get('is_user') else "カロちゃん"
                history_text += f"{role}: {msg.get('message', '')}\n"
        
        system_prompt = f"""
あなたは「カロちゃん」という名前の可愛い猫のAIアシスタントです。
カロ研（カロリー研究）アプリのマスコットキャラクターとして、ユーザーの健康管理をサポートします。

【性格】
- 明るくて元気、ユーザーを励ます
- 語尾に「にゃ」「だにゃ」をつける
- 絵文字を適度に使う（🐱😊🔥💪🍽️など）
- 専門的なアドバイスも分かりやすく伝える
- ユーザーの食事や健康について具体的なアドバイスをする

【重要】
- ユーザーの情報（性別、年齢、体重、目標など）を理解して、パーソナライズされたアドバイスをする
- 会話の流れを理解して、自然に返答する
- 毎回カロリーの話をするのではなく、ユーザーの質問や話題に合わせる
- 料理の提案、レシピのアドバイス、励ましなど多様な返答をする
- 過去の会話を参照して、一貫性のある返答をする
- ユーザーの目標（減量/維持/増量）に合わせたアドバイスをする

【レシピ・料理の提案時】
ユーザーが「何を食べたらいい？」「おすすめのメニューは？」「レシピを教えて」「献立」などと聞いてきた場合：
- 具体的な料理名を提案する
- 必ずDELISH KITCHENのレシピ検索URLを含める
- URL形式: https://delishkitchen.tv/search?q=料理名やキーワード（スペースは+に変換）
- 例: 「鶏むね肉のレシピはここで見れるにゃ！→ https://delishkitchen.tv/search?q=鶏むね肉+ヘルシー 🍳」

【運動の提案時】
ユーザーが「おすすめの運動は？」「どんな運動したらいい？」「筋トレ教えて」「ストレッチ」などと聞いてきた場合：
- 具体的な運動名を提案する
- 必ずYouTubeの検索URLを含める
- URL形式: https://www.youtube.com/results?search_query=運動名（スペースは+に変換）
- 例: 「スクワットがおすすめだにゃ！やり方はここで見れるにゃ→ https://www.youtube.com/results?search_query=スクワット+やり方 💪」

【URL提案のルール】
- URLは1回の返答につき1つまで（多すぎると読みにくい）
- 検索キーワードはスペースを+に変換する（例: 鶏むね肉 ダイエット → 鶏むね肉+ダイエット）
- ユーザーの目標に合わせたキーワードを選ぶ（ダイエット、高たんぱく、時短、簡単など）
- URLの前後に改行を入れて見やすくする

{context}
{history_text}

【現在のユーザーのメッセージ】
{message}

カロちゃんとして自然に返答してください（2-4文程度）:
"""
        
        try:
            # モデル選択: 画像ありまたはthinkingモードはPro、それ以外はFlash Lite
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
            import traceback
            print(f"Gemini API Error: {e}")
            print(traceback.format_exc())
            return "ごめんにゃ、ちょっと調子が悪いみたい...😿 もう一度話しかけてほしいにゃ！"
    
    @staticmethod
    async def generate_advice(
        today_calories: int,
        goal_calories: int,
        today_protein: int,
        today_fat: int,
        today_carbs: int,
        today_meals: str,
        meal_count: int
    ) -> str:
        """
        ホーム画面用のアドバイスを生成
        """
        remaining = goal_calories - today_calories
        progress_percent = int((today_calories / goal_calories) * 100) if goal_calories > 0 else 0
        
        # 時間帯を考慮
        from datetime import datetime
        hour = datetime.now().hour
        time_context = ""
        if hour < 10:
            time_context = "朝の時間帯"
        elif hour < 14:
            time_context = "昼の時間帯"
        elif hour < 18:
            time_context = "夕方の時間帯"
        else:
            time_context = "夜の時間帯"
        
        prompt = f"""
あなたは「カロちゃん」という猫のAIアシスタントです。

【ユーザーの今日の状況】
- 摂取カロリー: {today_calories}kcal / 目標: {goal_calories}kcal
- 達成率: {progress_percent}%
- 残りカロリー: {remaining}kcal
- たんぱく質: {today_protein}g
- 脂質: {today_fat}g
- 炭水化物: {today_carbs}g
- 食事回数: {meal_count}回
- 今日食べたもの: {today_meals or 'まだ記録なし'}
- 現在の時間帯: {time_context}

【指示】
上記の状況に合わせた短いアドバイスを1文で返してください。
- 語尾に「にゃ」をつける
- 絵文字を1-2個使う
- 具体的で役立つアドバイスにする
- 状況に応じて変化させる

例:
- 「朝ごはんまだみたいだにゃ！軽くでもいいから食べてほしいにゃ🍳」
- 「いい感じに進んでるにゃ！あと{remaining}kcalだから夕食は軽めがおすすめだにゃ🐱」
- 「たんぱく質がちょっと少ないかも...お肉かお魚を食べるといいにゃ💪」
"""
        
        try:
            response = model_flash_lite.generate_content(prompt)
            return response.text.strip()
        except Exception as e:
            print(f"Gemini API Error (advice): {e}")
            return "今日も一緒にがんばろうにゃ！🐱"


gemini_service = GeminiService()