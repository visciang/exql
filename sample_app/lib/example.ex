defmodule Example do
  use Application

  def start(_type, _args) do
    postgres_credentials = Application.fetch_env!(:example, :postgres_credentials)
    mydb_conf = Application.fetch_env!(:example, :db_mydb)

    Exql.Migration.create_db(postgres_credentials, mydb_conf[:database])
    Exql.Migration.migrate(mydb_conf, mydb_conf[:migration_dir])

    children = [
      {Postgrex, mydb_conf}
      # ...
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
