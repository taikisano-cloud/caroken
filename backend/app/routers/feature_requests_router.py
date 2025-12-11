from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.database import get_supabase_admin
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/feature-requests", tags=["機能リクエスト"])


# MARK: - リクエストモデル

class FeatureRequestCreate(BaseModel):
    title: str
    description: str


class FeatureRequestUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None


class CommentCreate(BaseModel):
    content: str


# MARK: - レスポンスモデル

class CommentResponse(BaseModel):
    id: str
    user_id: str
    display_name: str
    content: str
    created_at: datetime
    is_owner: bool = False


class FeatureRequestResponse(BaseModel):
    id: str
    author_id: str
    author_name: str
    title: str
    description: str
    votes: int
    status: str
    has_voted: bool = False
    is_owner: bool = False
    comments: List[CommentResponse] = []
    created_at: datetime
    updated_at: datetime


# MARK: - エンドポイント

@router.get("", response_model=List[FeatureRequestResponse])
async def get_feature_requests(
    current_user: dict = Depends(get_current_user)
):
    """全ての機能リクエストを取得（投票数順）"""
    try:
        supabase = get_supabase_admin()
        user_id = current_user["id"]
        
        # リクエスト一覧を取得
        requests_response = supabase.table("feature_requests").select(
            "*, profiles!feature_requests_author_id_fkey(display_name)"
        ).order("votes", desc=True).execute()
        
        # 現在のユーザーの投票を取得
        votes_response = supabase.table("feature_request_votes").select(
            "request_id"
        ).eq("user_id", user_id).execute()
        
        voted_request_ids = {v["request_id"] for v in votes_response.data}
        
        result = []
        for req in requests_response.data:
            author_name = req.get("profiles", {}).get("display_name", "匿名")
            
            result.append(FeatureRequestResponse(
                id=req["id"],
                author_id=req["author_id"],
                author_name=author_name,
                title=req["title"],
                description=req["description"],
                votes=req["votes"],
                status=req["status"],
                has_voted=req["id"] in voted_request_ids,
                is_owner=req["author_id"] == user_id,
                comments=[],
                created_at=req["created_at"],
                updated_at=req["updated_at"]
            ))
        
        return result
        
    except Exception as e:
        print(f"Error getting feature requests: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/{request_id}", response_model=FeatureRequestResponse)
