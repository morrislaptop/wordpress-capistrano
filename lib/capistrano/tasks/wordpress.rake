namespace :wordpress do

  namespace :db do
    desc "Pull the remote database"
    task :pull do

      on roles(:db) do
        within release_path do
          with path: "#{fetch(:path)}:$PATH" do
            execute :wp, "--path=#{fetch(:wp_path)} db export #{fetch(:tmp_dir)}/database.sql"
          end
        end

        download! "#{fetch(:tmp_dir)}/database.sql", "database.sql"

        run_locally do
          execute :wp, "--path=#{fetch(:wp_path)} db import database.sql"
          execute :wp, "--path=#{fetch(:wp_path)} search-replace #{fetch(:url)} #{fetch(:local_url)}"
          execute :rm, "database.sql"
          execute :wp, "--path=#{fetch(:wp_path)}", :option, :delete, :template_root, raise_on_non_zero_exit: false
          execute :wp, "--path=#{fetch(:wp_path)}", :option, :delete, :stylesheet_root, raise_on_non_zero_exit: false
        end

        execute :rm, "#{fetch(:tmp_dir)}/database.sql"
      end

    end

    desc "Push the local database"
    task :push do
      on roles(:web) do

        run_locally do
          execute :wp, "--path=#{fetch(:wp_path)} db export database.sql"
        end

        upload! "database.sql", "#{fetch(:tmp_dir)}/database.sql"

        run_locally do
          execute :rm, "database.sql"
        end

        within release_path do
          with path: "#{fetch(:path)}:$PATH" do
            execute :wp, "--path=#{fetch(:wp_path)} db import #{fetch(:tmp_dir)}/database.sql"
            execute :wp, "--path=#{fetch(:wp_path)} search-replace #{fetch(:local_url)} #{fetch(:url)}"
            execute :rm, "#{fetch(:tmp_dir)}/database.sql"
            invoke 'wordpress:paths'
          end
        end

      end
    end

    desc "Push the database in version control"
    task :deploy do

      on roles(:db) do

        upload! "#{fetch(:application)}.sql", "#{fetch(:tmp_dir)}/database.sql"

        within release_path do
          with path: "#{fetch(:path)}:$PATH" do
            execute :wp, "--path=#{fetch(:wp_path)} db import #{fetch(:tmp_dir)}/database.sql"
            execute :wp, "--path=#{fetch(:wp_path)} search-replace #{fetch(:local_url)} #{fetch(:url)}"
            execute :rm, "#{fetch(:tmp_dir)}/database.sql"
            invoke 'wordpress:paths'
          end
        end

      end

    end
  end

  namespace :uploads do

    desc "Synchronise local and remote wp content folders"
    task :sync do

      run_locally do
        roles(:all).each do |role|
          user = role.user + "@" if !role.user.nil?
          execute :rsync, "-avzO #{user}#{role.hostname}:#{release_path}/#{fetch(:wp_uploads)}/ #{fetch(:wp_uploads)}"
          execute :rsync, "-avzO #{fetch(:wp_uploads)}/ #{user}#{role.hostname}:#{release_path}/#{fetch(:wp_uploads)}"
        end
      end

    end

  end

  namespace :content do
    desc "Synchronise local and remote wp content folders"
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
