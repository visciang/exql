defmodule Exql.Migration do
  @moduledoc false

  require Logger
  alias Exql.Migration.{Log, Schema}

  @spec create_db(Postgrex.conn(), String.t()) :: :ok
  def create_db(conn, name) do
    # if two instances of the app runs concurrently, exists_db? + query!
    # could raise since we do not acquire locks and execute this two
    # operation transactionally (create database can't run in a transaction).
    # BTW, it's fine. If we hit this race condition the supervisor will retry
    unless exists_db?(conn, name) do
      Logger.info("Create DB #{inspect(name)}")
      Postgrex.query!(conn, "create database #{name}", [])
    end

    :ok
  end

  @spec migrate(Postgrex.conn(), Path.t(), timeout(), boolean()) :: :ok
  def migrate(conn, migrations_dir, timeout, transactional) do
    Schema.setup(conn)

    Logger.info("Migration started (dir: #{inspect(migrations_dir)})")

    migrations_dir
    |> migration_files()
    |> filter_migrations(Log.last_migration(conn))
    |> sort_migrations()
    |> Enum.each(&run(conn, &1, File.read!(Path.join(migrations_dir, &1)), timeout, transactional))

    Logger.info("Migration completed")

    :ok
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
          run_statememnts(conn, migration_id, statements, :infinity)
        end,
        timeout: timeout
      )
    else
      run_statememnts(conn, migration_id, statements, timeout)
    end

    Logger.info("[#{migration_id}] Completed")

    :ok
  end

  @spec run_statememnts(Postgrex.conn(), Log.migration_id(), String.t(), timeout()) :: :ok
  defp run_statememnts(conn, migration_id, statements, timeout) do
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
