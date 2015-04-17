defmodule RouterManager.RouteView do
  use RouterManager.Web, :view

  def display(route) do
    if route do
      "#{route.hostname}:#{route.port}"
    else
      ""
    end
  end
end
