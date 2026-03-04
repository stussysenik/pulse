defmodule PulseWeb.DashboardLive do
  use PulseWeb, :live_view

  alias Pulse.Dashboard.Stats

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign_async(:system_stats, fn ->
        {:ok, %{system_stats: Stats.fetch_system_stats()}}
      end)
      |> assign_async(:chart_data, fn ->
        {:ok, %{chart_data: Stats.fetch_chart_data()}}
      end)
      |> stream_async(:activity_feed, fn -> Enum.to_list(Stats.activity_feed_stream()) end)

    {:ok, socket}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    presences = PulseWeb.Presence.list("pulse:presence")
    {:noreply, assign(socket, :presences, presences)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      presences={@presences}
      current_path={@current_path}
    >
      <.page_header title="Dashboard" subtitle="Real-time system overview with async data loading">
        <:badges>
          <.feature_badge feature="assign_async" version="LV 1.0" />
          <.feature_badge feature="stream_async" version="LV 1.1" />
          <.feature_badge feature="Presence" version="Phoenix" />
        </:badges>
      </.page_header>
      
    <!-- Online Users -->
      <.code_sample title="Presence — Online Users" id="presence-demo" code={presence_code()}>
        <:demo>
          <div class="flex items-center gap-3 mb-3">
            <div class="badge badge-success gap-1">
              <span class="size-2 rounded-full bg-success-content animate-pulse"></span>
              {map_size(@presences)} online
            </div>
          </div>
          <div class="flex flex-wrap gap-2">
            <div
              :for={{_id, %{metas: [meta | _]}} <- @presences}
              class="flex items-center gap-2 bg-base-200 rounded-full px-3 py-1"
            >
              <div
                class="size-6 rounded-full flex items-center justify-center text-xs font-bold text-white"
                style={"background-color: #{meta.color}"}
              >
                {String.first(meta.name)}
              </div>
              <span class="text-sm">{meta.name}</span>
            </div>
          </div>
        </:demo>
      </.code_sample>
      
    <!-- System Stats -->
      <.code_sample title="assign_async — System Stats" id="stats-demo" code={stats_code()}>
        <:demo>
          <.async_state :let={stats} result={@system_stats}>
            <:loading>Loading system stats...</:loading>
            <:failed>Failed to fetch stats</:failed>
            <div class="grid grid-cols-3 gap-3">
              <div class="stat bg-base-200 rounded-lg p-3">
                <div class="stat-title text-xs">CPU</div>
                <div class="stat-value text-lg">{stats.cpu}%</div>
                <progress class="progress progress-primary w-full" value={stats.cpu} max="100">
                </progress>
              </div>
              <div class="stat bg-base-200 rounded-lg p-3">
                <div class="stat-title text-xs">Memory</div>
                <div class="stat-value text-lg">{stats.memory}%</div>
                <progress class="progress progress-secondary w-full" value={stats.memory} max="100">
                </progress>
              </div>
              <div class="stat bg-base-200 rounded-lg p-3">
                <div class="stat-title text-xs">Disk</div>
                <div class="stat-value text-lg">{stats.disk}%</div>
                <progress class="progress progress-accent w-full" value={stats.disk} max="100">
                </progress>
              </div>
            </div>
          </.async_state>
        </:demo>
      </.code_sample>
      
    <!-- Chart Data -->
      <.code_sample title="assign_async — Chart Data" id="chart-demo" code={chart_code()}>
        <:demo>
          <.async_state :let={data} result={@chart_data}>
            <:loading>Loading chart data...</:loading>
            <div class="overflow-x-auto">
              <div class="flex items-end gap-1 h-32">
                <div
                  :for={point <- data}
                  class="flex-1 bg-primary/80 hover:bg-primary rounded-t transition-colors tooltip tooltip-top"
                  style={"height: #{point.visitors / 100}%"}
                  data-tip={"#{point.month}: #{point.visitors}"}
                >
                </div>
              </div>
              <div class="flex gap-1 mt-1">
                <div :for={point <- data} class="flex-1 text-center text-[10px] text-base-content/50">
                  {point.month}
                </div>
              </div>
            </div>
          </.async_state>
        </:demo>
      </.code_sample>
      
    <!-- Activity Feed -->
      <.code_sample title="stream_async — Activity Feed" id="feed-demo" code={feed_code()}>
        <:demo>
          <div id="activity-feed" phx-update="stream" class="space-y-2 max-h-64 overflow-y-auto">
            <div
              :for={{dom_id, event} <- @streams.activity_feed}
              id={dom_id}
              class="flex items-center gap-3 bg-base-200 rounded-lg p-2 text-sm"
            >
              <div class="size-8 rounded-full bg-primary/20 flex items-center justify-center text-xs font-bold">
                {String.first(event.user) |> String.upcase()}
              </div>
              <div class="flex-1">
                <span class="font-medium">{event.user}</span>
                <span class="text-base-content/60">{event.action}</span>
                <span class="font-mono text-xs bg-base-300 px-1 rounded">{event.target}</span>
              </div>
              <time class="text-xs text-base-content/40">
                {Calendar.strftime(event.timestamp, "%H:%M")}
              </time>
            </div>
          </div>
        </:demo>
      </.code_sample>
    </Layouts.app>
    """
  end

  defp presence_code do
    """
    # Presence tracking on mount (hooks.ex)
    Presence.track(self(), topic, scope.id, %{
      name: scope.name,
      color: scope.color
    })

    # Template: keyed comprehension
    <div :for={{_id, %{metas: [meta | _]}} <- @presences}>
      ...
    </div>\
    """
  end

  defp stats_code do
    """
    # In mount/3:
    assign_async(socket, :system_stats, fn ->
      {:ok, %{system_stats: Stats.fetch_system_stats()}}
    end)

    # Template uses AsyncResult with :let
    <.async_state :let={stats} result={@system_stats}>
      <:loading>Loading...</:loading>
      <:failed>Error</:failed>
      <div>{stats.cpu}%</div>
    </.async_state>\
    """
  end

  defp chart_code do
    """
    assign_async(socket, :chart_data, fn ->
      {:ok, %{chart_data: Stats.fetch_chart_data()}}
    end)\
    """
  end

  defp feed_code do
    """
    # stream_async loads items into a stream
    stream_async(socket, :activity_feed, fn ->
      Enum.to_list(Stats.activity_feed_stream())
    end)

    # Template uses phx-update="stream"
    <div id="feed" phx-update="stream">
      <div :for={{dom_id, event} <- @streams.activity_feed}
           id={dom_id}>
        ...
      </div>
    </div>\
    """
  end
end
