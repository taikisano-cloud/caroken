from fastapi import APIRouter, HTTPException, Depends, status
from app.database import get_supabase_admin
from app.middleware.auth import get_current_user
from app.models.user import ProfileResponse, ProfileUpdate

router = APIRouter(prefix="/users", tags=["ユーザー"])


@router.get("/me", response_model=ProfileResponse)
async def get_my_profile(current_user: dict = Depends(get_current_user)):
    """
    自分のプロフィールを取得
    """
    try:
        supabase = get_supabase_admin()
        response = supabase.table("profiles").select("*").eq("id", current_user["id"]).single().execute()
        
        if response.data is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found"
            )
        
        return ProfileResponse(**response.data)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.put("/me", response_model=ProfileResponse)
async def update_my_profile(
    profile: ProfileUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    自分のプロフィールを更新
    """
    try:
        supabase = get_supabase_admin()
        
        # None以外の値のみ更新
        update_data = {k: v for k, v in profile.model_dump().items() if v is not None}
        
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No data to update"
            )
        
        response = supabase.table("profiles").update(update_data).eq("id", current_user["id"]).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found"
            )
        
        return ProfileResponse(**response.data[0])
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("/me")
async def delete_my_account(current_user: dict = Depends(get_current_user)):
    """
    自分のアカウントを削除
    """
    try:
        supabase = get_supabase_admin()
        
        # プロフィールを削除（CASCADE設定により関連データも削除される）
        supabase.table("profiles").delete().eq("id", current_user["id"]).execute()
        
        # 認証ユーザーを削除
        supabase.auth.admin.delete_user(current_user["id"])
        
        return {"message": "Account deleted successfully"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
