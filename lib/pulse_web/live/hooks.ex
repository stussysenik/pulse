defmodule PulseWeb.Live.Hooks do
  @moduledoc """
  on_mount hooks for all LiveViews:
  - :assign_scope — reads Scope from session
  - :track_presence — tracks the user in the global presence topic
  """
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  alias Pulse.Accounts.Scope
  alias PulseWeb.Presence

  @global_topic "pulse:presence"

  def on_mount(:assign_scope, _params, session, socket) do
    scope = session["scope"] || Scope.new()

    socket =
      socket
      |> assign(:current_scope, scope)
      |> Phoenix.LiveView.attach_hook(:save_uri, :handle_params, fn _params, uri, socket ->
        path = URI.parse(uri).path
        {:cont, assign(socket, :current_path, path)}
      end)

    {:cont, socket}
  end

  def on_mount(:track_presence, _params, _session, socket) do
    if connected?(socket) do
      scope = socket.assigns.current_scope

      {:ok, _} =
        Presence.track(self(), @global_topic, scope.id, %{
          name: scope.name,
          color: scope.color,
          joined_at: System.system_time(:second)
        })

      Phoenix.PubSub.subscribe(Pulse.PubSub, @global_topic)
    end

    presences = Presence.list(@global_topic)
    {:cont, assign(socket, :presences, presences)}
  end
end
