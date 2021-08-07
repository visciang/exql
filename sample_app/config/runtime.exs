import Config

config :postgrex,
  name: :db,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "postgres",
  pool_size: 5

config :exql_migration,
  migration_dir: "priv/migrations"
