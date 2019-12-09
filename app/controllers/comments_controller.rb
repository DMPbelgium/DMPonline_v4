class CommentsController < ApplicationController
  before_filter :authenticate_user!

  # GET /comments/1
  # GET /comments/1.json
  def show
    @comment = Comment.find(params[:id])
    authorize! :show,@comment

    render json: @comment
  end


  # GET /comments/1/edit
  def edit
    @comment = Comment.find(params[:id])
    authorize! :edit,@comment
  end

  # POST /comments
  # POST /comments.json
  def create

    p = params.require(:comment).permit(:text,:question_id,:plan_id)

    @comment = Comment.new(p)
    @comment.user_id = current_user.id

    authorize! :create, @comment

    if @comment.save
      c = @comment.attributes
      c[:h] = {
        :created_at => @comment.created_at.getlocal.strftime("%d/%m/%Y %H:%M"),
        :updated_at => @comment.updated_at.getlocal.strftime("%d/%m/%Y %H:%M"),
        :created_by => current_user.name
      }
      render json: c
    else
      render json: { :errors => @comment.errors.full_messages }
    end

  end

  # PUT /comments/1
  # PUT /comments/1.json
  def update

    p = params.require(:comment).permit(:id,:text)

    @comment = Comment.find(p[:id])
    authorize! :update,@comment

    @comment.text = p[:text]

    if @comment.save
      c = @comment.attributes
      c[:h] = {
        :created_at => @comment.created_at.getlocal.strftime("%d/%m/%Y %H:%M"),
        :updated_at => @comment.updated_at.getlocal.strftime("%d/%m/%Y %H:%M"),
        :created_by => @comment.user.name
      }
      render json: c
    else
      render json: { :errors => @comment.errors.full_messages }
    end
  end

  # ARCHIVE /comments/1
  # ARCHIVE /comments/1.json
  def archive

    p = params.permit(:id)

    @comment = Comment.find(p[:id])
    authorize! :archive,@comment
    @comment.archived = true
    @comment.archived_by = current_user.id

    if @comment.save
      c = @comment.attributes
      c[:h] = {
        :created_at => @comment.created_at.getlocal.strftime("%d/%m/%Y %H:%M"),
        :updated_at => @comment.updated_at.getlocal.strftime("%d/%m/%Y %H:%M"),
        :created_by => @comment.user.name,
        :archived_by => current_user.name
      }
      render json: c
    else
      render json: { :errors => @comment.errors.full_messages }
    end
  end
end
