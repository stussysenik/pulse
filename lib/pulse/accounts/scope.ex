defmodule Pulse.Accounts.Scope do
  @moduledoc """
  Session-based identity for the showcase app.
  No real auth — just a random name + color per session.
  """

  defstruct [:id, :name, :color]

  @names ~w(Phoenix Elixir Erlang LiveView Bandit Oban Tesla Finch Mint Plug)
  @colors ~w(#ef4444 #f97316 #eab308 #22c55e #14b8a6 #3b82f6 #8b5cf6 #ec4899 #f43f5e #06b6d4)

  def new do
    %__MODULE__{
      id: gen_id(),
      name: Enum.random(@names) <> "-#{:rand.uniform(999)}",
      color: Enum.random(@colors)
    }
  end

  defp gen_id, do: :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
end
