defmodule Test.Exql.Query do
  use ExUnit.Case
  alias Exql.Query

  @postgrex_conf [
    hostname: System.get_env("POSTGRES_HOST", "localhost"),
    username: "postgres",
    password: "postgres",
    database: "postgres"
  ]

  @test_table "query_test_table"

  setup_all do
    conn = start_supervised!({Postgrex, @postgrex_conf})

    Postgrex.query!(conn, "drop table if exists #{@test_table}", [])
    Postgrex.query!(conn, "create table #{@test_table} (x text, y text)", [])

    %{conn: conn}
  end

  setup %{conn: conn} do
    on_exit(fn ->
      Postgrex.query!(conn, "truncate table #{@test_table}", [])
    end)
  end

  test "results zip", %{conn: conn} do
    Postgrex.query!(conn, "insert into #{@test_table} (x, y) values ('a', 'b')", [])

    res = Postgrex.query!(conn, "select * from #{@test_table}", [])
    assert [%{"x" => "a", "y" => "b"}] = Query.result(res)
  end
end
