defmodule PulseWeb.ChatLive do
  use PulseWeb, :live_view

  alias Pulse.Chat.Room
  alias PulseWeb.Presence

  @chat_presence "chat:presence"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Pulse.PubSub, Room.topic())
      Phoenix.PubSub.subscribe(Pulse.PubSub, Room.typing_topic())

      scope = socket.assigns.current_scope

      {:ok, _} =
        Presence.track(self(), @chat_presence, scope.id, %{
          name: scope.name,
          color: scope.color
        })

      Phoenix.PubSub.subscribe(Pulse.PubSub, @chat_presence)
    end

    messages = Room.list_messages()
    chat_presences = Presence.list(@chat_presence)

    socket =
      socket
      |> assign(:page_title, "Chat")
      |> assign(:message_input, "")
      |> assign(:typing_users, %{})
      |> assign(:chat_presences, chat_presences)
      |> stream(:messages, messages)

    {:ok, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => body}, socket) when byte_size(body) > 0 do
    scope = socket.assigns.current_scope

    Room.send_message(%{
      sender_id: scope.id,
      sender_name: scope.name,
      sender_color: scope.color,
      body: String.trim(body)
    })

    {:noreply, assign(socket, :message_input, "")}
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  def handle_event("typing", _params, socket) do
    Room.broadcast_typing(socket.assigns.current_scope)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info({:typing, user_id, user_name}, socket) do
    if user_id != socket.assigns.current_scope.id do
      typing_users =
        Map.put(
          socket.assigns.typing_users,
          user_id,
          {user_name, System.monotonic_time(:millisecond)}
        )

      Process.send_after(self(), {:clear_typing, user_id}, 3000)
      {:noreply, assign(socket, :typing_users, typing_users)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:clear_typing, user_id}, socket) do
    now = System.monotonic_time(:millisecond)

    typing_users =
      case Map.get(socket.assigns.typing_users, user_id) do
        {_name, ts} when is_integer(ts) ->
          if now - ts >= 2900,
            do: Map.delete(socket.assigns.typing_users, user_id),
            else: socket.assigns.typing_users

        _ ->
          socket.assigns.typing_users
      end

    {:noreply, assign(socket, :typing_users, typing_users)}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{event: "presence_diff", topic: @chat_presence},
        socket
      ) do
    chat_presences = Presence.list(@chat_presence)
    {:noreply, assign(socket, :chat_presences, chat_presences)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    presences = Presence.list("pulse:presence")
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
        title="Chat Room"
        subtitle="Real-time messaging with presence and typing indicators"
      >
        <:badges>
          <.feature_badge feature="PubSub" version="Phoenix" />
          <.feature_badge feature="Presence" version="Phoenix" />
          <.feature_badge feature="Streams" version="LV 1.0" />
          <.feature_badge feature="Colocated Hook" version="LV 1.1" />
        </:badges>
      </.page_header>

      <div class="grid grid-cols-1 lg:grid-cols-4 gap-4">
        <!-- Chat area -->
        <div class="lg:col-span-3 card bg-base-100 shadow-sm border border-base-300">
          <div class="card-body p-0 flex flex-col h-[500px]">
            <!-- Messages -->
            <div
              id="messages"
              phx-update="stream"
              phx-hook="AutoScroll"
              class="flex-1 overflow-y-auto p-4 space-y-3"
            >
              <div
                :for={{dom_id, msg} <- @streams.messages}
                id={dom_id}
                class={[
                  "chat",
                  if(msg.sender_id == @current_scope.id, do: "chat-end", else: "chat-start")
                ]}
              >
                <div class="chat-image">
                  <div
                    class="size-8 rounded-full flex items-center justify-center text-xs font-bold text-white"
                    style={"background-color: #{msg.sender_color}"}
                  >
                    {String.first(msg.sender_name)}
                  </div>
                </div>
                <div class="chat-header text-xs opacity-60">
                  {msg.sender_name}
                  <time class="ml-1">{Calendar.strftime(msg.inserted_at, "%H:%M")}</time>
                </div>
                <div class={[
                  "chat-bubble",
                  if(msg.sender_id == @current_scope.id, do: "chat-bubble-primary", else: "")
                ]}>
                  {msg.body}
                </div>
              </div>
            </div>
            
    <!-- Typing indicator -->
            <div :if={map_size(@typing_users) > 0} class="px-4 py-1 text-xs text-base-content/50">
              {typing_text(@typing_users)} typing
              <span class="loading loading-dots loading-xs"></span>
            </div>
            
    <!-- Input -->
            <form phx-submit="send_message" class="p-3 border-t border-base-300 flex gap-2">
              <input
                type="text"
                name="message"
                value={@message_input}
                placeholder="Type a message..."
                class="input input-bordered flex-1"
                autocomplete="off"
                phx-keydown="typing"
                phx-key="."
                phx-debounce="500"
              />
              <button type="submit" class="btn btn-primary">
                <.icon name="hero-paper-airplane" class="size-4" />
              </button>
            </form>
          </div>
        </div>
        
    <!-- Online users sidebar -->
        <div class="card bg-base-100 shadow-sm border border-base-300">
          <div class="card-body p-4">
            <h3 class="font-semibold text-sm mb-3">
              In Chat ({map_size(@chat_presences)})
            </h3>
            <ul class="space-y-2">
              <li
                :for={{_id, %{metas: [meta | _]}} <- @chat_presences}
                class="flex items-center gap-2"
              >
                <div class="relative">
                  <div
                    class="size-8 rounded-full flex items-center justify-center text-xs font-bold text-white"
                    style={"background-color: #{meta.color}"}
                  >
                    {String.first(meta.name)}
                  </div>
                  <span class="absolute -bottom-0.5 -right-0.5 size-3 bg-success rounded-full border-2 border-base-100">
                  </span>
                </div>
                <span class="text-sm">{meta.name}</span>
              </li>
            </ul>
            
    <!-- Code sample -->
            <div class="mt-4 pt-4 border-t border-base-300">
              <h4 class="text-xs font-semibold text-base-content/60 mb-2">How it works</h4>
              <pre class="text-[10px] bg-base-200 rounded p-2 overflow-x-auto"><code>{chat_code()}</code></pre>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp typing_text(typing_users) do
    names = typing_users |> Map.values() |> Enum.map(fn {name, _ts} -> name end)

    case names do
      [name] -> name <> " is"
      [a, b] -> a <> " and " <> b <> " are"
      _ -> "Several people are"
    end
  end

  defp chat_code do
    """
    # PubSub broadcast
    Room.send_message(attrs)
    # => broadcasts {:new_message, msg}

    # Stream insert on receive
    def handle_info({:new_message, msg}, socket) do
      {:noreply, stream_insert(socket, :messages, msg)}
    end\
    """
  end
end
