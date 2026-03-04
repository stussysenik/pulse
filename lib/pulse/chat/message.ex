defmodule Pulse.Chat.Message do
  defstruct [:id, :sender_id, :sender_name, :sender_color, :body, :inserted_at]

  def new(attrs) do
    %__MODULE__{
      id: Map.get(attrs, :id, gen_id()),
      sender_id: attrs.sender_id,
      sender_name: attrs.sender_name,
      sender_color: attrs.sender_color,
      body: attrs.body,
      inserted_at: Map.get(attrs, :inserted_at, DateTime.utc_now())
    }
  end

  defp gen_id, do: :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
end
