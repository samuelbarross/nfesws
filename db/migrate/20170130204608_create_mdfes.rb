class CreateMdfes < ActiveRecord::Migration
	def change
    	create_table :mdfes do |t|
			t.string :chave_mdfe, limit: 44
			t.string :codigo_uf, limit: 2
			t.string :tipo_ambiente, limit: 1
			t.string :tipo_emitente, limit: 1
			t.string :tipo_transportador, limit: 1
			t.string :modelo, limit: 2
			t.string :serie, limit: 3
			t.string :numero_manifesto, limit: 9
			t.string :codigo_manifesto, limit: 8
			t.string :codigo_dv, limit: 1
			t.string :modal, limit: 1
			t.datetime :data_hora_emissao
			t.string :tipo_emissao, limit: 1
			t.string :processo_emissao, limit: 1
			t.string :versao_processo_emissao, limit: 20
			t.string :uf_inicio, limit: 2
			t.string :uf_fim, limit: 2
			t.string :codigo_municipio_carrega, limit: 7
			t.string :nome_municipio_carrega
			t.string :percurso, limit: 60
			t.datetime :data_hora_inicio_viagem
			t.string :cnpj_emitente, limit: 14
			t.string :inscricao_estadual_emitente, limit: 14
			t.string :nome_emitente, limit: 60
			t.string :nome_fantasia_emitente, limit: 60
			t.string :logradouro_emitente, limit: 60
			t.string :numero_endereco_emitente, limit: 60
			t.string :complemento_endereco_emitente, limit: 60
			t.string :bairro_emitente, limit: 60
			t.string :codigo_municipio_emitente, limit: 7
			t.string :nome_municipio_emitente, limit: 60
			t.string :cep_emitente, limit: 8
			t.string :uf_emitente, limit: 2
			t.string :fone_emitente, limit: 12
			t.string :email_emitente, limit: 60
			t.string :versao_modal, limit: 4
			t.string :rntrc, limit: 8
			t.string :ciot, limit: 12
			t.string :codigo_interno_veiculo_tracao, limit: 10
			t.string :placa_tracao, limit: 7
			t.string :renavam_tracao, limit: 11
	  		t.string :tara_tracao, limit: 6
	  		t.string :capacidade_tracao_kg, limit: 6
      		t.string :capacidade_tracao_m3, limit: 3
      		t.string :proprietario_tracao_cpf, limit: 11
      		t.string :proprietario_tracao_cnpj, limit: 14
      		t.string :proprietatio_tracao_rntrc, limit: 8
      		t.string :proprietario_tracao_nome, limit: 60
      		t.string :proprietario_tracao_ie, limit: 14
      		t.string :proprietario_tracao_uf, limit: 2
      		t.string :tipo_proprietario_tracao, limit: 1
		    t.string :condutor1_tracao_nome, limit: 60
		    t.string :condutor1_tracao_cpf, limit: 11
		    t.string :condutor2_tracao_nome, limit: 60
		    t.string :condutor2_tracao_cpf, limit: 11		    
      		t.string :tipo_rodado, limit: 2
      		t.string :tipo_carroceria_tracao, limit: 2
      		t.string :veliculo_tracao_licenciado_uf, limit: 2
			t.string :codigo_interno_veiculo_reboque, limit: 10
			t.string :placa_reboque, limit: 7
			t.string :renavam_reboque, limit: 11
	  		t.string :tara_reboque, limit: 6
	  		t.string :capacidade_reboque_kg, limit: 6
      		t.string :capacidade_reboque_m3, limit: 3
      		t.string :proprietario_reboque_cpf, limit: 11
      		t.string :proprietario_reboque_cnpj, limit: 14
      		t.string :proprietatio_reboque_rntrc, limit: 8
      		t.string :proprietario_reboque_nome, limit: 60
      		t.string :proprietario_reboque_ie, limit: 14
      		t.string :proprietario_reboque_uf, limit: 2
      		t.string :tipo_proprietario_reboque, limit: 1
      		t.string :tipo_carroceria_reboque, limit: 2
      		t.string :veliculo_reboque_licenciado_uf, limit: 2
      		t.string :codigo_municipio_descarga, limit: 7
      		t.string :nome_municipio_descarga, limit: 60
      		t.string :quantidade_total_cte, limit: 4
      		t.string :quantidade_total_nfe, limit: 4
      		t.string :valor_total_carga,  precision: 15, scale: 2
      		t.string :unidade_peso_bruto_carga, limit: 2
      		t.string :peso_bruto_carga,  precision: 15, scale: 4
      		t.text :informacoes_adcionais_fisco
      		t.text :informacoes_complementares

      		t.timestamps
    	end
  	end
end
