defmodule PulseWeb.BoardLiveTest do
  use PulseWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders board page with columns", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/board")

    assert html =~ "Collaborative Board"
    assert html =~ "To Do"
    assert html =~ "In Progress"
    assert html =~ "Done"
  end

  test "can add a card", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/board")

    view
    |> form("form", %{title: "Test Card"})
    |> render_submit()

    assert render(view) =~ "Test Card"
  end
end
