defmodule LiveWeb.PageController do
  use LiveWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
