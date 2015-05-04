defmodule RouterManager.Api.AuthorityController.Test do
  use RouterManager.ConnCase

  import Ecto.Query

  alias RouterManager.Authority
  alias RouterManager.DeletedAuthority
  alias RouterManager.Route

  setup do
    a1 = Repo.insert(%Authority{hostname: "test", port: 80})
    a2 = Repo.insert(%Authority{hostname: "test2", port: 80})

    Repo.insert(%Route{authority_id: a1.id, hostname: "test", port: 80})
    Repo.insert(%Route{authority_id: a1.id, hostname: "test2", port: 80})

    on_exit fn ->
      Repo.delete_all(DeletedAuthority)
      Repo.delete_all(Route)
      Repo.delete_all(Authority)
    end

    {:ok, authorities: [a1, a2]}
  end

  test "GET /api/authorities with query param (url uppercase encoded)", context do
    a1 = List.first(context[:authorities])
    path = "/api/authorities?hostspec=#{a1.hostname}%3A#{a1.port}"
    conn = get conn(), path
    assert conn.status == 200

    body = Poison.decode!(conn.resp_body)
    assert body["hostname"] == a1.hostname
    assert body["port"] == a1.port
  end

  test "GET /api/authorities with query param (url lowercase encoded)", context do
    a1 = List.first(context[:authorities])
    path = "/api/authorities?hostspec=#{a1.hostname}%3a#{a1.port}"
    conn = get conn(), path
    assert conn.status == 200

    body = Poison.decode!(conn.resp_body)
    assert body["hostname"] == a1.hostname
    assert body["port"] == a1.port
  end

  test "GET /api/authorities with query param (not url encoded)", context do
    a1 = List.first(context[:authorities])
    path = "/api/authorities?hostspec=#{a1.hostname}:#{a1.port}"
    conn = get conn(), path
    assert conn.status == 200

    body = Poison.decode!(conn.resp_body)
    assert body["hostname"] == a1.hostname
    assert body["port"] == a1.port
  end

  test "GET /api/authorities with query param for non-existent host" do
    path = "/api/authorities?hostspec=not_a_real_host:9999"
    conn = get conn(), path
    assert conn.status == 404
  end

  test "GET /api/authorities with invalied query param" do
    path = "/api/authorities?hostspec=hostname^9999"
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

  test "GET /api/authorities/:id id not found" do
    conn = get conn(), "/api/authorities/1234567890"
    assert conn.status == 404
  end

  test "DELETE /api/authorities/1", context do
    a1 = List.first(context[:authorities])

    conn = delete conn(), "/api/authorities/#{a1.id}"
    assert conn.status == 204

    assert Authority |> Repo.all |> length == length(context[:authorities]) - 1
  end

  test "DELETE /api/authorities/1 deletes associated routes", context do
    routes_count = length(Repo.all(Route))

    a1 = List.first(context[:authorities])

    conn = delete conn(), "/api/authorities/#{a1.id}"
    assert conn.status == 204

    assert length(Repo.all(Route)) == routes_count - 2
  end

  test "DELETE /api/authorities/1 creates a record in the deleted_authorities table", context do
    a1 = List.first(context[:authorities])

    deleted_count = DeletedAuthority |> Repo.all |> length

    conn = delete conn(), "/api/authorities/#{a1.id}"
    assert conn.status == 204

    deleted = DeletedAuthority
              |> where([da], da.hostname == ^a1.hostname)
              |> where([da], da.port == ^a1.port)
              |> Repo.one

    assert DeletedAuthority |> Repo.all |> length == deleted_count + 1

    assert deleted != nil
    assert deleted.hostname == a1.hostname
    assert deleted.port == a1.port
  end

  test "DELETE /api/authorities/123456789" do
    conn = delete conn(), "/api/authorities/123456789"
    assert conn.status == 404
  end

  test "DELETE /api/authorities/bad_authority_id" do
    conn = delete conn(), "/api/authorities/bad_authority_id"
    assert conn.status == 404
  end

  test "POST /api/authorities" do
    authority = %{hostname: "new_test", port: 80}
    conn = post conn(), "/api/authorities", authority

    assert conn.status == 201
    assert List.keymember?(conn.resp_headers, "location", 0)
    {_, location} = List.keyfind(conn.resp_headers, "location", 0)
    assert Regex.match?(~r/api\/authorities\/\d+/, location)
  end

  test "POST /api/authorities, missing hostname" do
    authority = %{port: 80}
    conn = post conn(), "/api/authorities", authority

    assert conn.status == 400
  end

  test "POST /api/authorities, missing port" do
    authority = %{hostname: "new_test"}
    conn = post conn(), "/api/authorities", authority

    assert conn.status == 400
  end

  test "POST /api/authorities, bad port value" do
    authority = %{hostname: "new_test", port: "NaN"}
    conn = post conn(), "/api/authorities", authority

    assert conn.status == 400
  end

  test "POST /api/authorities, port number out of range" do
    authority = %{hostname: "new_test", port: "99999"}
    conn = post conn(), "/api/authorities", authority

    assert conn.status == 400
  end

  test "POST /api/authorities, authority already exists", context do
    a1 = List.first(context[:authorities])
    authority = %{hostname: a1.hostname, port: a1.port}
    conn = post conn(), "/api/authorities", authority

    assert conn.status == 409
  end

  test "PUT /api/authorities/:id", context do
    a1 = List.first(context[:authorities])
    new_port = 1337
    authority = %{hostname: a1.hostname, port: new_port}

    conn = put conn(), "/api/authorities/#{a1.id}", authority

    assert conn.status == 204

    new_a1 = Repo.get(Authority, a1.id)
    assert new_a1.port == new_port
  end

  test "PUT /api/authorities/:id creates a DeletedAuthority for the old hostname:port combo", context do
    deleted_count = DeletedAuthority |> Repo.all |> length

    a1 = List.first(context[:authorities])
    new_port = 1337
    authority = %{hostname: a1.hostname, port: new_port}

    conn = put conn(), "/api/authorities/#{a1.id}", authority

    assert conn.status == 204

    new_a1 = Repo.get(Authority, a1.id)
    assert new_a1.port == new_port
    deleted = DeletedAuthority
              |> where([da], da.hostname == ^a1.hostname)
              |> where([da], da.port == ^a1.port)
              |> Repo.one

    deleted = Repo.all(DeletedAuthority)
    assert length(deleted) == deleted_count + 1
    
    da = List.first(deleted)
    assert da.hostname == a1.hostname
    assert da.port == a1.port
  end

  test "PUT /api/authorities/:id id not found", context do
    a1 = List.first(context[:authorities])
    new_port = 1337
    authority = %{hostname: a1.hostname, port: new_port}
    
    conn = put conn(), "/api/authorities/1234567890", authority

    assert conn.status == 404
  end

  test "PUT /api/authorities/:id invalid id", context do
    a1 = List.first(context[:authorities])
    new_port = 1337
    authority = %{hostname: a1.hostname, port: new_port}
    
    conn = put conn(), "/api/authorities/not_a_valid_id", authority

    assert conn.status == 404
  end

  test "PUT /api/authorities/:id conflict", context do
    a1 = List.first(context[:authorities])
    new_port = 1337
    authority = %{hostname: a1.hostname, port: new_port}
    
    conn = put conn(), "/api/authorities/1234567890", authority

    assert conn.status == 404
  end

  test "PUT /api/authorities/:id empty hostname", context do
    a1 = List.first(context[:authorities])

    authority = %{hostname: ""}
    
    conn = put conn(), "/api/authorities/#{a1.id}", authority

    assert conn.status == 400
  end

  test "PUT /api/authorities/:id bad hostname value", context do
    a1 = List.first(context[:authorities])

    authority = %{hostname: 1234567890}
    
    conn = put conn(), "/api/authorities/#{a1.id}", authority

    assert conn.status == 400
  end

  test "PUT /api/authorities/:id empty port value", context do
    a1 = List.first(context[:authorities])

    authority = %{port: ""}
    
    conn = put conn(), "/api/authorities/#{a1.id}", authority

    assert conn.status == 400
  end

  test "PUT /api/authorities/:id bad port value", context do
    a1 = List.first(context[:authorities])

    authority = %{port: "not a parseable number"}
    
    conn = put conn(), "/api/authorities/#{a1.id}", authority

    assert conn.status == 400
  end
end