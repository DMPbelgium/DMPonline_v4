class AnswersController < ApplicationController
  before_filter :authenticate_user!
	# POST /answers
	# POST /answers.json
	def create

    p = params.require(:answer)
    plan = Plan.find( p["plan_id"] )
    @answer = plan.answer( p["question_id"], false ) || Answer.new(p)

    authorize! :create,@answer

    @answer.user_id = p["user_id"]
    @answer.option_ids = p["option_ids"]
		@answer.text = params["answer-text-#{@answer.question_id}".to_sym]

    respond_to do |format|
      if @answer.save
        format.html {
          if request.xhr?
            render :text => 'Answer was successfully recorded.'
          else
            redirect_to :back, status: :found, notice: 'Answer was successfully recorded.'
          end
        }
        format.json { render json: @answer, status: :created, location: @answer }
      else
        format.html {
          if request.xhr?
            render :text => 'There was an error saving the answer.'
          else
            redirect_to :back, notice: 'There was an error saving the answer.'
          end
        }
        format.json { render json: @answer.errors, status: :unprocessable_entity }
      end
    end

	end
end
