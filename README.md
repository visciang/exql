# Exql

![CI](https://github.com/visciang/exql/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/visciang/exql/badge.svg?branch=master)](https://coveralls.io/github/visciang/exql?branch=master)

Few little things to work directly with `Postgrex`.

## Exql.Query

### Postgrex.Result as a list of maps

```elixir
res = Postgrex.query!(conn, "select x, y from table", [])
[%{"x" => x, "y" => y}, ...] = Exql.Query.result_to_map(res)
```

### Named parameters query

```elixir
{:ok, q, p} = Exql.Query.named_params("insert into a_table (x, y1, y2) values (:x, :y, :y)", %{x: "X", y: "Y"})

Postgrex.query!(conn, q, p)
```

### Usage

You may define a convenient wrapper around the two functions above:

```elixir
def query!(conn, stmt, args \\ %{}, opts \\ []) do
  {:ok, q, p} = Exql.Query.named_params(stmt, args)
  res = Postgrex.query!(conn, q, p, opts)
  Query.result_to_map(res)
end
```

so that this:

```elixir
{:ok, q, p} = Exql.Query.named_params("insert into a_table (x, y1, y2) values (:x, :y, :y)", %{x: "X", y: "Y"})
res = Postgrex.query!(conn, q, p)
Exql.Query.result_to_map(res)
```

become this:

```elixir
query!("insert into a_table (x, y1, y2) values (:x, :y, :y)", %{x: "X", y: "Y"})
```

## Exql.Migration

A minimalist executor for Postgres schema migration scripts.

Define your ordered list of SQL migrations under `priv/migrations/*.sql` and add `Exql.Migration` to you app supervisor.
The migration task will execute the `*.sql` scripts not already applied to the target DB.
The execution order follows the scripts filename alphabetic order.

If a migration script fails, the `Exql.Migration` executor stops the application.

### Multi instance deployment safety

If you have n instances of your app deployed, each of them can safely run the migration task since every migration runs
in a transaction and acquire a `'LOCK ... SHARE MODE'` ensuring that one and only migration execution can run at a time.

### Usage

In your application you can call the `Exql.Migration.create_db` and `Exql.Migration.migrate` functions:

```elixir
Exql.Migration.create_db(postgres_credentials, "db_name")
Exql.Migration.migrate(mydb_credentials, "priv/migrations/db_name")
```

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
