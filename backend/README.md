# Caloken Backend API

カロ研（カロリー研究）アプリのバックエンドAPI

## 技術スタック

- **Framework**: FastAPI
- **Database**: Supabase (PostgreSQL)
- **AI**: Google Gemini 2.0 Flash
- **Hosting**: Railway.app

## ローカル開発

### 1. 環境変数を設定

```bash
cp .env.example .env
```

`.env`ファイルを編集:

```
SUPABASE_URL=https://ekfcrkbnxkphtkyvozgw.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
GEMINI_API_KEY=your-gemini-api-key
APP_ENV=development
DEBUG=true
```

### 2. 依存関係をインストール

```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. サーバーを起動

```bash
uvicorn app.main:app --reload --port 8000
```

APIドキュメント: http://localhost:8000/docs

## API エンドポイント

### 認証
- `POST /api/auth/signup` - 新規登録
- `POST /api/auth/login` - ログイン
- `POST /api/auth/refresh` - トークン更新
- `POST /api/auth/logout` - ログアウト

### ユーザー
- `GET /api/users/me` - プロフィール取得
- `PUT /api/users/me` - プロフィール更新
- `DELETE /api/users/me` - アカウント削除

### 食事記録
- `POST /api/meals` - 食事を記録
- `GET /api/meals` - 食事記録一覧
- `GET /api/meals/daily/{date}` - 日別サマリー
- `GET /api/meals/{id}` - 詳細取得
- `PUT /api/meals/{id}` - 更新
- `DELETE /api/meals/{id}` - 削除
- `POST /api/meals/saved` - お気に入りに追加
- `GET /api/meals/saved` - お気に入り一覧
- `DELETE /api/meals/saved/{id}` - お気に入り削除

### 運動記録
- `POST /api/exercises` - 運動を記録
- `GET /api/exercises` - 運動記録一覧
- `GET /api/exercises/daily/{date}` - 日別サマリー
- `GET /api/exercises/{id}` - 詳細取得
- `PUT /api/exercises/{id}` - 更新
- `DELETE /api/exercises/{id}` - 削除

### 体重記録
- `POST /api/weights` - 体重を記録
- `GET /api/weights` - 体重記録一覧
- `GET /api/weights/history` - 履歴（集計付き）
- `GET /api/weights/latest` - 最新の体重

### AI分析
- `POST /api/ai/analyze-meal` - 食事画像/テキスト分析
- `POST /api/ai/chat` - カロちゃんとチャット
- `GET /api/ai/chat/history` - チャット履歴

### 統計
- `GET /api/stats/daily/{date}` - 日次サマリー
- `GET /api/stats/weekly` - 週次サマリー
- `GET /api/stats/today/progress` - 今日の目標達成度

## Railway.appへのデプロイ

1. Railway.appでアカウント作成
2. 新しいプロジェクトを作成
3. GitHubリポジトリを接続
4. 環境変数を設定:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `GEMINI_API_KEY`
   - `APP_ENV=production`
   - `DEBUG=false`
5. デプロイ！

## ライセンス

Private - All rights reserved
