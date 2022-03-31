class Cron < ActiveRecord::Base

	UNRANSACKABLE_ATTRIBUTES = ["created_at" , "updated_at" ,"xml_retorno"]

	def self.ransackable_attributes auth_object = nil
		(column_names - UNRANSACKABLE_ATTRIBUTES) + _ransackers.keys
	end

	def nome_completo_empresa
		emp = Empresa.where(cnpj: self.cnpj).first
		"#{emp.nome} - #{cnpj}".upcase
	end	
end
