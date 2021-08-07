# coveralls-ignore-start

defmodule ExqlMigration.Task do
  @moduledoc "Migration runner Task"

  use Task, restart: :transient
  require Logger

  @spec start_link(db_conn: Postgrex.conn(), migrations_dir: Path.t()) :: {:ok, pid}
  def start_link(db_conn: db_conn, migrations_dir: migrations_dir) do
    Task.start_link(fn -> run(db_conn, migrations_dir) end)
  end

  @spec run(Postgrex.conn(), Path.t()) :: :ok
  defp run(db_conn, migrations_dir) do
    ExqlMigration.migrate(db_conn, migrations_dir)
  rescue
    exc ->
      Logger.emergency("Migration failed")
      Logger.emergency(Exception.message(exc))
      Logger.emergency("#{inspect(exc)}")

      :init.stop()
  end
end

# coveralls-ignore-stop
