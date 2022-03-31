# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Empresa.create(cnpj: "70037379000190", nome: "Econômica-Fz", path_certificado: "lib/nfe/certificados/economica-fz", senha_certificado: "catarina", ult_nsu: 0)

dominio1 = Dominio.create(descricao: "Situação NF-e")
Dominio.create(descricao: "Situação da Manifestação do Destinatário")
Dominio.create(descricao: "Tipo Evento")

DominioValor.create(codigo: "1" , descricao: "Uso autorizado no momento da consulta", dominio_id: dominio1.id)
DominioValor.create(codigo: "2" , descricao: "Uso denegado", dominio_id: 1)
DominioValor.create(codigo: "3" , descricao: "NF-e cancelada", dominio_id: 1)

DominioCampo.create(descricao: "DM_SIT_NFE" , dominio_id: 1)

DominioValor.create(codigo: "0" , descricao: "Sem Manifestação do Destinatário", dominio_id: 2)
DominioValor.create(codigo: "1" , descricao: "Confirmada Operação", dominio_id: 2)
DominioValor.create(codigo: "2" , descricao: "Desconhecida", dominio_id: 2)
DominioValor.create(codigo: "3" , descricao: "Operação não Realizada", dominio_id: 2)
DominioValor.create(codigo: "4" , descricao: "Ciência", dominio_id: 2)

DominioCampo.create(descricao: "DM_SIT_CONF" , dominio_id: 2)

DominioValor.create(codigo: "210200" , descricao: "Confirmação da Operação", dominio_id: 3)
DominioValor.create(codigo: "210210" , descricao: "Ciência da Emissão", dominio_id: 3)
DominioValor.create(codigo: "210220" , descricao: "Desconhecimento da Operação", dominio_id: 3)
DominioValor.create(codigo: "210240" , descricao: "Operação não Realizada", dominio_id: 3)

DominioCampo.create(descricao: "DM_TIP_EVE" , dominio_id: 3)
