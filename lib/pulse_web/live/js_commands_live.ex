defmodule PulseWeb.JsCommandsLive do
  use PulseWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "JS Commands")}
  end

  @impl true
  def handle_event("confetti_triggered", _params, socket) do
    {:noreply, put_flash(socket, :info, "Confetti event received on server!")}
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
        title="JS Commands Playground"
        subtitle="All composable client-side JS commands — no server roundtrip"
      >
        <:badges>
          <.feature_badge feature="JS Commands" version="LV 1.0" />
          <.feature_badge feature="Colocated Hook" version="LV 1.1" />
        </:badges>
      </.page_header>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- show / hide / toggle -->
        <.code_sample title="show / hide / toggle" id="js-visibility" code={visibility_code()}>
          <:demo>
            <div class="space-y-3">
              <div class="flex gap-2">
                <button
                  class="btn btn-sm btn-primary"
                  phx-click={
                    JS.show(
                      to: "#demo-box",
                      transition:
                        {"ease-out duration-300", "opacity-0 scale-90", "opacity-100 scale-100"}
                    )
                  }
                >
                  Show
                </button>
                <button
                  class="btn btn-sm btn-secondary"
                  phx-click={
                    JS.hide(
                      to: "#demo-box",
                      transition:
                        {"ease-in duration-200", "opacity-100 scale-100", "opacity-0 scale-90"}
                    )
                  }
                >
                  Hide
                </button>
                <button
                  class="btn btn-sm btn-accent"
                  phx-click={
                    JS.toggle(
                      to: "#demo-box",
                      in: {"ease-out duration-300", "opacity-0 scale-90", "opacity-100 scale-100"},
                      out: {"ease-in duration-200", "opacity-100 scale-100", "opacity-0 scale-90"}
                    )
                  }
                >
                  Toggle
                </button>
              </div>
              <div
                id="demo-box"
                class="bg-primary text-primary-content rounded-lg p-4 text-center font-bold"
              >
                Hello, I'm visible!
              </div>
            </div>
          </:demo>
        </.code_sample>
        
    <!-- add_class / remove_class / toggle_class -->
        <.code_sample
          title="add_class / remove_class / toggle_class"
          id="js-classes"
          code={classes_code()}
        >
          <:demo>
            <div class="space-y-3">
              <div class="flex gap-2 flex-wrap">
                <button
                  class="btn btn-sm btn-primary"
                  phx-click={
                    JS.add_class("rotate-12 scale-110", to: "#class-box", transition: "duration-300")
                  }
                >
                  Add Transform
                </button>
                <button
                  class="btn btn-sm btn-secondary"
                  phx-click={
                    JS.remove_class("rotate-12 scale-110",
                      to: "#class-box",
                      transition: "duration-300"
                    )
                  }
                >
                  Remove Transform
                </button>
                <button
                  class="btn btn-sm btn-accent"
                  phx-click={
                    JS.toggle_class("bg-warning text-warning-content",
                      to: "#class-box",
                      transition: "duration-300"
                    )
                  }
                >
                  Toggle Color
                </button>
              </div>
              <div
                id="class-box"
                class="bg-info text-info-content rounded-lg p-4 text-center font-bold transition-all duration-300"
              >
                Transform me!
              </div>
            </div>
          </:demo>
        </.code_sample>
        
    <!-- set_attribute / remove_attribute / toggle_attribute -->
        <.code_sample
          title="set_attribute / remove_attribute / toggle_attribute"
          id="js-attrs"
          code={attrs_code()}
        >
          <:demo>
            <div class="space-y-3">
              <div class="flex gap-2 flex-wrap">
                <button
                  class="btn btn-sm btn-primary"
                  phx-click={JS.set_attribute({"disabled", ""}, to: "#attr-input")}
                >
                  Disable
                </button>
                <button
                  class="btn btn-sm btn-secondary"
                  phx-click={JS.remove_attribute("disabled", to: "#attr-input")}
                >
                  Enable
                </button>
                <button
                  class="btn btn-sm btn-accent"
                  phx-click={JS.toggle_attribute({"disabled", ""}, to: "#attr-input")}
                >
                  Toggle
                </button>
              </div>
              <input
                id="attr-input"
                type="text"
                value="Try disabling me"
                class="input input-bordered w-full"
                readonly
              />
            </div>
          </:demo>
        </.code_sample>
        
    <!-- focus / push_focus / pop_focus -->
        <.code_sample title="focus / push_focus / pop_focus" id="js-focus" code={focus_code()}>
          <:demo>
            <div class="space-y-3">
              <div class="flex gap-2">
                <button class="btn btn-sm btn-primary" phx-click={JS.focus(to: "#focus-a")}>
                  Focus A
                </button>
                <button class="btn btn-sm btn-secondary" phx-click={JS.push_focus(to: "#focus-b")}>
                  Push Focus B
                </button>
                <button class="btn btn-sm btn-accent" phx-click={JS.pop_focus()}>
                  Pop Focus
                </button>
              </div>
              <input
                id="focus-a"
                type="text"
                placeholder="Input A"
                class="input input-bordered w-full"
              />
              <input
                id="focus-b"
                type="text"
                placeholder="Input B"
                class="input input-bordered w-full"
              />
            </div>
          </:demo>
        </.code_sample>
        
    <!-- dispatch -->
        <.code_sample title="dispatch — Custom Events" id="js-dispatch" code={dispatch_code()}>
          <:demo>
            <div id="confetti-zone" phx-hook="ConfettiListener" class="space-y-3">
              <button
                class="btn btn-primary"
                phx-click={
                  JS.dispatch("pulse:confetti", to: "#confetti-zone")
                  |> JS.push("confetti_triggered")
                }
              >
                <.icon name="hero-sparkles" class="size-4" /> Fire Confetti!
              </button>
              <div id="confetti-output" class="text-sm text-base-content/60 min-h-[2rem]">
                Click the button to dispatch a custom event...
              </div>
            </div>
          </:demo>
        </.code_sample>
        
    <!-- Command chaining -->
        <.code_sample
          title="Command Chaining — 5 Commands in One Click"
          id="js-chaining"
          code={chaining_code()}
        >
          <:demo>
            <div class="space-y-3">
              <button
                class="btn btn-primary"
                phx-click={
                  JS.toggle(
                    to: "#chain-target",
                    in: "fade-in duration-300",
                    out: "fade-out duration-200"
                  )
                  |> JS.toggle_class("bg-success text-success-content", to: "#chain-status")
                  |> JS.set_attribute({"data-clicked", "true"}, to: "#chain-target")
                  |> JS.dispatch("pulse:chained", to: "#chain-target")
                  |> JS.focus(to: "#chain-input")
                }
              >
                Run 5 Chained Commands
              </button>
              <div id="chain-status" class="badge badge-outline transition-colors duration-300">
                Not clicked
              </div>
              <div
                id="chain-target"
                class="bg-secondary text-secondary-content rounded-lg p-4 text-center"
              >
                Chain Target
              </div>
              <input
                id="chain-input"
                type="text"
                placeholder="Focus lands here"
                class="input input-bordered w-full"
              />
            </div>
          </:demo>
        </.code_sample>
        
    <!-- navigate / patch -->
        <.code_sample title="navigate / patch" id="js-nav" code={nav_code()}>
          <:demo>
            <div class="flex gap-2 flex-wrap">
              <button class="btn btn-sm btn-primary" phx-click={JS.navigate(~p"/chat")}>
                Navigate to Chat
              </button>
              <button class="btn btn-sm btn-secondary" phx-click={JS.patch(~p"/js-commands?demo=nav")}>
                Patch (same LV)
              </button>
            </div>
            <p class="text-xs text-base-content/50 mt-2">
              navigate = full page mount, patch = update params in same LiveView
            </p>
          </:demo>
        </.code_sample>
      </div>
    </Layouts.app>
    """
  end

  defp visibility_code do
    """
    JS.show(to: "#demo-box",
      transition: {"ease-out duration-300",
        "opacity-0 scale-90",
        "opacity-100 scale-100"})

    JS.hide(to: "#demo-box", ...)
    JS.toggle(to: "#demo-box", in: ..., out: ...)\
    """
  end

  defp classes_code do
    """
    JS.add_class("rotate-12 scale-110",
      to: "#class-box",
      transition: "duration-300")

    JS.remove_class("rotate-12 scale-110", ...)
    JS.toggle_class("bg-warning", ...)\
    """
  end

  defp attrs_code do
    """
    JS.set_attribute({"disabled", ""},
      to: "#attr-input")
    JS.remove_attribute("disabled",
      to: "#attr-input")
    JS.toggle_attribute({"disabled", ""},
      to: "#attr-input")\
    """
  end

  defp focus_code do
    """
    JS.focus(to: "#focus-a")
    # Push saves current focus to stack
    JS.push_focus(to: "#focus-b")
    # Pop restores previously focused element
    JS.pop_focus()\
    """
  end

  defp dispatch_code do
    """
    # Dispatch custom event + push to server
    JS.dispatch("pulse:confetti",
      to: "#confetti-zone")
    |> JS.push("confetti_triggered")

    # Colocated hook catches it:
    this.el.addEventListener("pulse:confetti",
      () => { /* animate */ })\
    """
  end

  defp chaining_code do
    """
    # Pipe 5 commands together:
    JS.toggle(to: "#target")
    |> JS.toggle_class("bg-success", to: "#status")
    |> JS.set_attribute({"data-clicked", "true"}, ...)
    |> JS.dispatch("pulse:chained", ...)
    |> JS.focus(to: "#chain-input")\
    """
  end

  defp nav_code do
    """
    # Full navigation (unmount + mount new LV):
    JS.navigate(~p"/chat")

    # Patch (stay in same LiveView):
    JS.patch(~p"/js-commands?demo=nav")\
    """
  end
end
