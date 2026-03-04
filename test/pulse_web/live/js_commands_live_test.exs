defmodule PulseWeb.JsCommandsLiveTest do
  use PulseWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders JS commands page", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/js-commands")

    assert html =~ "JS Commands Playground"
    assert html =~ "show"
    assert html =~ "hide"
    assert html =~ "toggle"
    assert html =~ "focus"
    assert html =~ "dispatch"
  end

  test "confetti event handler works", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/js-commands")

    render_click(view, "confetti_triggered")
    assert render(view) =~ "Confetti event received on server!"
  end
end
