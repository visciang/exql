defmodule Exql.Migration do
  @moduledoc false

  require Logger
  alias Exql.Migration.{Log, Schema}

  @type credentials :: [
          hostname: String.t(),
          username: String.t(),
          password: String.t(),
          database: String.t()
        ]

  @spec create_db(credentials(), String.t()) :: :ok
  def create_db(credentials, db_name) do
    start_options = Keyword.put(credentials, :pool_size, 1)
    {:ok, conn} = Postgrex.start_link(start_options)

    unless exists_db?(conn, db_name) do
      case Postgrex.query(conn, "create database #{db_name}", []) do
        {:ok, _} ->
          Logger.info("Created DB #{inspect(db_name)}")

        # coveralls-ignore-start
        {:error, %Postgrex.Error{postgres: %{code: :duplicate_database}}} ->
          # if two instances of the app runs concurrently, exists_db? + query!
          # could raise since we do not acquire locks and execute these two
          # operations transactionally (create database can't run in a transaction)
          :ok

          # coveralls-ignore-end
      end
    end

    GenServer.stop(conn)
  rescue
    exc ->
      # coveralls-ignore-start
      Logger.emergency("Create DB failed")
      Logger.emergency(Exception.message(exc))
      Logger.emergency("#{inspect(exc)}")

      :init.stop()
      # coveralls-ignore-end
  end

  @spec migrate(credentials(), Path.t(), boolean(), timeout()) :: :ok
  def migrate(credentials, migrations_dir, transactional \\ true, timeout \\ :infinity) do
    start_options = Keyword.put(credentials, :pool_size, 1)
    {:ok, conn} = Postgrex.start_link(start_options)

    Schema.setup(conn)

    Logger.info("Migration started (dir: #{inspect(migrations_dir)})")

    migrations_dir
    |> migration_files()
    |> filter_migrations(Log.last_migration(conn))
    |> sort_migrations()
    |> Enum.each(&run(conn, &1, File.read!(Path.join(migrations_dir, &1)), timeout, transactional))

    Logger.info("Migration completed")

    GenServer.stop(conn)
  rescue
    exc ->
      # coveralls-ignore-start
      Logger.emergency("Migration failed")
      Logger.emergency(Exception.message(exc))
      Logger.emergency("#{inspect(exc)}")

      :init.stop()
      # coveralls-ignore-end
  end

  @spec run(Postgrex.conn(), Log.migration_id(), String.t(), timeout(), boolean()) :: :ok
  defp run(conn, migration_id, statements, timeout, transactional) do
    Logger.info("[#{migration_id}] Running")

    statements = """
    do $$
    begin
      #{statements}
    end $$
    """

    if transactional do
      Postgrex.transaction(
        conn,
        fn conn ->
          Log.lock(conn)
          run_statements(conn, migration_id, statements, :infinity)
        end,
        timeout: timeout
      )
    else
      run_statements(conn, migration_id, statements, timeout)
    end

    Logger.info("[#{migration_id}] Completed")

    :ok
  end

  @spec run_statements(Postgrex.conn(), Log.migration_id(), String.t(), timeout()) :: :ok
  defp run_statements(conn, migration_id, statements, timeout) do
    Logger.debug(statements)
    Postgrex.query!(conn, statements, [], timeout: timeout)
    shasum = :crypto.hash(:sha256, statements) |> Base.encode16(case: :lower)
    Log.insert(conn, migration_id, shasum)
    :ok
  end

  @spec migration_files(Path.t()) :: [String.t()]
  defp migration_files(migrations_dir) do
    migrations_dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".sql"))
  end

  @spec filter_migrations([String.t()], Log.migration_id()) :: [String.t()]
  defp filter_migrations(migrations, last_migration),
    do: Enum.reject(migrations, &applied?(&1, last_migration))

  @spec sort_migrations([String.t()]) :: [String.t()]
  defp sort_migrations(migrations),
    do: Enum.sort(migrations)

  @spec applied?(Log.migration_id(), nil | Log.migration_id()) :: boolean()
  defp applied?(migration, last_applied),
    do: migration <= last_applied

  @spec exists_db?(Postgrex.conn(), String.t()) :: boolean()
  defp exists_db?(conn, name) do
    res = Postgrex.query!(conn, "select true from pg_database where datname = $1", [name])
    match?(%Postgrex.Result{num_rows: 1}, res)
  end
end
