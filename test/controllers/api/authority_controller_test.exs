defmodule RouterManager.Api.AuthorityController.Test do
  use RouterManager.ConnCase

  alias RouterManager.Authority

  setup do
    a1 = Repo.insert(%Authority{hostname: "test", port: 80})
    a2 = Repo.insert(%Authority{hostname: "test2", port: 80})

    on_exit fn ->
      Repo.delete_all(Authority)
    end

    {:ok, authorities: [a1, a2]}
  end

  test "GET /api/authorities with query param (url uppercase encoded)", context do
    a1 = List.first(context[:authorities])
    path = "/api/authorities?authority=#{a1.hostname}%3A#{a1.port}"
    conn = get conn(), path
    assert conn.status == 200

    body = Poison.decode!(conn.resp_body)
    assert body["hostname"] == a1.hostname
    assert body["port"] == a1.port
  end

  test "GET /api/authorities with query param (url lowercase encoded)", context do
    a1 = List.first(context[:authorities])
    path = "/api/authorities?authority=#{a1.hostname}%3a#{a1.port}"
    conn = get conn(), path
    assert conn.status == 200

    body = Poison.decode!(conn.resp_body)
    assert body["hostname"] == a1.hostname
    assert body["port"] == a1.port
  end

  test "GET /api/authorities with query param (not url encoded)", context do
    a1 = List.first(context[:authorities])
    path = "/api/authorities?authority=#{a1.hostname}:#{a1.port}"
    conn = get conn(), path
    assert conn.status == 200

    body = Poison.decode!(conn.resp_body)
    assert body["hostname"] == a1.hostname
    assert body["port"] == a1.port
  end

  test "GET /api/authorities with query param for non-existent host" do
    path = "/api/authorities?authority=not_a_real_host:9999"
    conn = get conn(), path
    assert conn.status == 404
  end

  test "GET /api/authorities with invalied query param" do
    path = "/api/authorities?authority=hostname^9999"
    conn = get conn(), path
    assert conn.status == 400
  end

  test "GET /api/authorities", context do
    conn = get conn(), "/api/authorities"
    assert conn.status == 200

    body = Poison.decode!(conn.resp_body)
    assert length(body) == length(context[:authorities])
  end

  test "GET /api/authorities/1", context do
    a1 = List.first(context[:authorities])

    conn = get conn(), "/api/authorities/#{a1.id}"
    assert conn.status == 200

    body = Poison.decode!(conn.resp_body)
    assert body["hostname"] == a1.hostname
    assert body["port"] == a1.port
  end

  test "DELETE /api/authorities/1", context do
    a1 = List.first(context[:authorities])

    conn = delete conn(), "/api/authorities/#{a1.id}"
    assert conn.status == 204

    assert Authority |> Repo.all |> length == length(context[:authorities]) - 1
  end
end