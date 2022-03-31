json.array!(@nota_duplicatas) do |nota_duplicata|
  json.extract! nota_duplicata, :id, :nrDuplicata, :dtVencimento, :valorDuplicata, :notaFiscal_id
  json.url nota_duplicata_url(nota_duplicata, format: :json)
end
