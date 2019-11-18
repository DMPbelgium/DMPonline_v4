require 'fileutils'
require 'csv'

def exec_cmd(cmd)
  r = system(cmd)
  $stderr.puts cmd
  raise RuntimeError, "cannot execute command '#{cmd}'" if r.nil?
  #raise RuntimeError, "cmd '#{cmd}' exited with failure" unless r
end

def project_ld_updated?(project,date_s)

  if project[:updated_at] >= date_s

    return true

  end

  project[:plans].each do |plan|

    plan[:sections].each do |section|

      section[:questions].each do |question|

        answer = question[:answer]

        if answer.present? && answer[:updated_at] >= date_s

          return true

        end

        question[:comments].each do |comment|

          if comment[:updated_at] >= date_s

            return true

          end

        end

      end

    end

  end

  project[:collaborators].each do |collaborator|

    if collaborator[:updated_at] >= date_s

      return true

    end

  end

  false

end

def projects_ld

  Project.find_each do |project|

    project_url = Rails.application.routes.url_helpers.project_url(project, :host => ENV['DMP_HOST'], :protocol => ENV['DMP_PROTOCOL'])

    pr = {
      :id => project.id,
      :type => "Project",
      :url => project_url,
      :created_at => project.created_at.utc.strftime("%FT%TZ"),
      :updated_at => project.updated_at.utc.strftime("%FT%TZ"),
      :title => project.title,
      :description => project.description,
      :identifier => project.identifier,
      :grant_number => project.grant_number,
      :collaborators => project.project_groups.map { |pg|
        u = pg.user
        pg_r = {
          :type => "ProjectGroup",
          :user => nil,
          :access_level => pg.code_access_level,
          :created_at => pg.created_at.utc.strftime("%FT%TZ"),
          :updated_at => pg.updated_at.utc.strftime("%FT%TZ")
        }
        unless u.nil?

          pg_r[:user] = {
            :id => u.id,
            :created_at => u.created_at.utc.strftime("%FT%TZ"),
            :updated_at => u.updated_at.utc.strftime("%FT%TZ"),
            :email => u.email,
            :orcid => u.orcid_id
          }

        end
        pg_r
      },
      :organisation => nil,
      :plans => []
    }

    if project.organisation.present?

      pr[:organisation] = {
        :type => "Organisation",
        :id => project.organisation.id,
        :name => project.organisation.name
      }

    end

    dmptemplate = project.dmptemplate

    pr[:template] = dmptemplate.attributes
    pr[:template][:type] = "Template"

    funder = project.funder
    funder_name = project.read_attribute(:funder_name)

    if funder

      pr[:funder] = {
        :type => "Organisation",
        :id => funder.id,
        :name => funder.name
      }

    elsif funder_name.present?

      pr[:funder] = {
        :type => nil,
        :id => nil,
        :name => funder_name
      }

    else

      pr[:funder] = nil

    end

    i = 0

    project.plans.each do |plan|

      pl = {
        :version => {
          :type => "Version",
          :id => plan.version.id,
          :title => plan.version.phase.title
        },
        :id => plan.id,
        :type => "Plan",
        :url => project_url + "/plans/" + plan.id.to_s + "/edit",
        :sections => []
      }

      plan.sections.sort_by(&:number).each do |section|

        sc = {
          :id => section.id,
          :type => "Section",
          :number => section.number,
          :title => section.title,
          :questions => []
        }

        section.questions.sort_by(&:number).each do |question|

          qf = question.question_format

          q = {
            :id => question.id,
            :type => "Question",
            :text => question.text,
            :default_value => question.default_value,
            :number => question.number,
            #:guidance => question.guidance,
            :question_format => {
              :id => qf.id,
              :type => "QuestionFormat",
              :title => qf.title,
              :description => qf.description,
              :created_at => qf.created_at.utc.strftime("%FT%TZ"),
              :updated_at => qf.updated_at.utc.strftime("%FT%TZ")
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

          answer    = plan.answer(question.id, false)
          q_format  = question.question_format

          has_options = q_format.title == "Check box" || q_format.title == "Multi select box" ||
              q_format.title == "Radio buttons" || q_format.title == "Dropdown"

          if has_options

            q[:options] = question.options.sort_by(&:number).map do |op|
              {
                :id => op.id,
                :type => "Option",
                :text => op.text,
                :number => op.number,
                :is_default => op.is_default,
                :created_at => op.created_at.utc.strftime("%FT%TZ"),
                :updated_at => op.created_at.utc.strftime("%FT%TZ")
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

            au = answer.user
            q[:answer] = {
              :id => answer.id,
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

          Comment.where("question_id = ? AND plan_id = ?",question.id,plan.id).order(:created_at => :asc).each do |comment|

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

            created_by = comment.user

            if created_by.present?

              c[:created_by] = {
                :id => created_by.id,
                :type => "User",
                :email => created_by.email,
                :orcid => created_by.orcid_id
              }

            end

            archived_by = comment.archived_by.present? ?
              User.where( :id => comment.archived_by ).first : nil

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

      pr[:plans] << pl

      i += 1

    end

    if block_given?
      yield(pr)
    end

  end

end

namespace :dmponline do

  desc "copy user email to shibboleth_id"
  task :user_setup_shibboleth => :environment do |t,args|
    User.transaction do
      users = User.all
      users.each do |u|
        $stderr.puts "setting shibboleth_id to #{u.email.downcase}"
        u.shibboleth_id = u.email.downcase
        u.save
      end
    end
  end

  desc "template duplicate"
  task :template_dup,[:id,:title] => :environment do |t,args|

    t   = Dmptemplate.find(args[:id])
    t2  = t.dup
    t2.title = args[:title]
    t2.published = false
    unless t2.save
      $stderr.puts t2.errors.full_messages.inspect
      exit(1)
    end

    $stdout.puts "new template with id: " + t2.id.to_s + ", title: " + t2.title

    t.phases.all.each do |phase|

      p2 = phase.dup
      t2.phases << p2
      $stderr.puts "  phase #{p2.id.to_s} added to template #{p2.dmptemplate_id.to_s}"

      p2.reload

      phase.versions.all.each do |version|

        version2 = version.dup
        version2.published = false
        p2.versions << version2

        $stderr.puts "    version #{version2.id.to_s} added to phase #{version2.phase_id.to_s}"

        version.sections.all.each do |section|

          section2 = section.dup
          version2.sections << section2

          $stderr.puts "      section #{section2.id.to_s} added to version #{section2.version_id.to_s}"

          section.questions.all.each do |question|

            question2 = question.dup
            section2.questions << question2

            $stderr.puts "        question #{question2.id.to_s} added to section #{question2.section_id.to_s}"

            question.options.all.each do |option|

              option2 = option.dup
              question2.options << option2

              $stderr.puts "          option #{option2.id.to_s} added to question #{option2.question_id.to_s}"

            end

            question.suggested_answers.all.each do |suggested_answer|

              suggested_answer2 = suggested_answer.dup
              question2.suggested_answers << suggested_answer2

              $stderr.puts "          suggested_answer #{suggested_answer2.id.to_s} added to question #{suggested_answer2.question_id.to_s}"

            end

            question2.theme_ids = question.theme_ids

            question2.theme_ids.each do |theme_id|
              $stderr.puts "          assigned existing theme_id #{theme_id.to_s} to question #{question2.id.to_s}"
            end

            question.guidances.all.each do |guidance|

              guidance2 = guidance.dup
              question2.guidances << guidance2
              $stderr.puts "          guidance #{guidance2.id.to_s} added to question #{guidance2.question.id}"

            end

          end

        end

      end

    end

  end

  desc "backup data to git repo"
  task :git_backup => :environment do |t,args|

    raise RuntimeError,"environment variable DMP_DATA_GIT_REPO is not set" if ENV['DMP_DATA_GIT_REPO'].nil?
    raise RuntimeError,"environment variable DMP_DATA_GIT_PATH is not set" if ENV['DMP_DATA_GIT_PATH'].nil?

    git_repo = ENV['DMP_DATA_GIT_REPO']
    git_path = ENV['DMP_DATA_GIT_PATH']

    git_path = !git_path.nil? && !git_path.empty? && File.directory?(git_path) ? git_path : File.join( Rails.root.to_s, "git-data" )

    enter_cmd = "cd #{git_path}"
    clone_cmd = "git clone #{git_repo} #{git_path}"
    add_cmd = "#{enter_cmd} && git add ."
    commit_cmd = "#{enter_cmd} && git commit -m 'changed at #{Time.now}'"
    push_cmd = "#{enter_cmd} && git push origin master"
    clean_cmd = "#{enter_cmd} && (git ls-files | xargs rm -f)"

    unless File.directory?(git_path)
      exec_cmd(clone_cmd)
    end

    #change - start:
    #1) remove all tracked files
    #2) add files
    #=> by combining 1) and 2) we can track deleted guidances

    #1)
    exec_cmd(clean_cmd)

    #2)
    guidance_dir = File.join(git_path,"guidances")
    FileUtils.mkdir_p(guidance_dir) unless File.directory?(guidance_dir)

    Guidance.order(:id).each do |guidance|
      guidance_group = guidance.guidance_groups.first
      theme = guidance.themes.first

      next if guidance_group.nil? || theme.nil?

      file_dir = File.join(
        guidance_dir,
        "guidance_group-#{guidance_group.id}",
        "theme-#{theme.id}"
      )
      filename = File.join(file_dir,guidance.id.to_s+".txt")
      FileUtils.mkdir_p(file_dir) unless File.directory?(file_dir)

      $stderr.puts "writing guidance #{guidance.id} to #{filename}"
      File.open(filename, "w:UTF-8") do |f|
        f.write(guidance.text)
      end
    end

    map_guidance_group = File.join(git_path,"guidance_groups.csv")
    CSV.open(map_guidance_group, "wb", :headers => :first_row) do |csv|
      csv << ["directory","label"]
      GuidanceGroup.order(:id).each do |gg|
        csv << ["guidance_group-#{gg.id}",gg.name]
      end
    end

    map_themes = File.join(git_path,"themes.csv")
    CSV.open(map_themes, "wb", :headers => :first_row) do |csv|
      csv << ["directory","label"]
      Theme.order(:id).each do |t|
        csv << ["theme-#{t.id}",t.title]
      end
    end

    #change - end

    exec_cmd(add_cmd)

    exec_cmd(commit_cmd)

    exec_cmd(push_cmd)

  end

  namespace :export do

    namespace :csv do

      task :log,[:item_type,:event] => :environment do |t,args|

        csv = CSV.new(
          $stdout,{
            :write_headers => true,
            :col_sep => ";",
            :headers => %w(id datetime)
        })

        Log.where("item_type = ? AND event = ?",args[:item_type],args[:event]).each do |log|

          csv << [
            log.item_id,
            log.created_at.utc.strftime("%FT%TZ")
          ]

        end

        csv.close()

      end

      desc "export themes to csv"
      task :themes => :environment do |t,args|

        csv = CSV.new(
          $stdout,{
            :write_headers => true,
            :col_sep => ";",
            :headers => %w(id title description created_at updated_at)
        })

        Theme.find_each do |theme|

          csv << [
            theme.id,
            theme.title,
            theme.description,
            theme.created_at.utc.strftime("%FT%TZ"),
            theme.updated_at.utc.strftime("%FT%TZ")
          ]

        end

        csv.close()

      end

      desc "export questions to csv"
      task :questions => :environment do |t,args|

        csv = CSV.new(
          $stdout,{
            :write_headers => true,
            :col_sep => ";",
            :headers => %w(id text format created_at updated_at theme_ids section phase template)
        })

        Question.find_each do |q|

          row = []
          row << q.id
          row << q.text
          row << q.question_format.title
          row << q.created_at.utc.strftime("%FT%TZ")
          row << q.updated_at.utc.strftime("%FT%TZ")
          row << q.theme_ids.join(" ")
          row << q.section.title
          row << q.section.version.phase.title
          row << q.section.version.phase.dmptemplate.title

          csv << row

        end

        csv.close()

      end

    end

    namespace :json do

      desc "export projects"
      task :projects => :environment do |t,args|

        projects_ld do |pr|
          puts pr.to_json
        end

      end

      desc "export updated projects"
      task :updated_projects => :environment do |t,args|

        file = "tmp/projects_last_exported.txt"

        new_timestamp = DateTime.now.utc.strftime("%FT%TZ")
        old_timestamp = nil

        if File.exists?(file)

          fh = File.open(file,"r")
          old_timestamp = fh.readline.chomp
          fh.close()

        end

        projects_ld do |pr|

          if old_timestamp.nil?

            puts pr.to_json

          elsif project_ld_updated?( pr, old_timestamp )

            puts pr.to_json

          end

        end

        fh = File.open(file,"w")
        fh.puts(new_timestamp)
        fh.close()

      end

    end

  end

end
