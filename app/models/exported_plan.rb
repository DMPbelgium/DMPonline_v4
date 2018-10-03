class ExportedPlan < ActiveRecord::Base
  attr_accessible :plan_id, :user_id, :format

  #associations between tables
  belongs_to :plan, :autosave => true
  belongs_to :user, :autosave => true

  VALID_FORMATS = %i(pdf text docx)

  validates :format, inclusion: { in: VALID_FORMATS, message: '%{value} is not a valid format' }

  # Store settings with the exported plan so it can be recreated later
  # if necessary (otherwise the settings associated with the plan at a
  # given time can be lost)
  has_settings :export, class_name: 'Settings::Dmptemplate' do |s|
    s.key :export, defaults: Settings::Dmptemplate::DEFAULT_SETTINGS
  end

  # Getters to match Settings::Dmptemplate::VALID_ADMIN_FIELDS
  def project_name
    name = self.plan.project.title
    name += " - #{self.plan.title}" if self.plan.project.dmptemplate.phases.count > 1
    name
  end

  def project_identifier
    self.plan.project.identifier
  end

  def grant_title
    self.plan.project.grant_number
  end

  def principal_investigator
    self.plan.project.principal_investigator
  end

  def project_data_contact
    self.plan.project.data_contact
  end

  def project_description
    self.plan.project.description
  end

  def project_gdpr
    self.plan.project.gdpr
  end

  def funder
    org = self.plan.project.dmptemplate.try(:organisation)
    org.name if org.present? && org.organisation_type.try(:name) == I18n.t('helpers.org_type.funder')
  end

  def institution
    plan.project.organisation.try(:name)
  end

  # sections taken from fields settings
  def sections
    sections = self.plan.sections

    return [] if questions.empty?

    section_ids = questions.pluck(:section_id).uniq
    sections = sections.select {|section| section_ids.member?(section.id) }

    sections.sort_by(&:number)
  end

  def questions_for_section(section_id)
    questions.where(section_id: section_id)
  end

  def admin_details
    @admin_details ||= self.settings(:export).fields[:admin]
  end

  # Export formats

  def as_csv
    CSV.generate do |csv|
      csv << ["Section","Question","Answer","Selected option(s)","Answered by","Answered at"]
      self.sections.each do |section|
        self.questions_for_section(section).each do |question|
          answer = self.plan.answer(question.id)
          options_string = answer.options.collect {|o| o.text}.join('; ')

          csv << [section.title, question.text, sanitize_text(answer.text), options_string, answer.try(:user).try(:name), answer.created_at]
        end
      end
    end
  end

  def as_txt
    output = "#{self.plan.project.try(:title)}\n\n#{self.plan.title}\n"

    if self.admin_details.present?
        f = "Admin details"
        output += "\n"+f+":\n"
        output += "=" * f.length
        output += "\n"
        self.admin_details.each do |field|
            value = self.send(field)
            label = "helpers.plan.export.#{field}"
            if value.present?
              output += "#{I18n.t(label)}: #{value}\n"
            end
        end
    end

    if self.sections.present?
      f = "Sections"
      output += "\n"+f+":\n"
      output += "=" * f.length
      output += "\n"
      self.sections.each do |section|
        output += "\n#{section.title}\n"
        output += "-" * section.title.length
        output += "\n"

        self.questions_for_section(section).each do |question|
          output += "\n#{question.text}\n"
          answer = self.plan.answer(question.id, false)

          if answer.nil? || answer.text.nil? then
            output += "\nQuestion not answered.\n"
          else
            opts = answer.options.collect {|o| o.text}
            output += opts.size() > 0 ? opts.join("\n") + "\n" : ""
            output += "\n#{sanitize_text(answer.text)}\n"
          end
        end
      end
    end

    output
  end

  def html_for_docx
    docx_html_source = %q(<!doctype html><html><head>)
    docx_html_source << %q(
      <style type="text/css">
      a.orcid-link {
        text-decoration: none !important;
        color: #338caf !important;
        font-family: 'Noto Sans',sans-serif !important;
        font-style: normal !important;
      }
      a.orcid-link:hover, a.orcid-link:active, a.orcid-link:focus, a.orcid-link:visited {
        outline: 0 !important;
        text-decoration: none !important;
        font-family: 'Noto Sans',sans-serif !important;
        font-style: normal !important;
        color: #a6ce39 !important;
      }
      img {
        max-width: 100%;
        width: auto;
        height: auto;
        vertical-align: middle;
        border: 0;
      }
      </style>
    )
    docx_html_source << "</head><body><div><h1>#{self.plan.project.try(:title)}</h1><h2>#{self.plan.title}</h2>"
    if self.admin_details.present?
        docx_html_source << "<div><h3>Admin Details</h3>"
        self.admin_details.each do |field|
            value = self.send(field)
            label = "helpers.plan.export.#{field}"
            if value.present?
                docx_html_source << "<p><strong>#{I18n.t(label)}:</strong> #{value}</p>"
            end
        end
        docx_html_source << "</div>"
    end
    self.sections.each do |section|
        docx_html_source << "<div><h3>#{section.title}</h3>"

        self.questions_for_section(section.id).each do |question|

            docx_html_source << "<div><h4>#{question.text}</h4>"
            answer = self.plan.answer(question.id, false)
            if answer.nil?
                docx_html_source << "<p>Question not answered.</p>"
            else
                q_format = question.question_format
                if q_format.title == I18n.t("helpers.checkbox") || q_format.title == I18n.t("helpers.multi_select_box") ||
                   q_format.title == I18n.t("helpers.radio_buttons") || q_format.title == I18n.t("helpers.dropdown") then
                    answer.options.each do |option|
                        if !option.text.nil?
                            docx_html_source << "<p>- #{option.text}</p>"
                        end
                    end
                end

            if !answer.text.nil?
                docx_html_source << answer.text
            end
        end
        docx_html_source << "</div>"
      end
      docx_html_source << "</div>"
    end
    docx_html_source << "</div><body></html>"
  end

private

  def questions
    @questions ||= begin
      question_settings = self.settings(:export).fields[:questions]

      return [] if question_settings.is_a?(Array) && question_settings.empty?

      questions = if question_settings.present? && question_settings != :all
        Question.where(id: question_settings)
      else
        Question.where(section_id: self.plan.sections.collect {|s| s.id })
      end

      questions.order(:number)
    end
  end

  def sanitize_text(text)
    if (!text.nil?) then ActionView::Base.full_sanitizer.sanitize(text.gsub(/&nbsp;/i,"")) end
  end

end
