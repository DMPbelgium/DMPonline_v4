require 'fileutils'
require 'csv'

def exec_cmd(cmd)
  r = system(cmd)
  $stderr.puts cmd
  raise RuntimeError, "cannot execute command '#{cmd}'" if r.nil?
  #raise RuntimeError, "cmd '#{cmd}' exited with failure" unless r
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

            question2.guidance_ids = question.guidance_ids

            question2.guidance_ids.each do |guidance_id|
              $stderr.puts "          assigned existing guidance_id #{guidance_id.to_s} to question #{question2.id.to_s}"
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

end
