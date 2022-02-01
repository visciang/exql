defmodule Example do
  use Application

  def start(_type, _args) do
    postgres_credentials = Application.fetch_env!(:example, :postgres_credentials)
    mydb_conf = Application.fetch_env!(:example, :db_mydb)

    children = [
      # create "mydb", connecting to "postgres" database
      {Exql.Migration.CreateDB, [credentials: postgres_credentials, db_name: mydb_conf[:database]]},
      # database "mydb" connection pool
      Supervisor.child_spec({Postgrex, mydb_conf}, id: :db_mydb),
      # database "mydb" schema migrations
      {Exql.Migration.Migration, [conn: mydb_conf[:name], migrations_dir: mydb_conf[:migration_dir]]}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
