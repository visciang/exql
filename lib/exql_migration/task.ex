# coveralls-ignore-start

defmodule ExqlMigration.Task do
  @moduledoc "Migration runner Task"

  use Task, restart: :transient
  require Logger

  @type opts :: [
          {:db_conn, Postgrex.conn()}
          | {:migrations_dir, Path.t()}
          | {:timeout, timeout()}
          | {:transactional, boolean()}
        ]

  @spec start_link(opts()) :: {:ok, pid}
  def start_link(opts) do
    db_conn = Keyword.fetch!(opts, :db_conn)
    migrations_dir = Keyword.fetch!(opts, :migrations_dir)
    timeout = Keyword.get(opts, :timeout, :infinity)
    transactional = Keyword.get(opts, :transactional, true)

    Task.start_link(fn -> run(db_conn, migrations_dir, timeout, transactional) end)
  end

  @spec run(Postgrex.conn(), Path.t(), timeout(), boolean()) :: :ok
  defp run(db_conn, migrations_dir, timeout, transactional) do
    ExqlMigration.migrate(db_conn, migrations_dir, timeout, transactional)
  rescue
    exc ->
      Logger.emergency("Migration failed")
      Logger.emergency(Exception.message(exc))
      Logger.emergency("#{inspect(exc)}")

      :init.stop()
  end
end

# coveralls-ignore-stop
