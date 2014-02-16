namespace :wordpress do

  namespace :db do
    desc "Pull the remote database"
    task :pull do
      on roles(:web) do
        within release_path do
          with path: "#{fetch(:path)}:$PATH" do
            execute :wp, "migrate to #{fetch(:tmp_dir)} #{fetch(:local_url)} #{fetch(:tmp_dir)}/database.sql"
            download! "#{fetch(:tmp_dir)}/database.sql", "database.sql"
            execute :rm, "#{fetch(:tmp_dir)}/database.sql"
          end
        end

        run_locally do
          execute "mysql -u #{fetch(:wpdb)[:local][:user]} -p#{fetch(:wpdb)[:local][:password]} -h #{fetch(:wpdb)[:local][:host]} #{fetch(:wpdb)[:local][:name]} < database.sql"
          execute :rm, "database.sql"
        end
      end
    end

    desc "Push the local database"
    task :push do
      on roles(:web) do
        run_locally do
          execute :wp, "db export database.sql"
        end

        upload! "database.sql", "#{fetch(:tmp_dir)}/database.sql"

        run_locally do
          execute :rm, "database.sql"
        end

        within release_path do
          with path: "#{fetch(:path)}:$PATH" do
            execute :wp, "db import #{fetch(:tmp_dir)}/database.sql"
            execute :wp, "search-replace #{fetch(:local_url)} #{fetch(:url)}"
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
            execute :wp, "db import #{fetch(:tmp_dir)}/database.sql"
            execute :wp, "search-replace #{fetch(:local_url)} #{fetch(:url)}"
            execute :rm, "#{fetch(:tmp_dir)}/database.sql"
          end
        end
      end
    end
  end
end