# coveralls-ignore-start

defmodule Exql.Migration.CreateDB do
  @moduledoc "Migration runner Supervisor"

  use Supervisor

  require Logger

  @type credentials :: %{
          hostname: String.t(),
          username: String.t(),
          password: String.t(),
          database: String.t()
        }
  @type opts :: [{:credentials, credentials()} | {:db_name, String.t()}]

  @spec start_link(opts()) :: Supervisor.on_start()
  def start_link(opts) do
    credentials = Keyword.fetch!(opts, :credentials)
    db_name = Keyword.fetch!(opts, :db_name)

    Supervisor.start_link(__MODULE__, {credentials, db_name})
  end

  @impl Supervisor
  @spec init({Postgrex.conn(), String.t()}) :: :ignore
  def init({credentials, db_name}) do
    start_options = Keyword.put(credentials, :pool_size, 1)
    {:ok, conn} = Postgrex.start_link(start_options)

    Exql.Migration.create_db(conn, db_name)

    GenServer.stop(conn)

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
