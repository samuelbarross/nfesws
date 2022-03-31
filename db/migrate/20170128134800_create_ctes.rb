class CreateCtes < ActiveRecord::Migration
  def change
    create_table :ctes do |t|
      t.string :chave_cte, limit: 44
      t.string :codigo_uf, limit: 2
      t.string :codigo_ct, limit: 8
      t.string :codigo_fop, limit: 4
      t.string :natureza_operacao, limit: 60
      t.string :forma_pagamento, limit: 1
      t.string :modelo, limit: 2
      t.string :serie, limit: 3
      t.string :numero_ct, limit: 9
      t.datetime :data_hora_emissao
      t.string :tipo_impressao, limit: 1
      t.string :tipo_emissao, limit: 1
      t.string :codigo_dv, limit: 1
      t.string :tipo_ambiente, limit: 1
      t.string :tipo_cte, limit: 1
      t.string :processo_emissao, limit: 1
      t.string :versao_processo_emissao, limit: 20
      t.string :cte_referenciado, limit: 44
      t.string :codigo_municipio_envio, limit: 7
      t.string :nome_municipio_envio, limit: 60
      t.string :uf_envio, limit: 2
      t.string :modal, limit: 2
      t.string :tipo_servico, limit: 1
      t.string :codigo_municipio_inicio, limit: 7
      t.string :nome_municipio_inicio, limit: 60
      t.string :uf_inicio, limit: 2
      t.string :codigo_municipio_fim, limit: 7
      t.string :nome_municipio_fim, limit: 60
      t.string :uf_fim, limit: 2
      t.string :retira, limit: 1
      t.string :detalhes_retira, limit: 160
      t.string :toma, limit: 1
      t.string :cnpj_tomador, limit: 14
      t.string :cpf_tomador, limit: 11
      t.string :ie_tomador, limit: 14
      t.string :nome_tomador, limit: 60
      t.string :nome_fantasia_tomador, limit: 60
      t.string :fone_tomador, limit: 14
      t.string :logradouro_tomador
      t.string :numero_endereco_tomador, limit: 60
      t.string :endereco_complemento_tomador, limit: 60
      t.string :bairro_tomador, limit: 60
      t.string :codigo_municipio_tomador, limit: 7
      t.string :nome_municipio_tomador, limit: 60
      t.string :cep_tomador, limit: 8
      t.string :uf_tomador, limit: 2
      t.string :codigo_pais_tomador, limit: 4
      t.string :nome_pais_tomador, limit: 60
      t.string :email_tomador, limit: 60
      t.text :observacoes
      t.integer :identificador_cte
      t.integer :codigo_remetente
      t.integer :codigo_destinatario
      t.text :observacoes_cliente
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
      t.string :fone_emitente, limit: 14
      t.string :cnpj_remetente, limit: 14
      t.string :cpf_remetente, limit: 11
      t.string :inscricao_estadual_remetente, limit: 14
      t.string :nome_remetente, limit: 60
      t.string :nome_fantasia_remetente, limit: 60
      t.string :fone_remetente, limit: 14
      t.string :logradouro_remetente
      t.string :numero_endereco_remetente, limit: 60
      t.string :complemento_endereco_remetente, limit: 60
      t.string :bairro_remetente, limit: 60
      t.string :codigo_municipio_remetente, limit: 7
      t.string :nome_municipio_remetente, limit: 60
      t.string :cep_remetente, limit: 8
      t.string :uf_remetente, limit: 2
      t.string :codigo_pais_remetente, limit: 4
      t.string :nome_pais_remetente, limit: 60
      t.string :email_remetente, limit: 60
      t.string :cnpj_destinatario, limit: 14
      t.string :cpf_destinatario, limit: 11
      t.string :inscricao_estadual_destinatario, limit: 14
      t.string :nome_destinatario, limit: 60
      t.string :fone_destinatario, limit: 14
      t.string :suframa_destinatario, limit: 9
      t.string :logradouro_destinatario
      t.string :numero_endereco_destinatario, limit: 60
      t.string :complemento_endereco_destinatario, limit: 60
      t.string :bairro_destinatario, limit: 60
      t.string :codigo_municipio_destinatario, limit: 7
      t.string :nome_municipio_destinatario, limit: 60
      t.string :cep_destinatario, limit: 8
      t.string :uf_destinatario, limit: 2
      t.string :codigo_pais_destinatario, limit: 4
      t.string :nome_pais_destinatario, limit: 60
      t.string :email_destinatario, limit: 60
      t.decimal :valor_total_prestacao_servico, precision: 15, scale: 2
      t.string :valor_receber, precision: 15, scale: 2
      t.decimal :valor_frete_peso, precision: 13, scale: 2
      t.decimal :valor_frete, precision: 15, scale: 2
      t.decimal :valor_debito_credito, precision: 15, scale: 2
      t.decimal :valor_cat, precision: 15, scale: 2
      t.decimal :valor_pedagio, precision: 15, scale: 2
      t.decimal :valor_despacho, precision: 15, scale: 2
      t.decimal :valor_gris, precision: 15, scale: 2
      t.decimal :valor_itr, precision: 15, scale: 2
      t.decimal :valor_outros_ademe, precision: 15, scale: 2
      t.string :classificacao_tributaria_servico, limit: 2
      t.decimal :valor_bc_icms, precision: 15, scale: 2
      t.decimal :percentual_aliquota_icms, precision: 5, scale: 2
      t.decimal :valor_icms, precision: 15, scale: 2
      t.decimal :percentual_reducao_bc, precision: 5, scale: 2
      t.decimal :valor_bc_icms_st_retido, precision: 15, scale: 2
      t.decimal :valor_icms_st_retido, precision: 15, scale: 2
      t.decimal :percentual_aliquota_icms_retido, precision: 5, scale: 2
      t.decimal :valor_credito, precision: 15, scale: 2
      t.decimal :percentual_reducao_bc_outra_uf, precision: 5, scale: 2
      t.decimal :valor_bc_icms_outra_uf, precision: 15, scale: 2
      t.decimal :percentual_aliquota_icms_outra_uf, precision: 5, scale: 2
      t.decimal :valor_icms_outra_uf, precision: 15, scale: 2
      t.string :indicador_icms_sn, limit: 1
      t.decimal :valor_total_tributos, precision: 15, scale: 2
      t.text :informacoes_adicionais_fisco
      t.decimal :valor_carga, precision: 15, scale: 2
      t.string :produto_predominante, limit: 60
      t.string :outras_caracteristicas_carga, limit: 30
      t.string :unidade_peso_bruto, limit: 2
      t.string :medida_peso_bruto, limit: 20
      t.decimal :quantidade_peso_bruto, precision: 15, scale: 4
      t.string :unidade_peso_base_calculo, limit: 2
      t.string :medida_peso_base_calculo, limit: 20
      t.decimal :quantidade_peso_base_calculo, precision: 15, scale: 4
      t.string :unidade_quantidade_volume, limit: 2
      t.string :medida_quantidade_volume, limit: 20
      t.decimal :quantidade_volume, precision: 15, scale: 4
      t.string :responsavel_seguro, limit: 1
      t.string :nome_seguradora, limit: 30
      t.string :numero_apolice, limit: 20
      t.string :numero_averbacao, limit: 20
      t.decimal :valor_carga_averbacao, precision: 15, scale: 2
      t.string :versao_modal, limit: 4
      t.string :rntrc, limit: 8
      t.date :data_previsao_recebedor
      t.string :lota, limit: 1
      t.string :ciot, limit: 12
      t.string :ambiente_protocolo, limit: 1
      t.string :protocolo_versao_aplicacao, limit: 20
      t.datetime :data_recebimento
      t.string :numero_protocolo, limit: 15
      t.string :digest_value, limit: 28
      t.string :codigo_status_resposta_cte, limit: 3
      t.string :descricao_motivo_status
      t.string :chave_cte_complementar, limit: 44
      
      t.timestamps
    end
  end
end
