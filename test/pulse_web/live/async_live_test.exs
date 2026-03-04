defmodule PulseWeb.AsyncLiveTest do
  use PulseWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders async explorer page", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/async")

    assert html =~ "Async Explorer"
    assert html =~ "assign_async"
    assert html =~ "start_async"
    assert html =~ "stream_async"
  end

  test "can update delay slider", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/async")

    render_change(view, "update_delay", %{delay: "2000"})
    assert render(view) =~ "2000ms"
  end

  test "can toggle error simulation", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/async")

    render_click(view, "toggle_fail")
    # Toggle state changed - we verify it doesn't crash
    assert render(view) =~ "Async Explorer"
  end

  test "can run assign_async", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/async")

    render_click(view, "run_assign_async")

    # Wait for async to complete (longer timeout for simulated delays)
    html = render_async(view, 5000)
    assert html =~ "Async Explorer"
  end

  test "can run start_async", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/async")

    render_click(view, "run_start_async")

    # Wait for async to complete (longer timeout for simulated delays)
    html = render_async(view, 5000)
    assert html =~ "Async Explorer"
  end
end
