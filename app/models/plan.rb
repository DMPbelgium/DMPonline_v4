class Plan < ActiveRecord::Base

	attr_accessible :locked, :project_id, :version_id, :version, :plan_sections

	A4_PAGE_HEIGHT = 297 #(in mm)
	A4_PAGE_WIDTH = 210 #(in mm)
	ROUNDING = 5 #round estimate up to nearest 5%
	FONT_HEIGHT_CONVERSION_FACTOR = 0.35278 #convert font point size to mm
	FONT_WIDTH_HEIGHT_RATIO = 0.4 #Assume glyph width averages 2/5 the height

	#associations between tables
	belongs_to :project, :inverse_of => :plans, :autosave => true
	belongs_to :version, :inverse_of => :plans, :autosave => true
	has_many :answers, :inverse_of => :plan, :dependent => :destroy, :order => "created_at DESC"
  has_many :comments, :inverse_of => :plan, :dependent => :destroy, :order => "created_at DESC"
	has_many :plan_sections, :inverse_of => :plan, :dependent => :destroy
	accepts_nested_attributes_for :project
	accepts_nested_attributes_for :answers
	accepts_nested_attributes_for :version

	has_settings :export, class_name: 'Settings::Dmptemplate' do |s|
		s.key :export, defaults: Settings::Dmptemplate::DEFAULT_SETTINGS
	end

	alias_method :super_settings, :settings

	# Proxy through to the template settings (or defaults if this plan doesn't have
	# an associated template) if there are no settings stored for this plan.
	# `key` is required by rails-settings, so it's required here, too.
	def settings(key)
		self_settings = self.super_settings(key)
		return self_settings if self_settings.value?

		self.dmptemplate.settings(key)
	end

	def dmptemplate
		self.project.try(:dmptemplate) || Dmptemplate.new
	end

	def title
		if self.settings(:export).title.blank?
      if !self.version.nil? && !self.version.phase.nil? && self.version.phase.title.present?
          return self.version.phase.title
      else
          return ""
			end
		else
			return self.settings(:export).title
		end
	end

	def answer(qid, create_if_missing = true)
  	answer = answers
      .select {|a| a.question_id == qid }
      .sort {|a,b| b.created_at <=> a.created_at }
      .first()
		if answer.nil? && create_if_missing then
  		question = Question.find(qid)
			answer = Answer.new
			answer.plan_id = id
			answer.question_id = qid
			answer.text = question.default_value
			default_options = Array.new
			question.options.each do |option|
				if option.is_default
					default_options << option
				end
			end
			answer.options = default_options
		end
		return answer
	end

  def default_answer(question)

    a = Answer.new
    a.plan_id = self.id
    a.question_id = question.id
    a.text = question.default_value
    default_options = Array.new
    question.options.each do |option|
      if option.is_default
        default_options << option
      end
    end
    a.options = default_options

    return a

  end

	def sections
		unless project.organisation.nil? then
			sections = version.global_sections + project.organisation.all_sections(version_id)
		else
			sections = version.global_sections
		end
		sections.uniq.sort_by &:number
	end

	def guidance_for_question(question)
		guidances = {}
		# If project org isn't nil, get guidance by theme from any "non-subset" groups belonging to project org
		unless project.organisation.nil? then
			project.organisation.guidance_groups.each do |group|
				if !group.optional_subset && (group.dmptemplates.map(&:id).include?(project.dmptemplate_id) || group.dmptemplates.size == 0) then
					group.guidances.each do |guidance|
						guidance.themes.select {|t| question.theme_ids.include?(t.id) }.each do |theme|
							guidances = self.add_guidance_to_array(guidances, group, theme, guidance)
						end
					end
				end
			end
		end
		# Get guidance by theme from any guidance groups selected on creation
		project.guidance_groups.each do |group|
			if group.dmptemplates.map(&:id).include?(project.dmptemplate_id) || group.dmptemplates.size == 0 then
				group.guidances.each do |guidance|
					guidance.themes.select {|t| question.theme_ids.include?(t.id) }.each do |theme|
						guidances = self.add_guidance_to_array(guidances, group, theme, guidance)
					end
				end
			end
		end
		# Get guidance by question where guidance group was selected on creation or if group is organisation default
		question.guidances.each do |guidance|
			guidance.guidance_groups.each do |group|
				if (group.organisation == project.organisation && !group.optional_subset) || project.guidance_groups.include?(group) then
					guidances = self.add_guidance_to_array(guidances, group, nil, guidance)
				end
			end
		end
		return guidances
	end

	def add_guidance_to_array(guidance_array, guidance_group, theme, guidance)

		if guidance_array[guidance_group].nil? then
			guidance_array[guidance_group] = {}
		end
		if theme.nil? then
			if guidance_array[guidance_group]["no_theme"].nil? then
				guidance_array[guidance_group]["no_theme"] = []
			end
			if !guidance_array[guidance_group]["no_theme"].include?(guidance) then
				guidance_array[guidance_group]["no_theme"].push(guidance)
			end
		else
			if guidance_array[guidance_group][theme].nil? then
				guidance_array[guidance_group][theme] = []
			end
			if !guidance_array[guidance_group][theme].include?(guidance) then
				guidance_array[guidance_group][theme].push(guidance)
			end
		end

        return guidance_array
	end

	def warning(option_id)
		if project.organisation.nil?
			return nil
		else
			return project.organisation.warning(option_id)
		end
	end

	def editable_by(user_id)
		return project.editable_by(user_id)
	end

	def readable_by(user_id)
		if project.nil?
			return false
		else
			return project.readable_by(user_id)
		end
	end

	def administerable_by(user_id)
		return project.readable_by(user_id)
	end

	def status
		status = {
			"num_questions" => 0,
			"num_answers" => 0,
			"sections" => {},
			"questions" => {},
			"space_used" => 0 # percentage of available space in pdf used
		}

		space_used = height_of_text(self.project.title, 2, 2)

		sections.each do |s|
			space_used += height_of_text(s.title, 1, 1)
			section_questions = 0
			section_answers = 0
			status["sections"][s.id] = {}
			status["sections"][s.id]["questions"] = Array.new
			s.questions.each do |q|
				status["num_questions"] += 1
				section_questions += 1
				status["sections"][s.id]["questions"] << q.id
				status["questions"][q.id] = {}
				answer = answer(q.id, false)

				space_used += height_of_text(q.text) unless q.text == s.title
				space_used += height_of_text(answer.try(:text) || I18n.t('helpers.plan.export.pdf.question_not_answered'))

				if ! answer.nil? then
					status["questions"][q.id] = {
						"answer_id" => answer.id,
						"answer_created_at" => answer.created_at.to_i,
            "answer_updated_at" => answer.updated_at.to_i,
						"answer_text" => answer.text,
						"answer_option_ids" => answer.option_ids,
						"answered_by" => answer.user.name
					}
                    q_format = q.question_format
					status["num_answers"] += 1 if (q_format.title == I18n.t("helpers.checkbox") || q_format.title == I18n.t("helpers.multi_select_box") ||
                                        q_format.title == I18n.t("helpers.radio_buttons") || q_format.title == I18n.t("helpers.dropdown")) || answer.text.present?
					section_answers += 1
					#TODO: include selected options in space estimate
				else
					status["questions"][q.id] = {
						"answer_id" => nil,
						"answer_created_at" => nil,
						"answer_text" => nil,
						"answer_option_ids" => nil,
						"answered_by" => nil
					}
				end
 				status["sections"][s.id]["num_questions"] = section_questions
 				status["sections"][s.id]["num_answers"] = section_answers
			end
		end

		status['space_used'] = estimate_space_used(space_used)
		return status
	end

	def details
		details = {
			"project_title" => project.title,
			"phase_title" => version.phase.title,
			"sections" => {}
		}
		sections.sort_by(&:"number").each do |s|
			details["sections"][s.number] = {}
			details["sections"][s.number]["title"] = s.title
			details["sections"][s.number]["questions"] = {}
			s.questions.order("number").each do |q|
				details["sections"][s.number]["questions"][q.number] = {}
				details["sections"][s.number]["questions"][q.number]["question_text"] = q.text
				answer = answer(q.id, false)
				if ! answer.nil? then
                    q_format = q.question_format
					if (q_format.title == t("helpers.checkbox") || q_format.title == t("helpers.multi_select_box") ||
                                        q_format.title == t("helpers.radio_buttons") || q_format.title == t("helpers.dropdown")) then
						details["sections"][s.number]["questions"][q.number]["selections"] = {}
						answer.options.each do |o|
							details["sections"][s.number]["questions"][q.number]["selections"][o.number] = o.text
						end
					end
					details["sections"][s.number]["questions"][q.number]["answer_text"] = answer.text
				end
			end
		end
		return details
	end

