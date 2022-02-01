# coveralls-ignore-start

defmodule Exql.Migration.Migration do
  @moduledoc "Migration runner Supervisor"

  use Supervisor

  require Logger

  @type opts :: [
          {:conn, Postgrex.conn()}
          | {:migrations_dir, Path.t()}
          | {:timeout, timeout()}
          | {:transactional, boolean()}
        ]

  @spec start_link(opts()) :: Supervisor.on_start()
  def start_link(opts) do
    conn = Keyword.fetch!(opts, :conn)
    migrations_dir = Keyword.fetch!(opts, :migrations_dir)
    timeout = Keyword.get(opts, :timeout, :infinity)
    transactional = Keyword.get(opts, :transactional, true)

    Supervisor.start_link(__MODULE__, {conn, migrations_dir, timeout, transactional})
  end

  @impl Supervisor
  @spec init({Postgrex.conn(), Path.t(), timeout(), boolean()}) :: :ignore
  def init({conn, migrations_dir, timeout, transactional}) do
    Exql.Migration.migrate(conn, migrations_dir, timeout, transactional)

    :ignore
  rescue
    exc ->
      Logger.emergency("Migration failed")
      Logger.emergency(Exception.message(exc))
      Logger.emergency("#{inspect(exc)}")

      :init.stop()
  end
end

# coveralls-ignore-stop
