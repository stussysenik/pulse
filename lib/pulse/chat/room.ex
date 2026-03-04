defmodule Pulse.Chat.Room do
  @moduledoc """
  GenServer-backed chat room with ETS storage and PubSub broadcast.
  """
  use GenServer

  alias Pulse.Chat.Message

  @topic "chat:lobby"
  @typing_topic "chat:typing"
  @max_messages 100

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def send_message(attrs) do
    GenServer.call(__MODULE__, {:send_message, attrs})
  end

  def list_messages do
    GenServer.call(__MODULE__, :list_messages)
  end

  def broadcast_typing(scope) do
    Phoenix.PubSub.broadcast(Pulse.PubSub, @typing_topic, {:typing, scope.id, scope.name})
  end

  def topic, do: @topic
  def typing_topic, do: @typing_topic

  # Server

  @impl true
  def init(_) do
    table = :ets.new(:chat_messages, [:ordered_set, :protected])
    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:send_message, attrs}, _from, state) do
    message = Message.new(attrs)
    :ets.insert(state.table, {message.id, message})
    trim_messages(state.table)
    Phoenix.PubSub.broadcast(Pulse.PubSub, @topic, {:new_message, message})
    {:reply, {:ok, message}, state}
  end

  def handle_call(:list_messages, _from, state) do
    messages =
      :ets.tab2list(state.table)
      |> Enum.map(fn {_id, msg} -> msg end)
      |> Enum.sort_by(& &1.inserted_at, DateTime)

    {:reply, messages, state}
  end

  defp trim_messages(table) do
    size = :ets.info(table, :size)

    if size > @max_messages do
      keys =
        :ets.tab2list(table)
        |> Enum.map(fn {id, msg} -> {id, msg.inserted_at} end)
        |> Enum.sort_by(fn {_id, ts} -> ts end, DateTime)
        |> Enum.take(size - @max_messages)
        |> Enum.each(fn {id, _ts} -> :ets.delete(table, id) end)

      keys
    end
  end
end
