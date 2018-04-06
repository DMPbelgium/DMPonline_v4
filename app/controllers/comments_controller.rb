class CommentsController < ApplicationController
  before_filter :authenticate_user!
  # GET /comments
  # GET /comments.json
#  def index
#    @comments = Comment.all
#    authorize! :index, Comment
#
#    respond_to do |format|
#      format.json { render json: @comments }
#    end
#  end

  # GET /comments/1
  # GET /comments/1.json
  def show
    @comment = Comment.find(params[:id])
    authorize! :show,@comment

    respond_to do |format|
      #format.html # show.html.erb
      format.json { render json: @comment }
    end
  end


  # GET /comments/1/edit
  def edit
    @comment = Comment.find(params[:id])
    authorize! :edit,@comment
  end

  # POST /comments
  # POST /comments.json
  def create

    @comment = Comment.new(params[:new_comment])
    @comment.text = params["#{params[:new_comment][:question_id]}new_comment_text"]
    @comment.question_id = params[:new_comment][:question_id]
    @comment.user_id = params[:new_comment][:user_id]
    @comment.plan_id = params[:new_comment][:plan_id]

    authorize! :create, @comment

    @plan = Plan.find(@comment.plan_id)
    @project = Project.find(@plan.project_id)

    respond_to do |format|
      if @comment.save
        session[:question_id_comments] = @comment.question_id
        format.html { redirect_to edit_project_plan_path(@project, @plan), status: :found, notice: 'Comment was successfully created.' }
        format.json { head :no_content  }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.json
  def update
    @comment = Comment.find(params[:comment][:id])
    authorize! :update,@comment

    @comment.text = params["#{params[:comment][:id]}_comment_text"]

    @plan = Plan.find(@comment.plan_id)
    @project = Project.find(@plan.project_id)

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        session[:question_id_comments] = @comment.question_id
        format.html { redirect_to edit_project_plan_path(@project, @plan), status: :found, notice: 'Comment was successfully updated.' }
        format.json { head :no_content }
      end
    end
  end

  # ARCHIVE /comments/1
  # ARCHIVE /comments/1.json
  def archive
    @comment = Comment.find(params[:comment][:id])
    authorize! :archive,@comment
    @comment.archived = true
    @comment.archived_by = current_user.id

    @plan = Plan.find(@comment.plan_id)
    @project = Project.find(@plan.project_id)

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        session[:question_id_comments] = @comment.question_id
        format.html { redirect_to edit_project_plan_path(@project, @plan), status: :found, notice: 'Comment has been removed.' }
      end
    end
  end
end
