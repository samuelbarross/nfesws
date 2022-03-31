json.array!(@dominio_valores) do |dominio_valor|
  json.extract! dominio_valor, :id, :codigo, :descricao, :dominio_id
  json.url dominio_valor_url(dominio_valor, format: :json)
end
