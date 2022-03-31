class HomeController < ApplicationController
	before_action :authenticate_user!

	def index

		# @mainTitle = "Welcome in Inspinia Rails Seed Project"
		# @mainDesc = "It is an application skeleton for a typical Ruby on Rails web app. You can use it to quickly bootstrap your webapp projects and dev/prod environment."

		@empresas = UsuarioEmpresa.select("e.id, e.nome").joins("inner join empresas e on (e.id = usuario_empresas.empresa_id)").where("usuario_empresas.user_id = #{current_user.id}")
		@empresa_ini = @empresas.first

		@search = NotaFiscal.search("")

		if !params[:q].nil?
			grafics(params[:q][:id])
		else
			grafics(@empresa_ini.id)
		end
  end

  def grafics(id)
			@dashboard = NotaFiscal.select("count(*) as qt,
		    								cast(sum(nota_fiscais.valorTotalNfe) as decimal(12,2)) as valor,
		                         			sum(case ifnull(danfe, '') when '' then 0 else 1 end) as qt_baixada,
		                         			sum(case codSituacaoNfe when 3 then 1 else 0 end) as qt_cancelada")
		                         	.where("nota_fiscais.dtEmissaoNfe >= date_add('#{Time.now.strftime("%Y/%m/01").to_s}', interval -6 month) and  nota_fiscais.empresa_id = #{id}")

			@grafico = NotaFiscal.select("(year(nota_fiscais.dtEmissaoNfe) * 100) + month(nota_fiscais.dtEmissaoNfe) as ano_mes,
											cast(sum(nota_fiscais.valorTotalNfe) as decimal(12,2)) as valor,
											count(*) as qt_recebida,
											sum(case codSituacaoNfe when 1 then 1 else 0 end) as qt_autorizada,
											sum(case codSituacaoNfe when 3 then 1 else 0 end) as qt_cancelada,
											sum(case ifnull(danfe, '') when '' then 0 else 1 end) as qt_baixada,
											cast(sum((case ifnull(danfe, '') when '' then 0 else nota_fiscais.valorTotalNfe end)) as decimal(12,2)) as valor_baixada")
	 							  .where("nota_fiscais.dtEmissaoNfe >= date_add('#{Time.now.strftime("%Y/%m/01").to_s}', interval -5 month) and  nota_fiscais.empresa_id = #{id}")
								  .group("(year(nota_fiscais.dtEmissaoNfe) * 100) + month(nota_fiscais.dtEmissaoNfe)")
								  .order("1;")
  end
end
