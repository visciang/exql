defmodule Example do
  use Application

  def start(_type, _args) do
    postgrex_conf = Application.get_all_env(:postgrex)
    db_conn = Application.fetch_env!(:postgrex, :name)
    migrations_dir = Application.fetch_env!(:exql_migration, :migration_dir)

    children = [
      {Postgrex, postgrex_conf},
      {ExqlMigration.Task, [db_conn: db_conn, migrations_dir: migrations_dir]}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
