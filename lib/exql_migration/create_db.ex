# coveralls-ignore-start

defmodule Exql.Migration.CreateDB do
  @moduledoc "Migration runner Supervisor"

  use Supervisor

  require Logger

  @type opts :: [{:db_conn, Postgrex.conn()} | {:db_name, String.t()}]

  @spec start_link(opts()) :: Supervisor.on_start()
  def start_link(opts) do
    db_conn = Keyword.fetch!(opts, :db_conn)
    db_name = Keyword.fetch!(opts, :db_name)

    Supervisor.start_link(__MODULE__, {db_conn, db_name})
  end

  @impl Supervisor
  @spec init({Postgrex.conn(), String.t()}) :: :ignore
  def init({db_conn, db_name}) do
    Exql.Migration.create_db(db_conn, db_name)

    :ignore
  rescue
    exc ->
      Logger.emergency("Create DB failed")
      Logger.emergency(Exception.message(exc))
      Logger.emergency("#{inspect(exc)}")

      :init.stop()
  end
end

# coveralls-ignore-stop
