defimpl Kino.Render, for: MapLibre do
  def to_livebook(ml) do
    ml |> Kino.MapLibre.static() |> Kino.Render.to_livebook()
  end
end

defimpl Kino.Render, for: Kino.MapLibre do
  def to_livebook(ml) do
    ml |> Kino.MapLibre.static() |> Kino.Render.to_livebook()
  end
end
