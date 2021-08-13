import Config

config :example, :db_postgres,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "postgres",
  pool_size: 1

config :example, :db_mydb,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "mydb",
  pool_size: 5
