import Config

config :example, :db_postgres, name: :db_postgres

config :example, :db_mydb,
  name: :db_mydb,
  migration_dir: "priv/migrations/mydb"
