defmodule RouterManager.AuthorityView do
  use RouterManager.Web, :view

  def display(authority) do
    if authority do
      "#{authority.hostname}:#{authority.port}"
    else
      ""
    end
  end
end
