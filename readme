<div align="center">

# 🐱 カロ研 (Caloken)

### *AIがあなたの食事をサポートする、次世代カロリー管理アプリ*

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/ios)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-0071e3?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Gemini](https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)

<br>

<img src="https://img.shields.io/badge/Status-In_Development-orange?style=flat-square" alt="Status">
<img src="https://img.shields.io/badge/Version-1.0.0_Beta-blue?style=flat-square" alt="Version">
<img src="https://img.shields.io/badge/License-Private-red?style=flat-square" alt="License">

---

**📸 写真を撮るだけ • 🤖 AIが自動分析 • 🐱 カロちゃんがアドバイス**

</div>

<br>

## ✨ Features

<table>
<tr>
<td width="50%">

### 🍽️ AI食事分析
写真を撮るだけで、AIが**カロリー・栄養素を自動計算**。面倒な手入力は不要！

### 🐱 カロちゃんチャット
可愛い猫キャラクター「カロちゃん」が、あなたの食事や運動について**パーソナライズされたアドバイス**を提供。

### 📊 詳細な栄養管理
6つの栄養素（たんぱく質・脂質・炭水化物・糖分・食物繊維・ナトリウム）を**リアルタイムで追跡**。

</td>
<td width="50%">

### 🏃 運動記録
ランニング、筋トレ、その他の運動を簡単に記録。消費カロリーを自動計算。

### 📈 進捗トラッキング
体重の推移、摂取カロリーの傾向を**美しいグラフ**で可視化。

### 🎯 目標設定
ダイエット・維持・増量など、あなたの目標に合わせた**カスタマイズプラン**を作成。

</td>
</tr>
</table>

<br>

## 🛠️ Tech Stack

<div align="center">

### Frontend (iOS)
![Swift](https://img.shields.io/badge/Swift-F05138?style=for-the-badge&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0071e3?style=for-the-badge&logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-147EFB?style=for-the-badge&logo=xcode&logoColor=white)

### Backend
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Railway](https://img.shields.io/badge/Railway-0B0D0E?style=for-the-badge&logo=railway&logoColor=white)

### AI & Database
![Google Gemini](https://img.shields.io/badge/Gemini_2.5-8E75B2?style=for-the-badge&logo=google&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)

</div>

<br>

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     📱 iOS App (SwiftUI)                     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐ │
│  │  Home   │  │Progress │  │ Record  │  │    Settings     │ │
│  │   🏠    │  │   📈    │  │   ➕    │  │       ⚙️        │ │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────────┬────────┘ │
│       │            │            │                │          │
│       └────────────┴─────┬──────┴────────────────┘          │
│                          │                                   │
│                    NetworkManager                            │
└──────────────────────────┼───────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  🚀 FastAPI Backend (Railway)                │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  /v1/chat    │  │/v1/analyze   │  │   /v1/advice     │   │
│  │  (Pro/Flash) │  │   -meal      │  │    (Flash)       │   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘   │
│         │                 │                   │             │
│         └─────────────────┼───────────────────┘             │
│                           │                                  │
│                    Gemini AI API                             │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   🗄️ Supabase (PostgreSQL)                  │
│         Users • Meals • Exercises • Weight Logs             │
└─────────────────────────────────────────────────────────────┘
```

<br>

## 📁 Project Structure

```
📦 caroken/
├── 📱 ios/Caloken/           # iOS アプリ (SwiftUI)
│   ├── Views/
│   │   ├── Onboarding/       # オンボーディングフロー
│   │   ├── Home/             # ホーム画面
│   │   ├── Progress/         # 進捗画面
│   │   ├── Record/           # 記録画面（食事・運動）
│   │   └── Settings/         # 設定画面
│   ├── Models/               # データモデル
│   ├── Components/           # 共通UIコンポーネント
│   └── Network/              # API通信
│
├── 🐍 backend/               # FastAPI バックエンド
│   ├── main.py               # エントリーポイント
│   ├── routers/              # APIルーター
│   └── services/             # ビジネスロジック
│
└── 🖥️ admin/                 # 管理パネル (Next.js) [予定]
```

<br>

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Python 3.11+

### iOS App

```bash
# リポジトリをクローン
git clone https://github.com/taikisano-cloud/caroken.git

# Xcodeでプロジェクトを開く
cd caroken/ios/Caloken
open Caloken.xcodeproj

# シミュレーターまたは実機で実行
# Cmd + R
```

### Backend

```bash
cd caroken/backend

# 仮想環境を作成
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 依存関係をインストール
pip install -r requirements.txt

# 環境変数を設定
cp .env.example .env
# .envファイルを編集してAPIキーを設定

# サーバーを起動
uvicorn main:app --reload
```

<br>

## 🤖 AI Models

| 用途 | モデル | 特徴 |
|------|--------|------|
| 🗣️ チャット（高速モード） | Gemini 2.5 Flash | 高速レスポンス |
| 🧠 チャット（思考モード） | Gemini 2.5 Pro | 詳細な分析 |
| 📸 食事分析 | Gemini 2.5 Pro | 画像認識＋栄養計算 |
| 💡 ホームアドバイス | Gemini 2.5 Flash | リアルタイム提案 |

<br>

## 📱 Screenshots

<div align="center">

*Coming Soon* 🎨

</div>

<br>

## 🗺️ Roadmap

- [x] 📸 AI食事分析
- [x] 🐱 カロちゃんチャット
- [x] 📊 栄養素トラッキング
- [x] 🏃 運動記録
- [ ] 🍎 HealthKit連携
- [ ] 📱 Apple Watch対応
- [ ] 🌐 Web版
- [ ] 🤝 友達機能

<br>

## 👨‍💻 Author

<div align="center">

**Taiki Sano**

[![GitHub](https://img.shields.io/badge/GitHub-taikisano--cloud-181717?style=for-the-badge&logo=github)](https://github.com/taikisano-cloud)

</div>

<br>

---

<div align="center">

**Made with 🧡 and SwiftUI**

*カロちゃんと一緒に、健康的な毎日を！* 🐱✨

</div>