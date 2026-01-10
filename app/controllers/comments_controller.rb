class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    post = Post.find(params[:post_id])
    @comment = post.comments.create(body: params[:comment_body], author_id: current_user.id)
    @comment.save!
    redirect_to post, notice: "Ваш коментар збережений"
#    redirect_back(fallback_location: post)
  end

  def destroy
    @comment = Comment.find(params[:comment_id])
    post = @comment.post
    if (@comment.author.id == current_user.id || current_user.admin == 1)
      @comment.destroy
    end
    redirect_to post, notice: "Коментар видалений"
#    redirect_back(fallback_location: post)
  end

end