#	def locked(section_id, user_id)
#		plan_section = plan_sections.where("section_id = ? AND user_id != ? AND release_time > ?", section_id, user_id, Time.now).last
#		if plan_section.nil? then
#			status = {
#				"locked" => false,
#				"locked_by" => nil,
#				"timestamp" => nil,
#				"id" => nil
#			}
#		else
#			status = {
#				"locked" => true,
#				"locked_by" => plan_section.user.name,
#				"timestamp" => plan_section.updated_at,
#				"id" => plan_section.id
#			}
#		end
#	end

	def lock_all_sections(user_id)
		sections.each do |s|
			lock_section(s.id, user_id, 1800)
		end
	end

	def unlock_all_sections(user_id)
		plan_sections.where(:user_id => user_id).delete_all
	end

	def delete_recent_locks(user_id)
		plan_sections.where(:user_id => user_id).delete_all
	end

	def lock_section(section_id, user_id, release_time = 60)

    #is there a live lock on this section?
    old_plan_section = plan_sections.where(
      "section_id = ? AND release_time > ?", section_id, Time.now
    ).order("updated_at DESC").first

    st = {}

    #found own lock
    if old_plan_section.present? && old_plan_section.user_id == user_id

      old_plan_section.release_time = Time.now + release_time.seconds
      old_plan_section.save!

      st[:status] = "ok"
      st[:timestamp] = old_plan_section.updated_at
      st[:id] = old_plan_section.id

    #found others lock
    elsif old_plan_section.present?

      st[:status] = "error"
      st[:locked_by] = old_plan_section.user.name
      st[:timestamp] = old_plan_section.updated_at
      st[:id] = old_plan_section.id

    #found no lock
    else

      new_plan_section = PlanSection.new(
        :plan_id => id,
        :section_id => section_id,
        :release_time => Time.now + release_time.seconds,
        :user_id => user_id
      )

      if new_plan_section.save!

        st[:status] = "ok"
        st[:timestamp] = new_plan_section.updated_at
        st[:id] = new_plan_section.id

      else

        st[:status] = "error"

      end

    end

    return st

	end

	def unlock_section(section_id, user_id)
		plan_sections.where(:section_id => section_id, :user_id => user_id).delete_all
	end

	def latest_update
		if answers.any? then
			last_answered = answers.sort {|a,b| a.updated_at <=> b.updated_at }.last.updated_at
			if last_answered > updated_at then
				return last_answered
			else
				return updated_at
			end
		else
			return updated_at
		end
	end

	def section_answers(section_id)
		section = Section.find(section_id)
 		section_questions = Array.new
 		counter = 0
 		section.questions.each do |q|
 			section_questions[counter] = {}
 			section_questions[counter]["id"] = q.id
 			#section_questions[counter]["multiple_choice"] = q.multiple_choice
 			q_answer = answer(q.id, false)
 			if q_answer.nil? then
 				section_questions[counter]["answer_id"] = nil
 				if q.suggested_answers.find_by_organisation_id(project.organisation_id).nil? then
 					section_questions[counter]["answer_text"] = ""
 				else
 					section_questions[counter]["answer_text"] = q.default_value
 				end
 				section_questions[counter]["answer_timestamp"] = nil
 				section_questions[counter]["answer_options"] = Array.new
 			else
 				section_questions[counter]["answer_id"] = q_answer.id
 				section_questions[counter]["answer_text"] = q_answer.text
 				section_questions[counter]["answer_timestamp"] = q_answer.created_at
 				section_questions[counter]["answer_options"] = q_answer.options.pluck(:id)
 			end
 			counter = counter + 1
 		end
 		return section_questions
	end

  def ld_uri

    self.project.ld_uri + "/plans/" + self.id.to_s + "/edit"

  end

  def ld

    pl = {
      :version => {
        :type => "Version",
        :id => self.version.id,
        :title => self.version.phase.title
      },
      :id => self.id,
      :type => "Plan",
      :url => self.ld_uri,
      :sections => []
    }

    #preload plan related records - start
    plan_answers = self.answers.all.sort { |a,b| b.created_at <=> a.created_at }
    plan_comments = self.comments.all.sort { |a,b| a.created_at <=> b.created_at }

    plan_user_ids = []
    plan_user_ids += plan_comments.map { |c| c.archived_by }.select { |i| !i.nil? }
    plan_user_ids += plan_comments.map { |c| c.user_id }.select { |i| !i.nil? }
    plan_user_ids += plan_answers.map {|a| a.user_id }.select { |i| !i.nil? }
    plan_user_ids.uniq!

    plan_users = plan_user_ids.size > 0 ?
      User.where( :id => plan_user_ids ).all : []
    #preload plan related records - end

    #preload question formats
    question_formats = QuestionFormat.all

    #we have to specify this again as plan.sections returns an array!
    model_question = Question.includes(
      :suggested_answers,
      { :options => :themes },
      :guidances,
      :themes
    )

    self.sections.each do |section|

      sc = {
        :id => section.id,
        :type => "Section",
        :number => section.number,
        :title => section.title,
        :questions => []
      }
  
      model_question
        .where( :section_id => section.id )
        .order("number ASC")
        .each do |question|

        question_format = question_formats.select { |qf| qf.id == question.question_format_id }.first

        q = {
          :id => question.id,
          :type => "Question",
          :text => question.text,
          :default_value => question.default_value,
          :number => question.number,
          :question_format => {
            :id => question_format.id,
            :type => "QuestionFormat",
            :title => question_format.title,
            :description => question_format.description,
            :created_at => question_format.created_at.utc.strftime("%FT%TZ"),
            :updated_at => question_format.updated_at.utc.strftime("%FT%TZ")
          },
          :suggested_answers => question.suggested_answers.map { |sa|
            {
              :id => sa.id,
              :type => "SuggestedAnswer",
              :text => sa.text,
              :is_example => sa.is_example,
              :created_at => sa.created_at.utc.strftime("%FT%TZ"),
              :updated_at => sa.created_at.utc.strftime("%FT%TZ")
            }
          }.select { |sa| sa[:text].present? },
          :answer => nil,
          :themes => question.themes.map { |theme|
            {
              :id => theme.id,
              :type => "Theme",
              :title => theme.title,
              :created_at => theme.created_at.utc.strftime("%FT%TZ"),
              :updated_at => theme.updated_at.utc.strftime("%FT%TZ")
            }
          }
        }

        answer = plan_answers.find { |a| a.question_id == question.id }

        has_options = question_format.title == "Check box" || question_format.title == "Multi select box" ||
            question_format.title == "Radio buttons" || question_format.title == "Dropdown"

        if has_options

          q[:options] = question.options.sort_by(&:number).map do |op|
            {
              :id => op.id,
              :type => "Option",
              :text => op.text,
              :number => op.number,
              :is_default => op.is_default,
              :created_at => op.created_at.utc.strftime("%FT%TZ"),
              :updated_at => op.created_at.utc.strftime("%FT%TZ"),
              :themes => op.themes.map { |theme|
                {
                  :id => theme.id,
                  :type => "Theme",
                  :title => theme.title,
                  :created_at => theme.created_at.utc.strftime("%FT%TZ"),
                  :updated_at => theme.updated_at.utc.strftime("%FT%TZ")
                }
              }
            }
          end

        end


        if answer.present? && has_options

          q[:selected] = {}

          answer.options.each do |o|

            q[:selected][o.number] = o.text

          end

        end

        if answer.present?

          au = plan_users.find {|u| u.id == answer.user_id }
          q[:answer] = {
            :id => answer.id,
            :type => "Answer",
            :text => answer.text,
            :user => nil,
            :created_at => answer.created_at.utc.strftime("%FT%TZ"),
            :updated_at => answer.updated_at.utc.strftime("%FT%TZ")
          }
          unless au.nil?

            q[:answer][:user] = {
              :id => au.id,
              :type => "User",
              :email => au.email,
              :orcid => au.orcid_id
            }

          end

        end

        q[:comments] = []

        plan_comments.select { |comment| comment.question_id == question.id }.each do |comment|

          c = {
            :id => comment.id,
            :type => "Comment",
            :created_at => comment.created_at.utc.strftime("%FT%TZ"),
            :updated_at => comment.updated_at.utc.strftime("%FT%TZ"),
            :text => comment.text,
            :created_by => nil,
            :archived_by => nil,
            :archived => comment.archived ? true : false
          }

          created_by = plan_users.find {|u| u.id == comment.user_id }

          if created_by.present?

            c[:created_by] = {
              :id => created_by.id,
              :type => "User",
              :email => created_by.email,
              :orcid => created_by.orcid_id
            }

          end

          archived_by = plan_users.find { |u| u.id == comment.archived_by }

          if archived_by.present?

            c[:archived_by] = {
              :id => archived_by.id,
              :type => "User",
              :email => archived_by.email,
              :orcid => archived_by.orcid_id
            }

          end

          q[:comments] << c

        end

        sc[:questions] << q

      end

      pl[:sections] << sc

    end

    pl

  end

