defmodule PulseWeb.Presence do
  use Phoenix.Presence,
    otp_app: :pulse,
    pubsub_server: Pulse.PubSub
end
