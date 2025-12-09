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

# ============================================
# モデル設定
# ============================================
# Flash: チャット用（高速モード）- flash-liteは会話に不向きなためflashを使用
model_flash = genai.GenerativeModel('gemini-2.0-flash')
# Pro: 高精度（画像分析、食事分析、思考モード用）
model_pro = genai.GenerativeModel('gemini-2.5-pro')
# Flash Lite: 軽量タスク用（アドバイス生成、メモリ抽出）
model_flash_lite = genai.GenerativeModel('gemini-flash-lite-latest')


class GeminiService:
    """Gemini AIサービス"""
    
    @staticmethod
    async def analyze_meal_image(image_base64: str) -> DetailedMealAnalysis:
        """
        食事画像を分析してカロリー・栄養素を推定
        ✅ Proモデル使用（高精度）
        """
        prompt = """
あなたは経験豊富な栄養士AIです。この食事の画像を詳細に分析してください。

【分析のポイント】
- 各食品の量を正確に推定する（見た目から判断）
- 調理法を考慮する（揚げ物は脂質が多いなど）
- 調味料やソースも考慮する
- 日本の一般的な食事のカロリーを参考にする

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
            
            # ✅ Pro モデルを使用（高精度分析）
            response = model_pro.generate_content([
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
            print(f"Gemini analyze_meal_image error: {e}")
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
        ✅ Proモデル使用（高精度）
        """
        prompt = f"""
あなたは経験豊富な栄養士AIです。以下の食事内容を詳細に分析してカロリーと栄養素を推定してください。

食事内容: {description}

【分析のポイント】
- 食品名から一般的な量を推定する
- 調理法を考慮する（揚げ物、炒め物など）
- 日本の一般的な食事のカロリーを参考にする
- 不明な場合は一般的な値を使用する

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
            # ✅ Pro モデルを使用（高精度分析）
            response = model_pro.generate_content(prompt)
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
            print(f"Gemini analyze_meal_text error: {e}")
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
        mode: str = "fast",
        user_memories: Optional[list] = None
    ) -> dict:
        """
        カロちゃんとのチャット（会話履歴対応・フルユーザーコンテキスト）
        
        mode: 
        - "fast" = 高速モード（Flash）
        - "thinking" = 思考モード（Pro）
        
        Returns: {"response": str, "memory_to_save": Optional[dict]}
        """
        from datetime import datetime
        import pytz
        
        # 日本時間を取得
        jst = pytz.timezone('Asia/Tokyo')
        now = datetime.now(jst)
        current_time = now.strftime("%Y年%m月%d日 %H時%M分")
        hour = now.hour
        
        # 時間帯の判定
        if 5 <= hour < 10:
            time_period = "朝"
            greeting_hint = "おはようの挨拶が自然"
        elif 10 <= hour < 14:
            time_period = "昼"
            greeting_hint = "ランチの話題が自然"
        elif 14 <= hour < 18:
            time_period = "午後"
            greeting_hint = "おやつや夕食の準備の話題が自然"
        elif 18 <= hour < 22:
            time_period = "夜"
            greeting_hint = "夕食や1日の振り返りの話題が自然"
        else:
            time_period = "深夜"
            greeting_hint = "夜更かしを心配する、軽い夜食の話題が自然"
        
        context = f"\n【現在の時刻】\n{current_time}（{time_period}）\n※{greeting_hint}\n"
        
        # ユーザー記憶があれば追加
        if user_memories and len(user_memories) > 0:
            context += "\n【覚えていること】\n"
            for mem in user_memories[-10:]:
                context += f"- {mem.get('content', '')}（{mem.get('category', '')}）\n"
        
        if user_context:
            context += "\n【ユーザー情報】\n"
            
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
            if user_context.get('goal'):
                context += f"- 目標: {user_context.get('goal')}\n"
            if user_context.get('exercise_frequency'):
                context += f"- 運動頻度: {user_context.get('exercise_frequency')}\n"
            
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
            
            if user_context.get('today_meals'):
                context += f"\n今日食べたもの: {user_context.get('today_meals')}\n"
        
        # 会話履歴を構築
        history_text = ""
        if chat_history and len(chat_history) > 0:
            history_text = "\n\n【これまでの会話】\n"
            for msg in chat_history[-10:]:
                role = "ユーザー" if msg.get('is_user') else "カロちゃん"
                history_text += f"{role}: {msg.get('message', '')}\n"
        
        system_prompt = f"""あなたは「カロちゃん」という名前の可愛い猫のAIアシスタントです。
カロ研（カロリー研究）アプリのマスコットキャラクターとして、ユーザーの健康管理をサポートします。

