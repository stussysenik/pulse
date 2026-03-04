defmodule PulseWeb.Router do
  use PulseWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug PulseWeb.Plugs.AssignScope
    plug :fetch_live_flash
    plug :put_root_layout, html: {PulseWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", PulseWeb do
    pipe_through :browser

    live_session :default,
      on_mount: [
        {PulseWeb.Live.Hooks, :assign_scope},
        {PulseWeb.Live.Hooks, :track_presence}
      ] do
      live "/", DashboardLive
      live "/chat", ChatLive
      live "/board", BoardLive
      live "/uploads", UploadsLive
      live "/js-commands", JsCommandsLive
      live "/async", AsyncLive
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:pulse, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PulseWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
