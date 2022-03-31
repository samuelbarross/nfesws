class NotaFiscal < ActiveRecord::Base
	has_many :notaProdutos, foreign_key: :notaFiscal_id
	has_many :notaDuplicatas, foreign_key: :notaFiscal_id
	has_many :logs
	belongs_to :empresa

	validates :nrChaveNfe, presence: true, uniqueness: true

	accepts_nested_attributes_for :notaProdutos, :notaDuplicatas, :allow_destroy => true

	UNRANSACKABLE_ATTRIBUTES = ["bairroDestinatario" , "bairroEmitente" ,"cepDestinatario" ,"cepEmitente", "cnaeFiscalEmitente","codConsumidorFinal",
		"codDestinoOperacaoDestinatario","codFinalidadeEmissao","codFormaPagamento","codModeloNfe","codMunicipioDestinatario","codMunicipioEmitente",
		"codMunicipioFatorGeradorICMSEmitente","codPaisDestinatario","codPaisEmitente","codPresencaComprador","codProcessoEmissao","complementoEnderecoEmitente",
		"crtEmitente", "dtRecebimentoNfe","dtSaidaEntradaNfe","emailDestinatario","indicadorIEDestinatario","informacoesComplementaresNfe", "empresa_id",
		"inscricaoEstadualDestinatario","inscricaoEstadualEmitente","inscricaoEstadualSubsTribEmitente","inscricaoMunicipalEmitente", "danfe",
		"inscricaoMunicipalTomadorServico","inscricaoSuframa","logradouroDestinatario","logradouroEmitente","modalidadeFrete","naturezaOperacao",
		"nomeFantasiaEmitente","nrEnderecoDestinatario","nrEnderecoEmitente","nrProtocoloNfe","serieNfe","telefoneDestinatario","telefoneEmitente",
		"tipOperacao", "transporteMarcaDosVolumes", "tipoEmissao","ufDestinatario","ufEmitente","updated_at","valorAproximadoTributos","valorBaseCalculoICMS",
		"valorBaseCalculoICMSST","valorCOFINS","valorFrete","valorICMS","valorICMSDesonerado","valorICMSSubstituicao","valorOutrasDespesasAcessorias","valorPIS",
		"valorSeguro","valorTotalDesconto","valorTotalII","valorTotalIPI","valorTotalProduto","versaoProcesso", "idLoteEvento", "nrSequencialEvento",
		"nrSequencialEvento", "nrProtocoloEvento", "municipioEmitente", "paisEmitente", "paisDestinatario", "complementoEnderecoDestinatario", "transporteQtde",
		"transporteEspecie", "transporteNumeracao", "transportePesoLiquido", "transportePesoBruto", "municipioDestinatario", "entregaCpfCnpj", "entregaLogradouro",
		"entregaNumero", "entregaComplemento", "entregaBairro", "entregaMunicipio", "entregaUF", "xml_completo", "dataRegistroEvento", "cnpj_transportador",
		"cpf_transportador", "nome_transportador", "ie_transportador", "endereco_transportador", "municipio_transportador", "uf_transportador",
		"valor_servico_transporte", "valor_bc_retencao_icms_transporte", "aliquota_retencao_icms_transporte", "valor_icms_retido_transporte", "cfop_transporte",
		"codigo_municipio_fator_gerador_icms_transporte"]

	enum codSituacaoNfe: {Autorizado: 1, Denegado: 2, Cancelada: 3}
	enum codSituacaoManifestacaoDestinatario: {Manifestar: 0, Confirmada: 1, Desconhecida: 2, "Não Realizada": 3, Ciência: 4}
	enum tipo_evento: {"Confirmação da Operação": 210200, "Ciência da Emissão": 210210, "Desconhecimento da Operação": 210220, "Operação não Realizada": 210240}

	def self.ransackable_attributes auth_object = nil
		(column_names - UNRANSACKABLE_ATTRIBUTES) + _ransackers.keys
	end

	def nome_completo_empresa
		emp = Empresa.where(cnpj: self.cpfCnpjDestinatario).first
		"#{emp.nome} - #{cpfCnpjDestinatario}".upcase
	end

	def validade_certificado
		emp = Empresa.where(cnpj: self.cpfCnpjDestinatario).first
		certificado = OpenSSL::X509::Certificate.new(File.read("#{emp.path_certificado}/cert.pem"))
		"Validade do certificado: #{certificado.not_after.strftime("%d/%m/%Y")}".upcase
	end

	def _validade_certificado
		emp = Empresa.where(cnpj: self.cnpj_transportador).first
		certificado = OpenSSL::X509::Certificate.new(File.read("#{emp.path_certificado}/cert.pem"))
		"Validade do certificado: #{certificado.not_after.strftime("%d/%m/%Y")}".upcase
	end

	def baixada
		self.danfe.present?
	end

end
