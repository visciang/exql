defmodule ExqlMigration do
  @moduledoc File.read!("README.md")

  require Logger
  alias ExqlMigration.{Log, Schema}

  @type migration_id :: String.t()

  @default_migration_timeout :infinity

  @spec migrate(Postgrex.conn(), Path.t(), timeout()) :: :ok
  def migrate(conn, migrations_dir, timeout \\ @default_migration_timeout) do
    Schema.setup(conn)

    Logger.info("Migration started")

    migrations_dir
    |> migration_files(Log.last_migration(conn))
    |> Enum.each(&run(conn, &1, File.read!(Path.join(migrations_dir, &1)), timeout))

    Logger.info("Migration completed")

    :ok
  end

  @spec run(Postgrex.conn(), migration_id(), String.t(), timeout()) :: :ok
  defp run(conn, migration_id, statement, timeout) do
    Postgrex.transaction(
      conn,
      fn conn ->
        Log.lock(conn)

        unless applied?(migration_id, Log.last_migration(conn)) do
          Logger.info("[#{migration_id}] Running")
          Postgrex.query!(conn, statement, [], timeout: :infinity)
          shasum = :crypto.hash(:sha256, statement) |> Base.encode16(case: :lower)
          Log.insert(conn, migration_id, shasum)
          Logger.info("[#{migration_id}] Completed")
        end
      end,
      timeout: timeout
    )

    :ok
  end

  @spec migration_files(Path.t(), migration_id()) :: [String.t()]
  defp migration_files(migrations_dir, last_migration) do
    migrations_dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".sql"))
    |> Enum.reject(&applied?(&1, last_migration))
    |> Enum.sort()
  end

  @spec applied?(migration_id(), nil | migration_id()) :: boolean()
  defp applied?(_migration, nil), do: false

  defp applied?(migration, last_applied) do
    migration <= last_applied
  end
end
