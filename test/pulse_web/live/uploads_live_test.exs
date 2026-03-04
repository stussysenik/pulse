defmodule PulseWeb.UploadsLiveTest do
  use PulseWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders uploads page", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/uploads")

    assert html =~ "Live Uploads"
    assert html =~ "File Uploads"
    assert html =~ "Drag"
  end

  test "shows upload form", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/uploads")

    assert html =~ "upload-form"
    assert html =~ "Browse files"
  end
end