private

	# Based on the height of the text gathered so far and the available vertical
	# space of the pdf, estimate a percentage of how much space has been used.
	# This is highly dependent on the layout in the pdf. A more accurate approach
	# would be to render the pdf and check how much space had been used, but that
	# could be very slow.
	# NOTE: This is only an estimate, rounded up to the nearest 5%; it is intended
	# for guidance when editing plan data, not to be 100% accurate.
	def estimate_space_used(used_height)
		@formatting ||= self.settings(:export).formatting

		return 0 unless @formatting[:font_size] > 0

		margin_height    = @formatting[:margin][:top].to_i + @formatting[:margin][:bottom].to_i
		page_height      = A4_PAGE_HEIGHT - margin_height # 297mm for A4 portrait
		available_height = page_height * self.dmptemplate.settings(:export).max_pages

		percentage = (used_height / available_height) * 100
		(percentage / ROUNDING).ceil * ROUNDING # round up to nearest five
	end

	# Take a guess at the vertical height (in mm) of the given text based on the
	# font-size and left/right margins stored in the plan's settings.
	# This assumes a fixed-width for each glyph, which is obviously
	# incorrect for the font-face choices available; the idea is that
	# they'll hopefully average out to that in the long-run.
	# Allows for hinting different font sizes (offset from base via font_size_inc)
	# and vertical margins (i.e. for heading text)
	def height_of_text(text, font_size_inc = 0, vertical_margin = 0)
		@formatting     ||= self.settings(:export).formatting
		@margin_width   ||= @formatting[:margin][:left].to_i + @formatting[:margin][:right].to_i
		@base_font_size ||= @formatting[:font_size]

		return 0 unless @base_font_size > 0

		font_height = FONT_HEIGHT_CONVERSION_FACTOR * (@base_font_size + font_size_inc)
		font_width  = font_height * FONT_WIDTH_HEIGHT_RATIO # Assume glyph width averages at 2/5s the height
		leading     = font_height / 2

		chars_in_line = (A4_PAGE_WIDTH - @margin_width) / font_width # 210mm for A4 portrait
		num_lines = (text.length / chars_in_line).ceil

		(num_lines * font_height) + vertical_margin + leading
	end

end
