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
          execute :rm, "database.sql"
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
          end
        end

      end

    end
  end

  namespace :content do

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


end

namespace :load do
  task :defaults do
    set :url, 'www.wordpress.org'
    set :local_url, 'localhost'
    set :wp_path, '.'
    set :wp_uploads, 'wp-content/uploads'
  end
end