【キャラクター設定】
- 明るくて元気、ユーザーを励ます猫キャラ
- 語尾に「にゃ」「だにゃ」を自然につける（毎文ではなく適度に）
- 絵文字を適度に使う（🐱😊🔥💪🍽️など）
- 専門的なアドバイスも分かりやすく伝える

【最重要ルール】
1. ユーザーのメッセージに直接答える
2. 質問されたら具体的に回答する
3. 「明日のメニュー」と聞かれたら、具体的な料理を提案する
4. 挨拶には挨拶で返す
5. 雑談には雑談で返す

{context}
{history_text}

【ユーザーのメッセージ】
{message}

上記のメッセージに対して、カロちゃんとして自然に返答してください。
ユーザーが何を求めているかを理解し、それに直接答えてください。"""
        
        try:
            # ✅ モードに応じてモデルを選択
            if image_base64:
                image_data = base64.b64decode(image_base64)
                # 画像付きの場合はProモデル
                response = model_pro.generate_content([
                    system_prompt,
                    {"mime_type": "image/jpeg", "data": image_data}
                ])
            elif mode == "thinking":
                # 思考モード: Proモデル
                response = model_pro.generate_content(system_prompt)
            else:
                # 高速モード: Flashモデル（flash-liteは会話に不向き）
                response = model_flash.generate_content(system_prompt)
            
            response_text = response.text.strip()
            
            # ✅ 記憶抽出
            memory_to_save = await GeminiService.extract_memory(message, response_text)
            
            return {
                "response": response_text,
                "memory_to_save": memory_to_save
            }
            
        except Exception as e:
            print(f"Gemini chat API Error: {e}")
            return {
                "response": f"ごめんにゃ、ちょっと調子が悪いみたい...😿 もう一度話しかけてほしいにゃ！",
                "memory_to_save": None
            }
    
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
        ✅ Flash Liteモデル使用（高速）
        """
        remaining = goal_calories - today_calories
        progress_percent = int((today_calories / goal_calories) * 100) if goal_calories > 0 else 0
        
        from datetime import datetime
        import pytz
        jst = pytz.timezone('Asia/Tokyo')
        hour = datetime.now(jst).hour
        
        if hour < 10:
            time_context = "朝の時間帯"
        elif hour < 14:
            time_context = "昼の時間帯"
        elif hour < 18:
            time_context = "夕方の時間帯"
        else:
            time_context = "夜の時間帯"
        
        prompt = f"""あなたは「カロちゃん」という猫のAIアシスタントです。

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
- 具体的で役立つアドバイスにする"""
        
        try:
            response = model_flash_lite.generate_content(prompt)
            return response.text.strip()
        except Exception as e:
            print(f"Gemini generate_advice API Error: {e}")
            return "今日も一緒にがんばろうにゃ！🐱"
    
    @staticmethod
    async def extract_memory(message: str, response: str) -> Optional[dict]:
        """
        会話から重要な情報を抽出して記憶として保存するか判断
        ✅ Flash Liteモデル使用（高速）
        """
        prompt = f"""以下の会話から、覚えておくべき重要な情報があるか判断してください。

【ユーザーのメッセージ】
{message}

【カロちゃんの返答】
{response}

【抽出すべき情報の例】
- 食の好み（嫌いな食べ物、アレルギー、好きな料理）→ 長期記憶
- 健康目標（ダイエット目標、筋トレ目標）→ 長期記憶
- 生活習慣（朝型/夜型、食事時間の傾向）→ 長期記憶
- 体の状態（持病、体質）→ 長期記憶
- 予定・イベント（「来週〇〇がある」「誕生日は〇月」など）→ 短期記憶（期限付き）
- 一時的な状況（「今日は疲れた」「風邪気味」など）→ 短期記憶（1日）

【指示】
重要な情報があれば以下のJSON形式で返答してください。
なければ「null」とだけ返答してください。

{{
    "category": "preference|goal|health|habit|event|temporary",
    "content": "抽出した情報（簡潔に）",
    "importance": 1-5の数字,
    "expires_in_days": null（永続）または数字（何日後に期限切れ）
}}"""
        
        try:
            result = model_flash_lite.generate_content(prompt)
            text = result.text.strip()
            
            if text.lower() == "null" or text == "":
                return None
            
            if "```" in text:
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]
            
            memory = json.loads(text.strip())
            
            from datetime import datetime, timedelta
            if memory.get('expires_in_days') is not None:
                expires_at = datetime.now() + timedelta(days=memory['expires_in_days'])
                memory['expires_at'] = expires_at.isoformat()
            else:
                memory['expires_at'] = None
            
            memory['created_at'] = datetime.now().isoformat()
            
            return memory
        except Exception as e:
            print(f"Memory extraction error: {e}")
            return None


gemini_service = GeminiService()