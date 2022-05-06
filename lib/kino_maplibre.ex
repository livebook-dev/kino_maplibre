defimpl Kino.Render, for: Maplibre do
  def to_livebook(ml) do
    ml |> Kino.Maplibre.static() |> Kino.Render.to_livebook()
  end
end
