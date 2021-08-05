defmodule ExqlMigration do
  require Logger

  alias ExqlMigration.{Log, Schema}

  @type migration_id :: String.t()

  @default_migration_timeout :infinity

  @spec migrate(Postgrex.conn(), Path.t(), timeout()) :: :ok
  def migrate(conn, migrations_dir, timeout \\ @default_migration_timeout) do
    Schema.setup(conn)

    Postgrex.transaction(
      conn,
      fn conn ->
        Logger.info("Migration started")

        Log.lock(conn)
        Logger.info("Acquired migration exclusive lock")

        last_migration = Log.last(conn)

        migration_files =
          migrations_dir
          |> File.ls!()
          |> Enum.sort()
          |> Enum.reject(&applied?(&1, last_migration))

        if migration_files == [] do
          Logger.info("Nothing to do, all migration scripts already applied")
        else
          Enum.each(migration_files, &run(conn, &1, File.read!(Path.join(migrations_dir, &1)), timeout))
        end

        current_revision = List.last(migration_files, last_migration)
        Logger.info("Migration completed (current revision: #{current_revision})")
      end
    )

    :ok
  end

  @spec applied?(migration_id(), nil | migration_id()) :: boolean()
  defp applied?(_migration, nil), do: false

  defp applied?(migration, last_applied) do
    migration <= last_applied
  end

  @spec run(Postgrex.conn(), migration_id(), String.t(), timeout()) :: :ok
  defp run(conn, migration_id, statement, timeout) do
    shasum = :crypto.hash(:sha256, statement) |> Base.encode16(case: :lower)

    Logger.info("[#{migration_id}] Running")
    started_at = Log.clock_timestamp(conn)
    Postgrex.query!(conn, statement, [], timeout: timeout)
    Log.insert(conn, migration_id, shasum, started_at)
    Logger.info("[#{migration_id}] Completed")

    :ok
  end
end
