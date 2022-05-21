defmodule KinoMapLibre.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Kino.SmartCell.register(KinoMapLibre.MapCell)

    children = []
    opts = [strategy: :one_for_one, name: KinoMapLibre.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
