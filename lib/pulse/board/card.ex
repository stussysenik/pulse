defmodule Pulse.Board.Card do
  defstruct [:id, :title, :description, :column, :position, :color]

  def new(attrs) do
    %__MODULE__{
      id: Map.get(attrs, :id, gen_id()),
      title: attrs.title,
      description: Map.get(attrs, :description, ""),
      column: Map.get(attrs, :column, "todo"),
      position: Map.get(attrs, :position, 0),
      color: Map.get(attrs, :color, "#3b82f6")
    }
  end

  defp gen_id, do: :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
end
