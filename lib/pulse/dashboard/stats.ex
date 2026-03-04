defmodule Pulse.Dashboard.Stats do
  @moduledoc """
  Simulated async data sources with artificial delays for demo purposes.
  """

  def fetch_system_stats do
    Process.sleep(Enum.random(800..1500))

    %{
      cpu: :rand.uniform(100),
      memory: :rand.uniform(100),
      disk: :rand.uniform(100),
      uptime: "#{:rand.uniform(30)}d #{:rand.uniform(24)}h",
      requests: :rand.uniform(50_000),
      errors: :rand.uniform(100)
    }
  end

  def fetch_chart_data do
    Process.sleep(Enum.random(1000..2000))

    for i <- 1..12 do
      %{
        month: Enum.at(~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec), i - 1),
        visitors: :rand.uniform(10_000),
        conversions: :rand.uniform(1_000)
      }
    end
  end

  def activity_feed_stream do
    Stream.resource(
      fn -> 0 end,
      fn counter ->
        Process.sleep(Enum.random(300..800))
        event = generate_event(counter)
        {[event], counter + 1}
      end,
      fn _counter -> :ok end
    )
    |> Stream.take(20)
  end

  defp generate_event(id) do
    actions = ["deployed", "merged PR", "opened issue", "commented on", "reviewed", "pushed to"]
    targets = ["main", "feature/auth", "fix/nav", "docs/api", "chore/deps", "staging"]
    users = ["alice", "bob", "charlie", "diana", "eve", "frank"]

    %{
      id: "event-#{id}",
      user: Enum.random(users),
      action: Enum.random(actions),
      target: Enum.random(targets),
      timestamp: DateTime.utc_now() |> DateTime.add(-:rand.uniform(3600), :second)
    }
  end
end