async def get_feature_request(
    request_id: str,
    current_user: dict = Depends(get_current_user)
):
    """特定の機能リクエストを取得（コメント含む）"""
    try:
        supabase = get_supabase_admin()
        user_id = current_user["id"]
        
        # リクエストを取得
        req_response = supabase.table("feature_requests").select(
            "*, profiles!feature_requests_author_id_fkey(display_name)"
        ).eq("id", request_id).single().execute()
        
        if not req_response.data:
            raise HTTPException(status_code=404, detail="Request not found")
        
        req = req_response.data
        author_name = req.get("profiles", {}).get("display_name", "匿名")
        
        # 投票確認
        vote_response = supabase.table("feature_request_votes").select(
            "id"
        ).eq("request_id", request_id).eq("user_id", user_id).execute()
        
        has_voted = len(vote_response.data) > 0
        
        # コメントを取得
        comments_response = supabase.table("feature_request_comments").select(
            "*, profiles!feature_request_comments_user_id_fkey(display_name)"
        ).eq("request_id", request_id).order("created_at", desc=True).execute()
        
        comments = []
        for c in comments_response.data:
            display_name = c.get("profiles", {}).get("display_name", "匿名")
            comments.append(CommentResponse(
                id=c["id"],
                user_id=c["user_id"],
                display_name=display_name,
                content=c["content"],
                created_at=c["created_at"],
                is_owner=c["user_id"] == user_id
            ))
        
        return FeatureRequestResponse(
            id=req["id"],
            author_id=req["author_id"],
            author_name=author_name,
            title=req["title"],
            description=req["description"],
            votes=req["votes"],
            status=req["status"],
            has_voted=has_voted,
            is_owner=req["author_id"] == user_id,
            comments=comments,
            created_at=req["created_at"],
            updated_at=req["updated_at"]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error getting feature request: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("", response_model=FeatureRequestResponse)
async def create_feature_request(
    request: FeatureRequestCreate,
    current_user: dict = Depends(get_current_user)
):
    """新しい機能リクエストを作成"""
    try:
        supabase = get_supabase_admin()
        user_id = current_user["id"]
        
        # リクエストを作成
        req_data = {
            "author_id": user_id,
            "title": request.title,
            "description": request.description,
            "votes": 1  # 作成者は自動で1票
        }
        
        req_response = supabase.table("feature_requests").insert(req_data).execute()
        req = req_response.data[0]
        
        # 作成者の投票を追加
        supabase.table("feature_request_votes").insert({
            "request_id": req["id"],
            "user_id": user_id
        }).execute()
        
        # 作成者の名前を取得
        profile_response = supabase.table("profiles").select(
            "display_name"
        ).eq("id", user_id).single().execute()
        
        author_name = profile_response.data.get("display_name", "匿名") if profile_response.data else "匿名"
        
        return FeatureRequestResponse(
            id=req["id"],
            author_id=req["author_id"],
            author_name=author_name,
            title=req["title"],
            description=req["description"],
            votes=req["votes"],
            status=req["status"],
            has_voted=True,
            is_owner=True,
            comments=[],
            created_at=req["created_at"],
            updated_at=req["updated_at"]
        )
        
    except Exception as e:
        print(f"Error creating feature request: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/{request_id}")
async def delete_feature_request(
    request_id: str,
    current_user: dict = Depends(get_current_user)
):
    """機能リクエストを削除（作成者のみ）"""
    try:
        supabase = get_supabase_admin()
        user_id = current_user["id"]
        
        # 所有者確認
        req_response = supabase.table("feature_requests").select(
            "author_id"
        ).eq("id", request_id).single().execute()
        
        if not req_response.data:
            raise HTTPException(status_code=404, detail="Request not found")
        
        if req_response.data["author_id"] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        # 削除（CASCADE設定により投票・コメントも削除される）
        supabase.table("feature_requests").delete().eq("id", request_id).execute()
        
        return {"message": "Deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error deleting feature request: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/{request_id}/vote")
async def toggle_vote(
    request_id: str,
    current_user: dict = Depends(get_current_user)
):
    """投票のトグル（投票/取り消し）"""
    try:
        supabase = get_supabase_admin()
        user_id = current_user["id"]
        
        # 既存の投票を確認
        existing_vote = supabase.table("feature_request_votes").select(
            "id"
        ).eq("request_id", request_id).eq("user_id", user_id).execute()
        
        if existing_vote.data:
            # 投票を取り消し
            supabase.table("feature_request_votes").delete().eq(
                "request_id", request_id
            ).eq("user_id", user_id).execute()
            
            return {"voted": False, "message": "Vote removed"}
        else:
            # 投票を追加
            supabase.table("feature_request_votes").insert({
                "request_id": request_id,
                "user_id": user_id
            }).execute()
            
            return {"voted": True, "message": "Vote added"}
        
    except Exception as e:
        print(f"Error toggling vote: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("/{request_id}/comments", response_model=CommentResponse)
async def add_comment(
    request_id: str,
    comment: CommentCreate,
    current_user: dict = Depends(get_current_user)
):
    """コメントを追加"""
    try:
        supabase = get_supabase_admin()
        user_id = current_user["id"]
        
        # コメントを作成
        comment_data = {
            "request_id": request_id,
            "user_id": user_id,
            "content": comment.content
        }
        
        response = supabase.table("feature_request_comments").insert(comment_data).execute()
        c = response.data[0]
        
        # 作成者の名前を取得
        profile_response = supabase.table("profiles").select(
            "display_name"
        ).eq("id", user_id).single().execute()
        
        display_name = profile_response.data.get("display_name", "匿名") if profile_response.data else "匿名"
        
        return CommentResponse(
            id=c["id"],
            user_id=c["user_id"],
            display_name=display_name,
            content=c["content"],
            created_at=c["created_at"],
            is_owner=True
        )
        
    except Exception as e:
        print(f"Error adding comment: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/{request_id}/comments/{comment_id}")
async def delete_comment(
    request_id: str,
    comment_id: str,
    current_user: dict = Depends(get_current_user)
):
    """コメントを削除（作成者のみ）"""
    try:
        supabase = get_supabase_admin()
        user_id = current_user["id"]
        
        # 所有者確認
        comment_response = supabase.table("feature_request_comments").select(
            "user_id"
        ).eq("id", comment_id).single().execute()
        
        if not comment_response.data:
            raise HTTPException(status_code=404, detail="Comment not found")
        
        if comment_response.data["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        # 削除
        supabase.table("feature_request_comments").delete().eq("id", comment_id).execute()
        
        return {"message": "Comment deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error deleting comment: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
