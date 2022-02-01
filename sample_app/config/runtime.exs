import Config

config :example, :postgres_credentials,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "postgres"

config :example, :db_mydb,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "mydb",
  pool_size: 5
