class User::PostsController < ApplicationController
  before_action :authenticate_user!

  def index
    @posts = Post.published.all.includes(:tags).order(created_at: :desc)
    @users = User.all
    @comment = Comment.new
  end

  def new
    @post = Post.new
    @user = current_user
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user

    if @post.published?
      # 公開処理
      if @post.save
        redirect_to posts_path, notice: "投稿を公開しました！"
      else
        render :new, alert: "投稿の公開に失敗しました。"
      end
    else
      # 下書き保存処理
      if @post.save
        redirect_to user_path(current_user), notice: "下書きを保存しました！"
      else
        render :new, alert: "下書きの保存に失敗しました。"
      end
    end
  end

  def show
    @post = Post.with_attached_image.find(params[:id])
    @user = @post.user
    @prefecture = @post.prefecture
    @tags = @post.tag_counts_on(:tags)
    @comments = @post.comments.all
    @comment = Comment.new
    respond_to do |format|
      format.html
      # link_toメソッドをremote: trueに設定したのでリクエストはjs形式で行われる（詳しくは参照記事をご覧ください）
      format.js
    end
  end

  def edit
    @post = Post.with_attached_image.find(params[:id])
    @user = @post.user
  end

  def update
    @post = Post.find(params[:id])

    case params[:post][:post_status]
    when 'draft'
      # 下書き保存処理
      if @post.update(post_params)
        flash[:notice] = "下書きを保存しました"
        redirect_to user_path(current_user)
      else
        flash.now[:alert] = "下書きの保存に失敗しました"
        render 'edit'
      end
    when 'unpublished'
      # 非公開処理
      if @post.update(post_params)
        @post.unpublished! if @post.can_unpublished?
        flash[:notice] = "非公開にしました"
        redirect_to user_path(current_user)
      else
        flash.now[:alert] = "非公開の設定に失敗しました"
        render 'edit'
      end
    when 'published'
      # 公開処理
      if @post.update(post_params)
        @post.published! if @post.can_published?
        flash[:notice] = "投稿を公開しました"
        redirect_to posts_path
      else
        flash.now[:alert] = "投稿の公開に失敗しました"
        render 'edit'
      end
    else
      # デフォルトの更新処理
      if @post.update(post_params)
        flash[:notice] = "投稿内容を更新しました"
        redirect_to posts_path
      else
        flash.now[:alert] = "投稿内容の更新に失敗しました"
        render 'edit'
      end
    end


    if @post.update(post_params)
      flash[:notice] = "投稿内容を更新しました"
      redirect_to redirect_path, notice: notice_message
    else
      flash.now[:alert] = "投稿内容の更新に失敗しました"
      render 'edit'
    end
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    flash[:notice] = "投稿が削除されました"
    redirect_to posts_path
  end

  private

  def post_params
     params.require(:post).permit(:image, :prefecture_id, :tag_list, :content, :post_status, :address, :latitude, :longitude)
  end
end
