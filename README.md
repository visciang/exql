# ExqlMigration

SQL schema migration scripts runner.

No ecto_sql, just postgrex.
No down script, we go only up!!!  

## Usage

In your app supervisor, start Postgrex and then run a one off task with ExqlMigration.migrate.
The migration dir should be included in the app release, the migrate function will execute in
alphabetic order the *.sql scripts not already applied to the target DB.

```elixir
  migrations_dir = "priv/migrations"
  
  postgres_conn = :db
  postgres_conf = [
    name: postgres_conn,
    hostname: "localhost",
    username: "postgres",
    password: "postgres",
    database: "postgres"
  ]

  children = [
    {Postgrex, postgres_conf},
    {Task, fn -> ExqlMigration.migrate(postgres_conn, migrations_dir) end}}
  ]

  Supervisor.start_link(children, ...)
```
