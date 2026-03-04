defmodule PulseWeb.BoardLive do
  use PulseWeb, :live_view

  alias Pulse.Board.BoardServer

  @columns [
    %{id: "todo", label: "To Do", color: "border-warning"},
    %{id: "in_progress", label: "In Progress", color: "border-info"},
    %{id: "done", label: "Done", color: "border-success"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Pulse.PubSub, BoardServer.topic())
    end

    cards_by_col = BoardServer.cards_by_column()

    socket =
      socket
      |> assign(:page_title, "Board")
      |> assign(:columns, @columns)
      |> assign(:show_modal, false)
      |> assign(:selected_card, nil)
      |> assign(:new_card_title, "")
      |> stream(:todo, Map.get(cards_by_col, "todo", []))
      |> stream(:in_progress, Map.get(cards_by_col, "in_progress", []))
      |> stream(:done, Map.get(cards_by_col, "done", []))

    {:ok, socket}
  end

  @impl true
  def handle_event("card_dropped", %{"id" => id, "column" => column, "index" => index}, socket) do
    BoardServer.move_card(id, column, index)
    {:noreply, socket}
  end

  def handle_event("add_card", %{"title" => title}, socket) when byte_size(title) > 0 do
    BoardServer.add_card(%{title: String.trim(title), column: "todo"})
    {:noreply, assign(socket, :new_card_title, "")}
  end

  def handle_event("add_card", _params, socket), do: {:noreply, socket}

  def handle_event("delete_card", %{"id" => id}, socket) do
    BoardServer.delete_card(id)
    {:noreply, socket}
  end

  def handle_event("show_card", %{"id" => card_id}, socket) do
    card = BoardServer.list_cards() |> Enum.find(&(&1.id == card_id))
    {:noreply, socket |> assign(:selected_card, card) |> assign(:show_modal, true)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  @impl true
  def handle_info(:cards_updated, socket) do
    cards_by_col = BoardServer.cards_by_column()

    socket =
      socket
      |> stream(:todo, Map.get(cards_by_col, "todo", []), reset: true)
      |> stream(:in_progress, Map.get(cards_by_col, "in_progress", []), reset: true)
      |> stream(:done, Map.get(cards_by_col, "done", []), reset: true)

    {:noreply, socket}
  end

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
        title="Collaborative Board"
        subtitle="Drag-and-drop kanban board synced across all clients"
      >
        <:badges>
          <.feature_badge feature="Colocated Hook" version="LV 1.1" />
          <.feature_badge feature="Portals" version="LV 1.1" />
          <.feature_badge feature="PubSub" version="Phoenix" />
          <.feature_badge feature="Streams" version="LV 1.0" />
        </:badges>
      </.page_header>
      
    <!-- Add card form -->
      <form phx-submit="add_card" class="flex gap-2 mb-4">
        <input
          type="text"
          name="title"
          value={@new_card_title}
          placeholder="New card title..."
          class="input input-bordered flex-1"
          autocomplete="off"
        />
        <button type="submit" class="btn btn-primary">
          <.icon name="hero-plus" class="size-4" /> Add Card
        </button>
      </form>
      
    <!-- Board columns -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div :for={col <- @columns} class={["card bg-base-100 shadow-sm border-t-4", col.color]}>
          <div class="card-body p-3">
            <h3 class="font-semibold text-sm flex items-center justify-between">
              {col.label}
            </h3>

            <div
              id={"board-#{col.id}"}
              phx-update="stream"
              phx-hook="SortableHook"
              data-column={col.id}
              class="space-y-2 min-h-[200px] mt-2"
            >
              <div
                :for={{dom_id, card} <- stream_for(assigns, col.id)}
                id={dom_id}
                data-id={card.id}
                class="card bg-base-200 shadow-sm cursor-grab active:cursor-grabbing group"
              >
                <div class="card-body p-3 flex-row items-center gap-2">
                  <div class="size-3 rounded-full flex-none" style={"background-color: #{card.color}"}>
                  </div>
                  <span
                    class="flex-1 text-sm cursor-pointer hover:text-primary"
                    phx-click="show_card"
                    phx-value-id={card.id}
                  >
                    {card.title}
                  </span>
                  <button
                    phx-click="delete_card"
                    phx-value-id={card.id}
                    class="btn btn-ghost btn-xs opacity-0 group-hover:opacity-100"
                  >
                    <.icon name="hero-x-mark" class="size-3" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Card detail modal using portal -->
      <.portal :if={@show_modal} id="card-modal-portal" target="body">
        <div class="modal modal-open">
          <div class="modal-box" phx-click-away="close_modal">
            <button
              class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
              phx-click="close_modal"
            >
              <.icon name="hero-x-mark" class="size-4" />
            </button>
            <div :if={@selected_card}>
              <div class="flex items-center gap-2 mb-4">
                <div class="size-4 rounded-full" style={"background-color: #{@selected_card.color}"}>
                </div>
                <h3 class="text-lg font-bold">{@selected_card.title}</h3>
              </div>
              <div class="badge badge-outline mb-2">{column_label(@selected_card.column)}</div>
              <p class="text-sm text-base-content/60">
                {if @selected_card.description != "",
                  do: @selected_card.description,
                  else: "No description yet."}
              </p>
              <div class="mt-4 pt-4 border-t border-base-300">
                <h4 class="text-xs font-semibold text-base-content/60 mb-2">Portal Demo</h4>
                <pre class="text-[10px] bg-base-200 rounded p-2"><code>{portal_code()}</code></pre>
              </div>
            </div>
          </div>
          <div class="modal-backdrop" phx-click="close_modal"></div>
        </div>
      </.portal>
      
    <!-- Code panel -->
      <div class="mt-4">
        <.code_sample title="Sortable.js Colocated Hook" id="sortable-code" code={sortable_code()}>
          <:demo>
            <p class="text-sm text-base-content/60">
              Drag cards between columns above. Changes sync across all connected clients via PubSub.
            </p>
          </:demo>
        </.code_sample>
      </div>
    </Layouts.app>
    """
  end

  defp stream_for(assigns, column) do
    Map.get(assigns.streams, String.to_atom(column), [])
  end

  defp column_label("todo"), do: "To Do"
  defp column_label("in_progress"), do: "In Progress"
  defp column_label("done"), do: "Done"
  defp column_label(other), do: other

  defp portal_code do
    """
    # This modal uses LiveView 1.1 Portals
    # to render outside the normal DOM hierarchy
    <.portal target="body">
      <div class="modal modal-open">
        ...
      </div>
    </.portal>\
    """
  end

  defp sortable_code do
    """
    # Colocated hook in this file's <script> tag
    export default {
      mounted() {
        new Sortable(this.el, {
          group: "board",
          animation: 150,
          onEnd: (evt) => {
            this.pushEvent("card_dropped", {
              id: evt.item.dataset.id,
              column: evt.to.dataset.column,
              index: evt.newIndex
            })
          }
        })
      }
    }\
    """
  end
end
