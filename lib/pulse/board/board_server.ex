defmodule Pulse.Board.BoardServer do
  @moduledoc """
  GenServer managing kanban board state with PubSub broadcast.
  """
  use GenServer

  alias Pulse.Board.Card

  @topic "board:main"

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def list_cards do
    GenServer.call(__MODULE__, :list_cards)
  end

  def cards_by_column do
    GenServer.call(__MODULE__, :cards_by_column)
  end

  def add_card(attrs) do
    GenServer.call(__MODULE__, {:add_card, attrs})
  end

  def move_card(card_id, column, position) do
    GenServer.call(__MODULE__, {:move_card, card_id, column, position})
  end

  def delete_card(card_id) do
    GenServer.call(__MODULE__, {:delete_card, card_id})
  end

  def topic, do: @topic

  # Server

  @impl true
  def init(_) do
    cards = seed_cards()
    {:ok, %{cards: cards}}
  end

  @impl true
  def handle_call(:list_cards, _from, state) do
    {:reply, state.cards, state}
  end

  def handle_call(:cards_by_column, _from, state) do
    grouped =
      state.cards
      |> Enum.group_by(& &1.column)
      |> Map.put_new("todo", [])
      |> Map.put_new("in_progress", [])
      |> Map.put_new("done", [])
      |> Map.new(fn {col, cards} ->
        {col, Enum.sort_by(cards, & &1.position)}
      end)

    {:reply, grouped, state}
  end

  def handle_call({:add_card, attrs}, _from, state) do
    card = Card.new(attrs)
    cards = [card | state.cards]
    broadcast(:cards_updated)
    {:reply, {:ok, card}, %{state | cards: cards}}
  end

  def handle_call({:move_card, card_id, column, position}, _from, state) do
    cards =
      Enum.map(state.cards, fn card ->
        if card.id == card_id do
          %{card | column: column, position: position}
        else
          card
        end
      end)

    broadcast(:cards_updated)
    {:reply, :ok, %{state | cards: cards}}
  end

  def handle_call({:delete_card, card_id}, _from, state) do
    cards = Enum.reject(state.cards, &(&1.id == card_id))
    broadcast(:cards_updated)
    {:reply, :ok, %{state | cards: cards}}
  end

  defp broadcast(event) do
    Phoenix.PubSub.broadcast(Pulse.PubSub, @topic, event)
  end

  defp seed_cards do
    [
      Card.new(%{title: "Design landing page", column: "done", position: 0, color: "#22c55e"}),
      Card.new(%{title: "Set up CI/CD pipeline", column: "done", position: 1, color: "#3b82f6"}),
      Card.new(%{
        title: "Implement auth flow",
        column: "in_progress",
        position: 0,
        color: "#8b5cf6"
      }),
      Card.new(%{title: "Write API docs", column: "in_progress", position: 1, color: "#f97316"}),
      Card.new(%{title: "Add dark mode", column: "todo", position: 0, color: "#ec4899"}),
      Card.new(%{title: "Performance audit", column: "todo", position: 1, color: "#14b8a6"}),
      Card.new(%{title: "User onboarding", column: "todo", position: 2, color: "#eab308"})
    ]
  end
end
