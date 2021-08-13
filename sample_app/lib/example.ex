defmodule Example do
  use Application

  def start(_type, _args) do
    db_postgres_conf = Application.fetch_env!(:example, :db_postgres)
    db_mydb_conf = Application.fetch_env!(:example, :db_mydb)

    children = [
      # database "postgres" connection
      Supervisor.child_spec({Postgrex, db_postgres_conf}, id: :db_postgres),
      # create "mydb", connecting to "postgres" database
      {ExqlMigration.CreateDB, [db_conn: db_postgres_conf[:name], db_name: db_mydb_conf[:database]]},
      # database "mydb" connection
      Supervisor.child_spec({Postgrex, db_mydb_conf}, id: :db_mydb),
      # database "mydb" schema migrations
      {ExqlMigration.Migration, [db_conn: db_mydb_conf[:name], migrations_dir: db_mydb_conf[:migration_dir]]}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
