defmodule PulseWeb.ChatLiveTest do
  use PulseWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders chat page", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/chat")

    assert html =~ "Chat Room"
    assert html =~ "PubSub"
    assert html =~ "Presence"
    assert html =~ "Streams"
  end

  test "can send a message", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/chat")

    view
    |> form("form", %{message: "Hello from test!"})
    |> render_submit()

    # The message gets broadcast via PubSub and should appear
    assert render(view) =~ "Hello from test!"
  end
end
