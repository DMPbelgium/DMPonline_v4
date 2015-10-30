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
