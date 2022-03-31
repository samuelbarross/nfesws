json.array!(@empresas) do |empresa|
  json.extract! empresa, :id, :cnpj, :nome, :path_certificado, :senha_certificado, :ult_nsu
  json.url empresa_url(empresa, format: :json)
end
