json.array!(@crons) do |crom|
  json.extract! crom, :id, :data, :cnpj, :xml_retorno, :mensagem
  json.url crom_url(crom, format: :json)
end
