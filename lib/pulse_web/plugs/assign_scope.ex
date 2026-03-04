defmodule PulseWeb.Plugs.AssignScope do
  @moduledoc """
  Generates a random Scope identity per session if none exists.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :scope) do
      nil ->
        scope = Pulse.Accounts.Scope.new()
        conn |> put_session(:scope, scope) |> assign(:current_scope, scope)

      scope ->
        assign(conn, :current_scope, scope)
    end
  end
end
