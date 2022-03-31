json.array!(@dominio_campos) do |dominio_campo|
  json.extract! dominio_campo, :id, :descricao, :dominio_id
  json.url dominio_campo_url(dominio_campo, format: :json)
end
