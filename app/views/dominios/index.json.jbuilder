json.array!(@dominios) do |dominio|
  json.extract! dominio, :id, :descricao
  json.url dominio_url(dominio, format: :json)
end
