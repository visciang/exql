defmodule Test.Exql.Query do
  use ExUnit.Case, async: true
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

  test "result to map", %{conn: conn} do
    res = Postgrex.query!(conn, "select * from #{@test_table}", [])
    assert [] = Query.result_to_map(res)

    Postgrex.query!(conn, "insert into #{@test_table} (x, y) values ('a', 'b')", [])
    res = Postgrex.query!(conn, "select * from #{@test_table}", [])
    assert [%{"x" => "a", "y" => "b"}] = Query.result_to_map(res)
  end

  test "named params", %{conn: conn} do
    assert [] = query!(conn, "select * from #{@test_table}")

    query!(conn, "insert into #{@test_table} (x, y) values (:x, :y)", %{x: "a", y: "b"})
    assert [%{"x" => "a", "y" => "b"}] = query!(conn, "select * from #{@test_table}")
  end

  test "named params escaping" do
    assert {:ok, ~s/insert into ":table" (x, y) values (':literal'::text, $1)/, ["b"]} =
             Exql.Query.named_params(~s/insert into ":table" (x, y) values (':literal'::text, :y)/, %{y: "b"})
  end

  test "named params with missing bindings" do
    assert {:error, {:missing_var_bindings, ["y"]}} =
             Exql.Query.named_params("insert into a_table values (:x, :y)", %{x: "a"})
  end

  defp query!(conn, stmt, args \\ %{}, opts \\ []) do
    {:ok, q, p} = Exql.Query.named_params(stmt, args)
    res = Postgrex.query!(conn, q, p, opts)
    Query.result_to_map(res)
  end
end
