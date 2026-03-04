defmodule PulseWeb.DashboardLiveTest do
  use PulseWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders dashboard page", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")

    assert html =~ "Dashboard"
    assert html =~ "assign_async"
    assert html =~ "stream_async"
    assert html =~ "Presence"
  end

  test "displays presence section", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "online"
  end

  test "has activity feed container", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "activity-feed"
  end
end
