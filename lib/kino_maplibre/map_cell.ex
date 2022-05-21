defmodule KinoMapLibre.MapCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/map_cell"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Map"

  @impl true
  def init(_attrs, ctx) do
    {:ok, ctx, reevaluate_on_change: true}
  end

  @impl true
  def scan_binding(_pid, _binding, _env) do
    :ok
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{}
    {:ok, payload, ctx}
  end

  @impl true
  def handle_info({:scan_binding_result, _data_options, _ml_alias}, ctx) do
    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => _field, "value" => _value}, ctx) do
    {:noreply, ctx}
  end

  @impl true
  def to_attrs(_ctx) do
    %{}
  end

  @impl true
  def to_source(_attrs) do
    "map cell"
  end
end
