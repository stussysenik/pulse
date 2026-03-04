defmodule PulseWeb.Layouts do
  @moduledoc """
  Phoenix 1.8 function component layouts with daisyUI drawer sidebar.
  """
  use PulseWeb, :html

  embed_templates "layouts/*"

  @nav_items [
    %{path: "/", label: "Dashboard", icon: "hero-chart-bar-square"},
    %{path: "/chat", label: "Chat", icon: "hero-chat-bubble-left-right"},
    %{path: "/board", label: "Board", icon: "hero-view-columns"},
    %{path: "/uploads", label: "Uploads", icon: "hero-arrow-up-tray"},
    %{path: "/js-commands", label: "JS Commands", icon: "hero-command-line"},
    %{path: "/async", label: "Async Explorer", icon: "hero-bolt"}
  ]

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  attr :presences, :map, default: %{}
  attr :current_path, :string, default: "/"
  slot :inner_block, required: true

  def app(assigns) do
    assigns = assign(assigns, :nav_items, @nav_items)

    ~H"""
    <div class="drawer lg:drawer-open">
      <input id="sidebar-toggle" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content flex flex-col">
        <!-- Mobile navbar -->
        <div class="navbar bg-base-100 lg:hidden border-b border-base-300">
          <div class="flex-none">
            <label for="sidebar-toggle" class="btn btn-square btn-ghost drawer-button">
              <.icon name="hero-bars-3" class="size-5" />
            </label>
          </div>
          <div class="flex-1">
            <span class="text-lg font-bold px-2">Pulse</span>
          </div>
          <div class="flex-none">
            <.theme_toggle />
          </div>
        </div>
        
    <!-- Main content -->
        <main class="flex-1 p-4 lg:p-6">
          {render_slot(@inner_block)}
        </main>
      </div>
      
    <!-- Sidebar -->
      <div class="drawer-side z-40">
        <label for="sidebar-toggle" aria-label="close sidebar" class="drawer-overlay"></label>
        <aside class="bg-base-100 border-r border-base-300 min-h-full w-64 flex flex-col">
          <!-- Logo -->
          <div class="p-4 border-b border-base-300">
            <div class="flex items-center gap-3">
              <div class="size-9 rounded-lg bg-primary flex items-center justify-center">
                <.icon name="hero-bolt" class="size-5 text-primary-content" />
              </div>
              <div>
                <h1 class="font-bold text-lg">Pulse</h1>
                <p class="text-xs text-base-content/60">LiveView Showcase</p>
              </div>
            </div>
          </div>
          
    <!-- Navigation -->
          <nav class="flex-1 p-3">
            <ul class="menu menu-sm gap-1">
              <li :for={item <- @nav_items}>
                <.link
                  navigate={item.path}
                  class={if active_path?(@current_path, item.path), do: "active", else: ""}
                >
                  <.icon name={item.icon} class="size-4" />
                  {item.label}
                </.link>
              </li>
            </ul>
          </nav>
          
    <!-- Online users -->
          <div class="p-4 border-t border-base-300">
            <div class="flex items-center gap-2 text-sm text-base-content/60 mb-2">
              <span class="relative flex size-2">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opacity-75">
                </span>
                <span class="relative inline-flex rounded-full size-2 bg-success"></span>
              </span>
              {map_size(@presences)} online
            </div>
            <div class="flex flex-wrap gap-1">
              <div
                :for={{_id, %{metas: [meta | _]}} <- @presences}
                class="tooltip tooltip-top"
                data-tip={meta.name}
              >
                <div
                  class="size-7 rounded-full flex items-center justify-center text-xs font-bold text-white"
                  style={"background-color: #{meta.color}"}
                >
                  {String.first(meta.name)}
                </div>
              </div>
            </div>
          </div>
          
    <!-- Theme toggle + version -->
          <div class="p-4 border-t border-base-300 flex items-center justify-between">
            <.theme_toggle />
            <span class="text-xs text-base-content/40">
              Phoenix {Application.spec(:phoenix, :vsn)}
            </span>
          </div>
        </aside>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  defp active_path?(current_path, item_path) do
    if item_path == "/" do
      current_path == "/"
    else
      String.starts_with?(current_path, item_path)
    end
  end

  def flash_group(assigns) do
    ~H"""
    <div id="flash-group" aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
