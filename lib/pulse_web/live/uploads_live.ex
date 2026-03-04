defmodule PulseWeb.UploadsLive do
  use PulseWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Uploads")
      |> assign(:uploaded_files, [])
      |> allow_upload(:gallery,
        accept: ~w(.jpg .jpeg .png .gif .webp),
        max_entries: 10,
        max_file_size: 10_000_000,
        auto_upload: true
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :gallery, fn %{path: path}, entry ->
        filename = "#{entry.uuid}-#{entry.client_name}"
        dest = Path.join(["priv/static/uploads", filename])
        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{filename}"}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :gallery, ref)}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    presences = PulseWeb.Presence.list("pulse:presence")
    {:noreply, assign(socket, :presences, presences)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      presences={@presences}
      current_path={@current_path}
    >
      <.page_header
        title="Live Uploads"
        subtitle="Drag-and-drop file uploads with real-time progress and previews"
      >
        <:badges>
          <.feature_badge feature="File Uploads" version="LV 1.0" />
          <.feature_badge feature="live_img_preview" version="LV 1.0" />
          <.feature_badge feature="Progress Callbacks" version="LV 1.0" />
        </:badges>
      </.page_header>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <!-- Upload zone -->
        <div class="card bg-base-100 shadow-sm border border-base-300">
          <div class="card-body">
            <h3 class="font-semibold mb-3">Upload Images</h3>

            <form id="upload-form" phx-submit="save" phx-change="validate">
              <div
                phx-drop-target={@uploads.gallery.ref}
                class="border-2 border-dashed border-base-300 rounded-lg p-8 text-center hover:border-primary transition-colors cursor-pointer"
              >
                <.icon name="hero-cloud-arrow-up" class="size-12 mx-auto text-base-content/30" />
                <p class="mt-2 text-sm text-base-content/60">
                  Drag & drop images here, or
                </p>
                <label class="btn btn-primary btn-sm mt-2">
                  Browse files <.live_file_input upload={@uploads.gallery} class="hidden" />
                </label>
                <p class="mt-2 text-xs text-base-content/40">
                  Max 10 files, 10MB each. JPG, PNG, GIF, WebP.
                </p>
              </div>
              
    <!-- Upload errors -->
              <div
                :for={err <- upload_errors(@uploads.gallery)}
                class="alert alert-error alert-sm mt-2"
              >
                <.icon name="hero-exclamation-triangle" class="size-4" />
                {upload_error_to_string(err)}
              </div>
              
    <!-- Entries with progress -->
              <div :if={@uploads.gallery.entries != []} class="mt-4 space-y-3">
                <div :for={entry <- @uploads.gallery.entries} class="flex items-center gap-3">
                  <.live_img_preview entry={entry} class="size-12 rounded object-cover" />
                  <div class="flex-1">
                    <p class="text-sm font-medium truncate">{entry.client_name}</p>
                    <progress
                      class="progress progress-primary w-full"
                      value={entry.progress}
                      max="100"
                    >
                    </progress>
                    <div
                      :for={err <- upload_errors(@uploads.gallery, entry)}
                      class="text-xs text-error mt-1"
                    >
                      {upload_error_to_string(err)}
                    </div>
                  </div>
                  <button
                    type="button"
                    phx-click="cancel_upload"
                    phx-value-ref={entry.ref}
                    class="btn btn-ghost btn-xs"
                  >
                    <.icon name="hero-x-mark" class="size-4" />
                  </button>
                </div>
              </div>

              <button
                :if={@uploads.gallery.entries != []}
                type="submit"
                class="btn btn-primary mt-4 w-full"
              >
                <.icon name="hero-arrow-up-tray" class="size-4" />
                Upload {length(@uploads.gallery.entries)} file(s)
              </button>
            </form>
          </div>
        </div>
        
    <!-- Code + uploaded files -->
        <div class="space-y-4">
          <!-- Uploaded gallery -->
          <div :if={@uploaded_files != []} class="card bg-base-100 shadow-sm border border-base-300">
            <div class="card-body">
              <h3 class="font-semibold mb-3">Uploaded Files</h3>
              <div class="grid grid-cols-3 gap-2">
                <div :for={file <- @uploaded_files} class="relative group">
                  <img src={file} class="rounded-lg object-cover w-full aspect-square" />
                </div>
              </div>
            </div>
          </div>
          
    <!-- Code sample -->
          <.code_sample title="Upload Configuration" id="upload-code" code={upload_code()}>
            <:demo>
              <div class="text-sm space-y-1 text-base-content/60">
                <p>Max entries: 10</p>
                <p>Max file size: 10 MB</p>
                <p>Auto-upload: enabled</p>
                <p>Accepted: .jpg, .png, .gif, .webp</p>
              </div>
            </:demo>
          </.code_sample>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 10)"
  defp upload_error_to_string(:not_accepted), do: "File type not accepted"
  defp upload_error_to_string(err), do: "Error: #{inspect(err)}"

  defp upload_code do
    """
    # In mount/3:
    allow_upload(socket, :gallery,
      accept: ~w(.jpg .jpeg .png .gif .webp),
      max_entries: 10,
      max_file_size: 10_000_000,
      auto_upload: true
    )

    # Drag-and-drop target:
    <div phx-drop-target={@uploads.gallery.ref}>
      <.live_file_input upload={@uploads.gallery} />
    </div>

    # Live preview before upload:
    <.live_img_preview entry={entry} />

    # Consume uploaded entries:
    consume_uploaded_entries(socket, :gallery,
      fn %{path: path}, entry ->
        File.cp!(path, dest)
        {:ok, url}
      end
    )\
    """
  end
end
