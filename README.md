# ExqlMigration

![CI](https://github.com/visciang/exql_migration/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/visciang/exql_migration/badge.svg?branch=master)](https://coveralls.io/github/visciang/exql_migration?branch=master)

`exql_migration` is a minimalist executor for Postgres schema migration scripts.

Good for those who:

> No Ecto, just Postgrex please!
> No down script, we go only up!

Define your ordered list of SQL migrations under `priv/migrations/*.sql` and add `ExqlMigration.Task` to you app supervisor.
The migration task will execute the `*.sql` scripts not already applied to the target DB.
The execution order follows the scripts filename alphabetic order.

If a migration script fails, the `ExqlMigration.Task` executor stops the application.

## Multi instance deployment safety

If you have n instances of your app deployed, each of them can safely run the migration task since every migration runs
in a transaction and acquire a `'LOCK ... SHARE MODE'` ensuring that one and only migration execution can run at a time.

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
    {ExqlMigration.Migration, [
        db_conn: postgres_conn,
        migrations_dir: migrations_dir,
        timeout: 5_000,      # default :infinity
        transactional: true  # default true, if false You know What you are doing
      ]}
  ]

  opts = [strategy: :one_for_one]
  Supervisor.start_link(children, opts)
```

if you have multiple DBs to setup:

```elixir
    children = [
      Supervisor.child_spec({Postgrex, db_A_conf}, id: :postgrex_A),
      Supervisor.child_spec({ExqlMigration.Migration, [db_conn: db_A_conn, migrations_dir: db_A_migrations_dir]}, id: :exql_db_A),
      Supervisor.child_spec({Postgrex, db_B_conf}, id: :postgrex_B),
      Supervisor.child_spec({ExqlMigration.Migration, [db_conn: db_B_conn, migrations_dir: db_B_migrations_dir]}, id: :exql_db_B)
    ]
```

`ExqlMigration.CreateDB` can be included in the supervision tree to create (if not exists) a database.
Check the sample app under `./sample_app` for more details.

# Development

```shell
docker run -d --rm -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:alpine

mix deps.get
mix format
mix credo --strict --all
mix dialyzer
mix coveralls
```
