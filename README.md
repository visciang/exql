# ExqlMigration

![CI](https://github.com/visciang/exql_migration/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/visciang/exql_migration/badge.svg?branch=main)](https://coveralls.io/github/visciang/exql_migration?branch=main)

Postgres SQL schema migration scripts runner.

For those who:

> No Ecto, just postgrex please!
> No down script, we go only up! 

Define your SQL migrations under `priv/migrations/*.sql`.

The migration task will execute the `*.sql` scripts not already applied to the target DB in alphabetic order.

Every migration runs in a transaction and acquire a `'LOCK ... SHARE MODE'` ensuring that one and only migration execution can run at a time.

If a migration script fails, the `ExqlMigration.Task` executor stops the application.

## Usage

In your app supervisor, start `Postgrex` and then the `ExqlMigration.Task`.

```elixir
  migrations_dir = "priv/migrations"
  
  postgres_conn = :db
  postgres_conf = [
    name: postgres_conn,
    hostname: "localhost",
    username: "postgres",
    password: "postgres",
    database: "postgres",
    pool_size: 5
  ]

  children = [
    {Postgrex, postgres_conf},
    {ExqlMigration.Task, [db_conn: postgres_conn, migrations_dir: migrations_dir]}
  ]

  opts = [strategy: :one_for_one]
  Supervisor.start_link(children, opts)
```

Check the sample app under `./sample_app`.

# Development

```shell
docker run -d --rm -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:alpine

mix deps.get
mix format
mix credo --strict --all
mix dialyzer
mix coveralls
```
