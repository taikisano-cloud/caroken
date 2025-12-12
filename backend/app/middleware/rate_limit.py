# app/middleware/rate_limit.py
"""
Rate Limiting ミドルウェア
API乱用を防ぐためのリクエスト制限
"""

from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from collections import defaultdict
from datetime import datetime, timedelta
import asyncio
from typing import Dict, Tuple


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    シンプルなインメモリ Rate Limiting
    
    - IPアドレスごとにリクエスト数を制限
    - 制限を超えると429 Too Many Requestsを返す
    """
    
    def __init__(
        self,
        app,
        requests_per_minute: int = 60,
        requests_per_hour: int = 1000,
        enabled: bool = True
    ):
        super().__init__(app)
        self.requests_per_minute = requests_per_minute
        self.requests_per_hour = requests_per_hour
        self.enabled = enabled
        
        # IPごとのリクエスト記録: {ip: [(timestamp, count), ...]}
        self.minute_requests: Dict[str, list] = defaultdict(list)
        self.hour_requests: Dict[str, list] = defaultdict(list)
        
        # クリーンアップ用のロック
        self._lock = asyncio.Lock()
    
    async def dispatch(self, request: Request, call_next):
        # Rate Limitingが無効、またはヘルスチェックはスキップ
        if not self.enabled or request.url.path in ["/", "/health"]:
            return await call_next(request)
        
        # クライアントIPを取得
        client_ip = self._get_client_ip(request)
        
        # レート制限チェック
        is_limited, retry_after = await self._check_rate_limit(client_ip)
        
        if is_limited:
            return JSONResponse(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                content={
                    "error": "Too many requests",
                    "message": "リクエスト数が制限を超えました。しばらく待ってから再試行してください。",
                    "retry_after": retry_after
                },
                headers={"Retry-After": str(retry_after)}
            )
        
        # リクエストを記録
        await self._record_request(client_ip)
        
        # 次の処理へ
        response = await call_next(request)
        return response
    
    def _get_client_ip(self, request: Request) -> str:
        """クライアントIPを取得（プロキシ対応）"""
        # X-Forwarded-Forヘッダーをチェック（Railwayなどのプロキシ経由）
        forwarded = request.headers.get("X-Forwarded-For")
        if forwarded:
            # 最初のIPがクライアントIP
            return forwarded.split(",")[0].strip()
        
        # X-Real-IPヘッダーをチェック
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        # 直接接続の場合
        return request.client.host if request.client else "unknown"
    
    async def _check_rate_limit(self, client_ip: str) -> Tuple[bool, int]:
        """レート制限をチェック。制限超過時は(True, retry_after秒)を返す"""
        now = datetime.now()
        
        async with self._lock:
            # 古いエントリをクリーンアップ
            await self._cleanup_old_entries(client_ip, now)
            
            # 分あたりのリクエスト数をチェック
            minute_count = len(self.minute_requests[client_ip])
            if minute_count >= self.requests_per_minute:
                # 最も古いリクエストが期限切れになるまでの秒数
                oldest = self.minute_requests[client_ip][0]
                retry_after = 60 - (now - oldest).seconds
                return True, max(1, retry_after)
            
            # 時間あたりのリクエスト数をチェック
            hour_count = len(self.hour_requests[client_ip])
            if hour_count >= self.requests_per_hour:
                oldest = self.hour_requests[client_ip][0]
                retry_after = 3600 - (now - oldest).seconds
                return True, max(1, retry_after)
        
        return False, 0
    
    async def _record_request(self, client_ip: str):
        """リクエストを記録"""
        now = datetime.now()
        
        async with self._lock:
            self.minute_requests[client_ip].append(now)
            self.hour_requests[client_ip].append(now)
    
    async def _cleanup_old_entries(self, client_ip: str, now: datetime):
        """古いエントリを削除"""
        minute_ago = now - timedelta(minutes=1)
        hour_ago = now - timedelta(hours=1)
        
        # 1分以上前のエントリを削除
        self.minute_requests[client_ip] = [
            ts for ts in self.minute_requests[client_ip]
            if ts > minute_ago
        ]
        
        # 1時間以上前のエントリを削除
        self.hour_requests[client_ip] = [
            ts for ts in self.hour_requests[client_ip]
            if ts > hour_ago
        ]


# エンドポイント別のRate Limiter（より細かい制御用）
class EndpointRateLimiter:
    """
    特定のエンドポイント用のRate Limiter
    デコレータとして使用可能
    """
    
    def __init__(self, requests_per_minute: int = 10):
        self.requests_per_minute = requests_per_minute
        self.requests: Dict[str, list] = defaultdict(list)
        self._lock = asyncio.Lock()
    
    async def check(self, identifier: str) -> bool:
        """制限内ならTrue、制限超過ならFalse"""
        now = datetime.now()
        minute_ago = now - timedelta(minutes=1)
        
        async with self._lock:
            # 古いエントリを削除
            self.requests[identifier] = [
                ts for ts in self.requests[identifier]
                if ts > minute_ago
            ]
            
            # 制限チェック
            if len(self.requests[identifier]) >= self.requests_per_minute:
                return False
            
            # 記録
            self.requests[identifier].append(now)
            return True


# AI APIなど高コストなエンドポイント用
ai_rate_limiter = EndpointRateLimiter(requests_per_minute=20)

# 認証エンドポイント用（ブルートフォース対策）
auth_rate_limiter = EndpointRateLimiter(requests_per_minute=5)