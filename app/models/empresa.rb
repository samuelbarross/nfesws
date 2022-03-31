class Empresa < ActiveRecord::Base
	enum cod_uf: {RO: 11, AC: 12, AM: 12, RR: 14, PA: 15, AP: 16, TO: 17, MA: 21, PI: 22, CE: 23, RN: 24, PB: 25, PE: 26, AL:27, SE: 28, BA: 29, MG: 31, ES: 32, RJ: 33, SP: 35, PR: 41	, SC: 42, RS: 43, MS: 50, MT: 51, GO: 52, DF: 53}

	validates :cnpj,  numericality: true,  length: { is: 14 }
	validates  :nome, :path_certificado, :cod_uf, presence: true

	has_many :usuario_empresas, :dependent => :destroy 
	accepts_nested_attributes_for :usuario_empresas, :allow_destroy => true
	has_many :nota_fiscais


	UNRANSACKABLE_ATTRIBUTES = ["updated_at", "created_at", "ult_nsu", "senha_certificado", "path_certificado"]

	def self.ransackable_attributes auth_object = nil
		(column_names - UNRANSACKABLE_ATTRIBUTES) + _ransackers.keys
	end

end
