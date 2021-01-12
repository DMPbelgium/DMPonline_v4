require 'fileutils'
require 'csv'
require 'file_utils'

def export_org_projects(organisation)

  org_dir = organisation.internal_export_dir

  #base url
  uri_base = organisation.internal_export_url

  #timestamp - start
  file_t = File.join( org_dir, "mdate.txt" )
  now = Time.now
  new_timestamp = now.utc.strftime("%FT%TZ")
  sub_dir = File.join(
    now.utc.strftime("%Y"),
    now.utc.strftime("%m")
  )
  cur_dir = File.join( org_dir, sub_dir )
  old_timestamp = nil

  unless File.directory?(cur_dir)

    FileUtils.mkdir_p(cur_dir)

  end

  if File.exists?(file_t)
    fh = File.open(file_t,"r")
    old_timestamp = fh.readline.chomp
    fh.close()
  end
  #timestamp - end

  #export all projects - start
  begin

    cur_fn = File.join(
      sub_dir,
      "projects_" + new_timestamp + ".json"
    )
    cur_file = File.join(org_dir,cur_fn)
    prev_fn = Dir
      .glob( File.join(org_dir,"*","*","projects_*.json") )
      .map { |f| f.sub(org_dir,"").sub(/^\//,"") }
      .sort
      .last
    links = {
      :self => uri_base + "/" + cur_fn
    }
    if prev_fn.present?

      links[:prev] = uri_base + "/" + prev_fn

    end

    fh_json = File.open(cur_file,"w:UTF-8")

    fh_json.print "{"

    fh_json.print "\"meta\": { \"version\": \"0.1\",\"created_at\": \"#{new_timestamp}\" }"

    fh_json.print ",\"links\": " + links.to_json

    fh_json.print ",\"data\": ["

    i = 0
    prev_i = nil

    projects_ld({ :organisation_id => organisation.id }) do |pr|

      fh_json.print "," unless prev_i.nil?
      fh_json.print pr.to_json
      prev_i = i
      i = i + 1

    end

    fh_json.print "]"
    fh_json.print "}"

    fh_json.close()

    ref_file = File.join( org_dir, "projects.json" )
    File.delete( ref_file ) if File.exists?( ref_file )
    File.symlink( cur_file, ref_file )
    File.utime(now,now,cur_file)
    File.utime(now,now,ref_file)

  end
  #export all projects - end

  #export updated projects - start
  begin

    cur_fn = File.join(
      sub_dir,
      "updated_projects_" + new_timestamp + ".json"
    )
    cur_file = File.join(org_dir,cur_fn)
    prev_fn = Dir
      .glob( File.join(org_dir,"*","*","updated_projects_*.json") )
      .map { |f| f.sub(org_dir,"").sub(/^\//,"") }
      .sort
      .last
    links = {
      :self => uri_base + "/" + cur_fn
    }
    if prev_fn.present?

      links[:prev] = uri_base + "/" + prev_fn

    end

    fh_json = File.open(cur_file,"w:UTF-8")

    fh_json.print "{"

    fh_json.print "\"meta\": { \"version\": \"0.1\",\"created_at\": \"#{new_timestamp}\" }"

    fh_json.print ",\"links\": " + links.to_json

    fh_json.print ",\"data\": ["

    i = 0
    prev_i = nil

    projects_ld({ :organisation_id => organisation.id }) do |pr|

      do_print = old_timestamp.nil? || project_ld_updated?( pr, old_timestamp )

      if do_print

        fh_json.print "," unless prev_i.nil?
        fh_json.print pr.to_json
        prev_i = i
        i = i + 1

      end

    end

    fh_json.print "]"
    fh_json.print "}"

    fh_json.close()

    ref_file = File.join( org_dir, "updated_projects.json" )
    File.delete( ref_file ) if File.exists?( ref_file )
    File.symlink( cur_file, ref_file )
    File.utime(now,now,cur_file)
    File.utime(now,now,ref_file)

  end
  #export updated projects - end

  #export deleted projects - start
  begin

    cur_fn = File.join(
      sub_dir,
      "deleted_projects_" + new_timestamp + ".json"
    )
    cur_file = File.join(org_dir,cur_fn)
    prev_fn = Dir
      .glob( File.join(org_dir,"*","*","deleted_projects_*.json") )
      .map { |f| f.sub(org_dir,"").sub(/^\//,"") }
      .sort
      .last

    links = {
      :self => uri_base + "/" + cur_fn
    }
    if prev_fn.present?

      links[:prev] = uri_base + "/" + prev_fn

    end

    fh_json = File.open(cur_file,"w:UTF_8")

    fh_json.print "{"

    fh_json.print "\"meta\": { \"version\": \"0.1\",\"created_at\": \"#{new_timestamp}\" }"

    fh_json.print ",\"links\": " + links.to_json

    fh_json.print ",\"data\": ["

    i = 0
    prev_i = nil
    Log.where("item_type = ? AND event = ?","Project","destroy").each do |log|

      fh_json.print "," unless prev_i.nil?

      fh_json.print({ :id => log.item_id, :type => "Project", :datetime => log.created_at.utc.strftime("%FT%TZ") }.to_json)

      prev_i = i
      i = i + 1

    end

    fh_json.print "]}"

    fh_json.close()

    ref_file = File.join( org_dir, "deleted_projects.json" )
    File.delete( ref_file ) if File.exists?( ref_file )
    File.symlink( cur_file, ref_file )
    File.utime(now,now,cur_file)
    File.utime(now,now,ref_file)

  end
  #export deleted projects - end

  #timestamp - start
  begin

    fh = File.open(file_t,"w")
    fh.puts(new_timestamp)
    fh.close()

  end
  #timestamp - end

end

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

def projects_ld(conditions = {})

  #prevent n+1 queries
  model_project = Project.includes(
    :organisation,
    { :project_groups => :user },
    { :dmptemplate => :organisation },
    {
      :plans => {
        :version => [
          :phase,
          {
            :sections => [
              :organisation
            ]
          }
        ]
      }
    }
  )

  model_project.find_each(:conditions => conditions,:batch_size => 100) do |project|

    if block_given?
      yield(project.ld)
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
        u.save!
      end
    end
  end

=begin task dmponline:copy_sections

Purpose: copy section from one version to another

Input: CSV on STDIN, having fields of the src_version_id and dest_version_id

=end

  desc "copy sections from src version to dest version"
  task :copy_sections => :environment do |t,args|

    ActiveRecord::Base.transaction do

      csv = CSV.new( $stdin, {
          :headers => true,
          :col_sep => ","
        }
      )

      csv.each do |r|

        row = r.to_hash.slice("src_version_id","dest_version_id")

        src_version   = ::Version.find( Integer( row["src_version_id"] ) )
        dest_version  = ::Version.find( Integer( row["dest_version_id"] ) )

        src_version.global_sections.each do |section|

          section.clone_to(dest_version)

        end

      end

      csv.close()

    end

  end

=begin task dmponline:copy_phase

Purpose: copy phases to other dmptemplates

Input: CSV on STDIN, having fields phase_id and dmptemplate_id
       phase_id is the source phase, dmptemplate_id is the destination dmptemplate

=end

  desc "copy phase"
  task :copy_phase => :environment do |t,args|

    ActiveRecord::Base.transaction do

      csv = CSV.new( $stdin, {
          :headers => true,
          :col_sep => ","
        }
      )

      csv.each do |r|

        row = r.to_hash.slice("phase_id","dmptemplate_id")

        phase = Phase.find( Integer( row["phase_id"] ) )
        dmptemplate = Dmptemplate.find( Integer( row["dmptemplate_id"] ) )

        phase.clone_to( dmptemplate )

      end

      csv.close()

    end

  end

=begin task dmponline:copy_dmptemplate

Reads from STDIN

Each line must be an id of a dmptemplate

Each dmptemplate is duplicated with all of its decendants

=end

  desc "copy dmptemplate"
  task :copy_dmptemplate => :environment do |t,args|

    ActiveRecord::Base.transaction do

      while id = $stdin.gets

        id.chomp!

        t   = Dmptemplate.find(id)
        t2  = t.dup
        t2.title = "Copy of "+t2.title
        t2.published = false

        t2.save!

        Rails.logger.info("[CLONE] COPIED Dmptemplate[#{t.id}] to Dmptemplate[#{t2.id}]")

        t.phases.all.each do |phase|

          phase.clone_to(t2)

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

      desc "export projects for organisations"
      task :projects,[:id] => :environment do |t,args|

        orgs = []

        if args[:id].present?

          orgs = Organisation.where( :id => args[:id] )

        else

          orgs = Organisation.all

        end

        orgs.each do |org|

          export_org_projects(org)

        end

      end

    end

  end

  desc "cleanup lock in table plan_sections"
  task :cleanup_locks => :environment do |t,args|

    count = PlanSection.where("release_time <= ? ",Time.now).delete_all
    puts "removed #{count} records from table plan_sections"

  end

end
