defmodule PulseWeb.AsyncLive do
  use PulseWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Async Explorer")
      |> assign(:delay, 1500)
      |> assign(:should_fail, false)
      # assign_async panel
      |> assign(:assign_async_result, %Phoenix.LiveView.AsyncResult{})
      |> assign(:assign_async_running, false)
      # start_async panel
      |> assign(:start_async_result, nil)
      |> assign(:start_async_status, :idle)
      # stream_async panel
      |> stream(:async_items, [])
      |> assign(:stream_async_status, :idle)

    {:ok, socket}
  end

  @impl true
  def handle_event("update_delay", %{"delay" => delay}, socket) do
    {:noreply, assign(socket, :delay, String.to_integer(delay))}
  end

  def handle_event("toggle_fail", _params, socket) do
    {:noreply, assign(socket, :should_fail, !socket.assigns.should_fail)}
  end

  # assign_async
  def handle_event("run_assign_async", _params, socket) do
    delay = socket.assigns.delay
    should_fail = socket.assigns.should_fail

    socket =
      socket
      |> assign(:assign_async_running, true)
      |> assign_async(:assign_async_result, fn ->
        Process.sleep(delay)

        if should_fail do
          {:error, :simulated_failure}
        else
          {:ok,
           %{assign_async_result: %{value: :rand.uniform(1000), loaded_at: DateTime.utc_now()}}}
        end
      end)

    {:noreply, socket}
  end

  def handle_event("cancel_assign_async", _params, socket) do
    socket =
      socket
      |> cancel_async(:assign_async_result)
      |> assign(:assign_async_running, false)
      |> assign(:assign_async_result, %Phoenix.LiveView.AsyncResult{})

    {:noreply, socket}
  end

  # start_async
  def handle_event("run_start_async", _params, socket) do
    delay = socket.assigns.delay
    should_fail = socket.assigns.should_fail

    socket =
      socket
      |> assign(:start_async_status, :loading)
      |> start_async(:manual_task, fn ->
        Process.sleep(delay)
        if should_fail, do: {:error, :simulated_failure}, else: {:ok, :rand.uniform(1000)}
      end)

    {:noreply, socket}
  end

  # stream_async
  def handle_event("run_stream_async", _params, socket) do
    delay = socket.assigns.delay
    should_fail = socket.assigns.should_fail

    socket =
      socket
      |> assign(:stream_async_status, :loading)
      |> stream(:async_items, [], reset: true)
      |> stream_async(:async_items, fn ->
        Process.sleep(delay)
        if should_fail, do: raise("Simulated failure")

        for i <- 1..5 do
          %{
            id: "item-#{System.unique_integer([:positive])}",
            label: "Item #{i}",
            value: :rand.uniform(100)
          }
        end
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:manual_task, {:ok, {:ok, value}}, socket) do
    {:noreply,
     socket
     |> assign(:start_async_status, :ok)
     |> assign(:start_async_result, %{value: value, loaded_at: DateTime.utc_now()})}
  end

  def handle_async(:manual_task, {:ok, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:start_async_status, :error)
     |> assign(:start_async_result, reason)}
  end

  def handle_async(:manual_task, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:start_async_status, :error)
     |> assign(:start_async_result, reason)}
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
      <.page_header
        title="Async Explorer"
        subtitle="Side-by-side comparison of all three async patterns"
      >
        <:badges>
          <.feature_badge feature="assign_async" version="LV 1.0" />
          <.feature_badge feature="start_async" version="LV 1.0" />
          <.feature_badge feature="stream_async" version="LV 1.1" />
          <.feature_badge feature="cancel_async" version="LV 1.0" />
        </:badges>
      </.page_header>
      
    <!-- Shared controls -->
      <div class="card bg-base-100 shadow-sm border border-base-300 mb-4">
        <div class="card-body p-4">
          <div class="flex flex-wrap items-center gap-6">
            <div class="flex items-center gap-3">
              <label class="text-sm font-medium">Delay:</label>
              <input
                type="range"
                min="500"
                max="5000"
                step="250"
                value={@delay}
                phx-change="update_delay"
                name="delay"
                class="range range-sm range-primary w-40"
              />
              <span class="text-sm font-mono badge badge-ghost">{@delay}ms</span>
            </div>
            <div class="flex items-center gap-2">
              <label class="text-sm font-medium">Simulate error:</label>
              <input
                type="checkbox"
                class="toggle toggle-error toggle-sm"
                checked={@should_fail}
                phx-click="toggle_fail"
              />
            </div>
          </div>
        </div>
      </div>
      
    <!-- Three panels -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <!-- assign_async panel -->
        <div class="card bg-base-100 shadow-sm border border-base-300">
          <div class="card-body p-4">
            <h3 class="font-semibold flex items-center gap-2">
              <.icon name="hero-arrow-path" class="size-4 text-primary" /> assign_async
            </h3>
            <p class="text-xs text-base-content/60 mb-3">
              Automatic AsyncResult state management
            </p>

            <div class="flex gap-2 mb-3">
              <button class="btn btn-sm btn-primary" phx-click="run_assign_async">
                Run
              </button>
              <button
                class="btn btn-sm btn-outline"
                phx-click="cancel_assign_async"
                disabled={!@assign_async_running}
              >
                Cancel
              </button>
            </div>

            <div class="bg-base-200 rounded-lg p-3 min-h-[80px]">
              <.async_state :let={result} result={@assign_async_result}>
                <:loading>
                  <span class="loading loading-spinner loading-sm"></span> Loading...
                </:loading>
                <:failed>
                  <span class="text-error text-sm">Failed!</span>
                </:failed>
                <div class="text-sm">
                  <div class="stat-value text-lg text-primary">{result.value}</div>
                  <div class="text-xs text-base-content/50 mt-1">
                    at {Calendar.strftime(result.loaded_at, "%H:%M:%S")}
                  </div>
                </div>
              </.async_state>
              <div :if={show_idle?(@assign_async_result)} class="text-sm text-base-content/40">
                Click Run to start
              </div>
            </div>

            <pre class="text-[10px] bg-base-200 rounded p-2 mt-3 overflow-x-auto"><code>{assign_async_code()}</code></pre>
          </div>
        </div>
        
    <!-- start_async panel -->
        <div class="card bg-base-100 shadow-sm border border-base-300">
          <div class="card-body p-4">
            <h3 class="font-semibold flex items-center gap-2">
              <.icon name="hero-play" class="size-4 text-secondary" /> start_async
            </h3>
            <p class="text-xs text-base-content/60 mb-3">
              Manual handle_async/3 callback
            </p>

            <div class="flex gap-2 mb-3">
              <button
                class="btn btn-sm btn-secondary"
                phx-click="run_start_async"
                disabled={@start_async_status == :loading}
              >
                Run
              </button>
            </div>

            <div class="bg-base-200 rounded-lg p-3 min-h-[80px]">
              <div :if={@start_async_status == :idle} class="text-sm text-base-content/40">
                Click Run to start
              </div>
              <div :if={@start_async_status == :loading} class="flex items-center gap-2 text-sm">
                <span class="loading loading-spinner loading-sm"></span> Loading...
              </div>
              <div :if={@start_async_status == :ok} class="text-sm">
                <div class="stat-value text-lg text-secondary">{@start_async_result.value}</div>
                <div class="text-xs text-base-content/50 mt-1">
                  at {Calendar.strftime(@start_async_result.loaded_at, "%H:%M:%S")}
                </div>
              </div>
              <div :if={@start_async_status == :error} class="text-sm text-error">
                Failed: {inspect(@start_async_result)}
              </div>
            </div>

            <pre class="text-[10px] bg-base-200 rounded p-2 mt-3 overflow-x-auto"><code>{start_async_code()}</code></pre>
          </div>
        </div>
        
    <!-- stream_async panel -->
        <div class="card bg-base-100 shadow-sm border border-base-300">
          <div class="card-body p-4">
            <h3 class="font-semibold flex items-center gap-2">
              <.icon name="hero-queue-list" class="size-4 text-accent" /> stream_async
            </h3>
            <p class="text-xs text-base-content/60 mb-3">
              Load items into a stream asynchronously
            </p>

            <div class="flex gap-2 mb-3">
              <button class="btn btn-sm btn-accent" phx-click="run_stream_async">
                Run
              </button>
            </div>

            <div
              id="async-items"
              phx-update="stream"
              class="bg-base-200 rounded-lg p-3 min-h-[80px] space-y-1"
            >
              <div
                :for={{dom_id, item} <- @streams.async_items}
                id={dom_id}
                class="flex items-center justify-between bg-base-100 rounded px-2 py-1 text-sm"
              >
                <span>{item.label}</span>
                <span class="badge badge-sm badge-primary">{item.value}</span>
              </div>
            </div>
            <div :if={@stream_async_status == :loading} class="flex items-center gap-2 text-sm mt-2">
              <span class="loading loading-spinner loading-sm"></span> Loading...
            </div>

            <pre class="text-[10px] bg-base-200 rounded p-2 mt-3 overflow-x-auto"><code>{stream_async_code()}</code></pre>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp show_idle?(result) do
    is_struct(result, Phoenix.LiveView.AsyncResult) and
      !result.loading and !result.ok? and !result.failed
  end

  defp assign_async_code do
    """
    assign_async(socket, :result, fn ->
      {:ok, %{result: compute()}}
    end)

    # Cancel:
    cancel_async(socket, :result)\
    """
  end

  defp start_async_code do
    """
    start_async(socket, :task, fn ->
      {:ok, compute()}
    end)

    # Handle in callback:
    def handle_async(:task, {:ok, result}, socket) do
      {:noreply, assign(socket, result: result)}
    end\
    """
  end

  defp stream_async_code do
    """
    stream_async(socket, :items, fn ->
      for i <- 1..5 do
        %{id: "item-\#{i}", label: "Item \#{i}"}
      end
    end)\
    """
  end
end
