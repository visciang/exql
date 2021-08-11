defmodule ExqlMigration do
  @moduledoc File.read!("README.md")

  require Logger
  alias ExqlMigration.{Log, Schema}

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
  defp run(conn, migration_id, statement, timeout, transactional) do
    Logger.info("[#{migration_id}] Running")

    if transactional do
      Postgrex.transaction(
        conn,
        fn conn ->
          Log.lock(conn)

          unless applied?(migration_id, Log.last_migration(conn)) do
            Postgrex.query!(conn, statement, [], timeout: :infinity)
            shasum = :crypto.hash(:sha256, statement) |> Base.encode16(case: :lower)
            Log.insert(conn, migration_id, shasum)
          end
        end,
        timeout: timeout
      )
    else
      unless applied?(migration_id, Log.last_migration(conn)) do
        Postgrex.query!(conn, statement, [], timeout: timeout)
        shasum = :crypto.hash(:sha256, statement) |> Base.encode16(case: :lower)
        Log.insert(conn, migration_id, shasum)
      end
    end

    Logger.info("[#{migration_id}] Completed")

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
end
