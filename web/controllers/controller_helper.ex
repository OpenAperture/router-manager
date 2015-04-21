defmodule RouterManager.ControllerHelper do
  @moduledoc """
  This module provides helper functions that are used by controllers to
  format incoming and outgoing data.
  """

  @doc """
  to_sendable prepares a struct or map for transmission by converting structs
  to plain old maps (if a struct is passed in), and stripping out any fields
  in the allowed_fields list. If allowed_fields is empty, then all fields are
  sent.
  """
  @spec to_sendable(Map.t, List.t) :: Map.t
  def to_sendable(item, allowed_fields \\ [])

  def to_sendable(item, []) when is_map(item) do
    to_sendable(item, Map.keys(item))
  end

  def to_sendable(%{__struct__: _} = struct, allowed_fields) do
    struct
    |> Map.from_struct
    |> to_sendable(allowed_fields)
  end

  def to_sendable(item, allowed_fields) when is_map(item) do
    Map.take(item, allowed_fields)
  end

  @doc """
  keywords_to_map converts a keyword list to a map, which is more easily
  transmitted as a JSON object. If a key is repeated in the keyword list, then
  the value in the map is represented as a list.
  Ex:
  [a: "First value", b: "Second value", c: "Third value"] becomes
  %{a: ["First value", "Third value"], b: "Second value"}
  """
  @spec keywords_to_map(Keyword) :: Map
  def keywords_to_map(kw) do
    kw
    |> Enum.reduce(
      %{},
      fn {key, value}, acc ->
        current = acc[key]
        case current do
          nil -> Map.put(acc, key, value)
          [single] -> Map.put(acc, key, [single, value])
          [_ | _] -> Map.put(acc, key, current ++ [value])
          _ -> Map.put(acc, key, [current, value])
        end
      end)
  end

  @doc """
  Parses a string of the form hostname:port into its separate hostname
  and port components. Supports URL-encoded colons.

  ## Examples

      iex> RouterManager.ControllerHelper.parse_hostspec("test:80")
      {:ok, "test", 80}

      iex> RouterManager.ControllerHelper.parse_hostspec("test%3A80")
      {:ok, "test", 80}

      iex> RouterManager.ControllerHelper.parse_hostspec("test%3a80")
      {:ok, "test", 80}
  """
  @spec parse_hostspec(String.t) :: {:ok, String.t, integer} | :error
  def parse_hostspec(authority) do
    colon_regex = ~r/(?<hostname>.*):(?<port>\d+)$/
    urlencoded_regex = ~r/(?<hostname>.*)%3[aA](?<port>\d+)$/

    cond do
      Regex.match?(colon_regex, authority) ->
        captures = Regex.named_captures(colon_regex, authority)
        {:ok, captures["hostname"], String.to_integer(captures["port"])}

      Regex.match?(urlencoded_regex, authority) ->
        captures = Regex.named_captures(urlencoded_regex, authority)
        {:ok, captures["hostname"], String.to_integer(captures["port"])}

      true -> :error
    end
  end
end