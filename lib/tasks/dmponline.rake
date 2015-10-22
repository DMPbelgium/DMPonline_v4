require 'fileutils'

def exec_cmd(cmd)
  r = system(cmd)
  raise RuntimeError, "cannot execute command '#{cmd}'" if r.nil?
  #raise RuntimeError, "cmd '#{cmd}' exited with failure" unless r
end

namespace :dmponline do

  desc "backup data to git repo"
  task :git_backup => :environment do |t,args|

    git_repo = ENV['DMP_DATA_GIT_REPO']
    git_path = ENV['DMP_DATA_GIT_PATH']
    git_path = !git_path.nil? && !git_path.empty? && File.directory?(git_path) ? git_path : File.join( Rails.root.to_s, "git-data" )

    enter_cmd = "cd #{git_path}"
    clone_cmd = "git clone #{git_repo} #{git_path}"
    add_cmd = "git add ."
    commit_cmd = "git commit -m 'changed at #{Time.now}'"
    push_cmd = "git push origin master"

    unless File.directory?(git_path)
      exec_cmd(clone_cmd)
    end

    exec_cmd(enter_cmd)

    #change - start
    guidance_dir = File.join(git_path,"guidances")
    unless File.directory?(guidance_dir)
      FileUtils.mkdir_p(guidance_dir)
      Guidance.all.each do |guidance|
        filename = File.join(guidance_dir,guidance.id.to_s+".txt")
        $stderr.puts "writing guidance #{guidance.id} to #{filename}"
        File.open(filename, "w:UTF-8") do |f|
          f.write(guidance.text)
        end
      end
    end

    #change - end

    exec_cmd(add_cmd)

    exec_cmd(commit_cmd)

    exec_cmd(push_cmd)

  end

end
