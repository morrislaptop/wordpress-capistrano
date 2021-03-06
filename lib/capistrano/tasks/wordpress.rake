namespace :wordpress do

  namespace :db do
    desc "Pull the remote database"
    task :pull do

      on roles(:db) do
        within release_path do
          with path: "#{fetch(:path)}:$PATH" do
            execute :wp, "--path=#{fetch(:wp_path)} db export #{fetch(:tmp_dir)}/database.sql"
            execute :gzip, "-f #{fetch(:tmp_dir)}/database.sql"
          end
        end

        download! "#{fetch(:tmp_dir)}/database.sql.gz", "database.sql.gz"

        run_locally do
          timestamp = "#{Time.now.year}-#{Time.now.month}-#{Time.now.day}-#{Time.now.hour}-#{Time.now.min}-#{Time.now.sec}"
          
          execute :wp, "--path=#{fetch(:wp_path)} db export #{fetch(:application)}.#{timestamp}.sql" # backup
          
          execute :gunzip, "-f database.sql.gz"
          execute :wp, "--path=#{fetch(:wp_path)} db import database.sql"
          execute :wp, "--path=#{fetch(:wp_path)} search-replace #{fetch(:url)} #{fetch(:local_url)}"
          
          execute :rm, "database.sql.gz", raise_on_non_zero_exit: false
          execute :rm, "database.sql", raise_on_non_zero_exit: false
          
          execute :wp, "--path=#{fetch(:wp_path)}", :option, :delete, :template_root, raise_on_non_zero_exit: false
          execute :wp, "--path=#{fetch(:wp_path)}", :option, :delete, :stylesheet_root, raise_on_non_zero_exit: false
        end

        execute :rm, "#{fetch(:tmp_dir)}/database.sql", raise_on_non_zero_exit: false
        execute :rm, "#{fetch(:tmp_dir)}/database.sql.gz", raise_on_non_zero_exit: false
      end

    end

    # @todo GZIP
    desc "Push the local database"
    task :push do
      on roles(:db) do

        run_locally do
          execute :wp, "--path=#{fetch(:wp_path)} db export database.sql"
          execute :gzip, "-f database.sql"
        end

        upload! "database.sql.gz", "#{fetch(:tmp_dir)}/database.sql.gz" 

        run_locally do
          execute :rm, "database.sql", raise_on_non_zero_exit: false
          execute :rm, "database.sql.gz", raise_on_non_zero_exit: false
        end

        within release_path do
          with path: "#{fetch(:path)}:$PATH" do
            timestamp = "#{Time.now.year}-#{Time.now.month}-#{Time.now.day}-#{Time.now.hour}-#{Time.now.min}-#{Time.now.sec}"
            
            execute :wp, "--path=#{fetch(:wp_path)} db export #{fetch(:application)}.#{timestamp}.sql" # backup
            
            execute :gunzip, "-f #{fetch(:tmp_dir)}/database.sql.gz"
            
            execute :wp, "--path=#{fetch(:wp_path)} db import #{fetch(:tmp_dir)}/database.sql"
            execute :wp, "--path=#{fetch(:wp_path)} search-replace #{fetch(:local_url)} #{fetch(:url)}"
            
            execute :rm, "#{fetch(:tmp_dir)}/database.sql", raise_on_non_zero_exit: false
            execute :rm, "#{fetch(:tmp_dir)}/database.sql.gz", raise_on_non_zero_exit: false
            
            invoke 'wordpress:paths'
            
            execute :echo, %{"Database imported at #{timestamp}" >> #{revision_log}}
          end
        end

      end
    end

    # Database name locally must match the :application variable in capistrano
    # @todo gzip
    desc "Push the database in version control"
    task :deploy do

      on roles(:db) do

        upload! "#{fetch(:application)}.sql", "#{fetch(:tmp_dir)}/database.sql"

        within release_path do
          with path: "#{fetch(:path)}:$PATH" do
            timestamp = "#{Time.now.year}-#{Time.now.month}-#{Time.now.day}-#{Time.now.hour}-#{Time.now.min}-#{Time.now.sec}"
            execute :wp, "--path=#{fetch(:wp_path)} db export #{fetch(:application)}.#{timestamp}.sql"
            execute :wp, "--path=#{fetch(:wp_path)} db import #{fetch(:tmp_dir)}/database.sql"
            execute :wp, "--path=#{fetch(:wp_path)} search-replace #{fetch(:local_url)} #{fetch(:url)}"
            execute :rm, "#{fetch(:tmp_dir)}/database.sql"
            invoke 'wordpress:paths'
            execute :echo, %{"Database imported at #{timestamp}" >> #{revision_log}}
          end
        end

      end

    end
  end

  namespace :uploads do

    desc "Synchronise local and remote wp-content/uploads folders"
    task :sync do
      invoke 'pull'
      invoke 'push'
    end

    desc "Pull remote wp-content/uploads folder"
    task :pull do
      run_locally do
        roles(:web).each do |role|
          user = role.user + "@" if !role.user.nil?
          execute :rsync, "-avzO #{user}#{role.hostname}:#{release_path}/#{fetch(:wp_uploads)}/ #{fetch(:wp_uploads)}"
        end
      end
    end

    desc "Push local wp-content folder to remote wp-content/uploads folder"
    task :push do
      run_locally do
        roles(:web).each do |role|
          user = role.user + "@" if !role.user.nil?
          execute :rsync, "-avzO #{fetch(:wp_uploads)}/ #{user}#{role.hostname}:#{release_path}/#{fetch(:wp_uploads)}"
        end
      end
    end

  end

  namespace :content do
    desc "Synchronise local and remote wp-content/uploads folders"
    task :sync do
      invoke 'uploads:sync'
    end
  end

  desc "Update WordPress template root paths to point to the new release"
  task :paths do

    on roles(:db) do
      within release_path do
        with path: "#{fetch(:path)}:$PATH" do
          if test :wp, :core, 'is-installed'

            releases = capture("ls #{File.join(fetch(:deploy_to), 'releases')}")
            last_release = File.join(releases_path, releases.split("\n").sort.last, fetch(:wp_themes))

            [:stylesheet_root, :template_root].each do |option|
              # Only change the value if it's an absolute path
              # i.e. The relative path "/themes" must remain unchanged
              # Also, the option might not be set, in which case we leave it like that
              value = capture :wp, :option, :get, option, raise_on_non_zero_exit: false
              if value != '' && value != '/themes'
                execute :wp, "--path=#{fetch(:wp_path)}", :option, :set, option, last_release
              end
            end

          end
        end
      end
    end
  end

end

def set_option_path

end

namespace :load do
  task :defaults do
    set :url, 'www.wordpress.org'
    set :local_url, 'localhost'
    set :wp_path, '.'
    set :wp_uploads, 'wp-content/uploads'
    set :wp_themes, 'wp-content/themes'
  end
end
