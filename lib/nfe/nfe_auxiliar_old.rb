class Nfe


  Consome o serviço NfeStatusServico2 da sefez CE, método desativado
  def self.consultaStatusServico
    begin
      client = Savon::Client.new(wsdl: "https://nfe.sefaz.ce.gov.br/nfe2/services/NfeStatusServico2?wsdl", ssl_cert_file: "/home/samuel/projetos/nfesws/lib/nfe/certificados/economica-fz/cert.pem", ssl_cert_key_file: "/home/samuel/projetos/nfesws/lib/nfe/certificados/economica-fz/key.pem", endpoint: "https://nfe.sefaz.ce.gov.br/nfe2/services/NfeStatusServico2", ssl_verify_mode: :none) # endpoint usado somente para sefaz do CE
      xml = '<?xml version="1.0" encoding="UTF-8"?><soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Header><nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeStatusServico2"><cUF>23</cUF><versaoDados>3.10</versaoDados></nfeCabecMsg></soap12:Header><soap12:Body><nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeStatusServico2"><consStatServ xmlns="http://www.portalfiscal.inf.br/nfe" versao="3.10"><tpAmb>1</tpAmb><cUF>23</cUF><xServ>STATUS</xServ></consStatServ></nfeDadosMsg></soap12:Body></soap12:Envelope>'
      response = client.call(:nfe_status_servico_nf2, xml: xml)
      if response.success?
        data = response.to_array(:nfe_status_servico_nf2_result, :ret_cons_stat_serv).first  # percorre os nós do xml dentro do body "corpo" no retorno do WS
        puts  "Status: " + data[:c_stat] + ", Motivo: " + data[:x_motivo]
      end
      rescue Savon::Error => error
    end
  end


  # Realiza a busca por nosta fiscais destinadas a todas a empresas cadastradas
  # ---------------------------------------------------------------------------
  def self.consultaTodasNfe
  	Empresa.where("senha_certificado is not null and senha_certificado != ''").each do |emp|
      # Verifica a validade do certificado
      # ----------------------------------
      certificado = OpenSSL::X509::Certificate.new(File.read("#{emp.path_certificado}/cert.pem"))
      if !(certificado.not_after.strftime("%d/%m/%Y").to_date - DateTime.now.to_date).to_i.zero? 
    	 consulta_nfe_destinatario(emp)
      end 
    end
  end

  # Consome o serviço NFeConsultaDest da sefaz
  # ------------------------------------------
  def self.consulta_nfe_destinatario(emp)
    begin 
      # xml_exemplo = '<?xml version="1.0" encoding="utf-8"?><soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Header><nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsultaDest"><cUF>23</cUF><versaoDados>1.01</versaoDados></nfeCabecMsg></soap12:Header><soap12:Body><nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsultaDest"><consNFeDest versao="1.01" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>1</tpAmb><xServ>CONSULTAR NFE DEST</xServ><CNPJ>70037379000190</CNPJ><indNFe>2</indNFe><indEmi>0</indEmi><ultNSU>15008979830</ultNSU></consNFeDest></nfeDadosMsg></soap12:Body></soap12:Envelope>'
      client = Savon::Client.new(wsdl: "https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx?wsdl", ssl_cert_file: "#{emp.path_certificado}/cert.pem", ssl_cert_key_file: "#{emp.path_certificado}/key.pem", ssl_verify_mode: :none)
      xml = '<?xml version="1.0" encoding="utf-8"?><soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Header><nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsultaDest"><cUF>' << emp[:cod_uf].to_s << '</cUF><versaoDados>1.01</versaoDados></nfeCabecMsg></soap12:Header><soap12:Body><nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsultaDest"><consNFeDest versao="1.01" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>1</tpAmb><xServ>CONSULTAR NFE DEST</xServ><CNPJ>' << emp.cnpj.to_s  << '</CNPJ><indNFe>0</indNFe><indEmi>0</indEmi><ultNSU>' << emp.ult_nsu.to_s << '</ultNSU></consNFeDest></nfeDadosMsg></soap12:Body></soap12:Envelope>'
      retorno = ""
      response = client.call(:nfe_consulta_nf_dest, xml: xml, advanced_typecasting: false)
      cnpj_destinatario = emp.cnpj
      if response.success?
        data = response.to_array.first
        if data[:nfe_consulta_nf_dest_result][:ret_cons_n_fe_dest][:ind_cont] == "1" || data[:nfe_consulta_nf_dest_result][:ret_cons_n_fe_dest][:ind_cont] == "0" then
          if data[:nfe_consulta_nf_dest_result][:ret_cons_n_fe_dest][:c_stat] == "138" then
            retorno += "#{Time.new} #{emp.nome} #{data}"
            puts retorno
            salvar_consulta_nfe(response, cnpj_destinatario)
          else
            retorno += "#{Time.new} #{emp.nome} #{data}"
            puts retorno
          end          
          emp.update({ult_nsu: data[:nfe_consulta_nf_dest_result][:ret_cons_n_fe_dest][:ult_nsu]})  
        else
          retorno += "#{Time.new} #{emp.nome} #{data}"
          puts retorno
        end
      else
        retorno += "#{Time.new} #{response.to_array.first}"
        puts retorno        
      end
      rescue Savon::Error => error
    end
  end

  # Testa o schema com o xml
  # ------------------------
  def teste_xml_schema
    # Open abre todas as dependências de outros schamas na pasta
    xsd = Nokogiri::XML::Schema(File.open("/home/samuel/Modelos/PL_008f/leiauteConsSitNFe_v3.10.xsd"))
    doc = Nokogiri::XML(File.read("/home/samuel/xml/a.xml"))
    xsd.validate(doc).each do |error|
        puts "Error: #{error}"
    end
  end

=begin
  def self.dominio(nome_campo, dominio_id, valor_dominio_id)
    codigo = VwDominioValores.where(nomeCampo: nome_campo, idDomínio: dominio_id, idValorDomínio: valor_dominio_id).first
  end
=end

  # Salva as informações iniciais da nota
  # -----------------------------------------------------
  def self.salvar_consulta_nfe(response, cnpj_destinatario)
    # arquivo_xml = "/home/samuel/23160211606224000168550010000321751440562100.xml"
    # xml = Nokogiri::XML(File.open(arquivo_xml))
    # xml.remove_namespaces!
    # puts xml.css("resNFe")

    node = Nokogiri::XML(response.xml)
    node.remove_namespaces!

    node.css("resNFe").each do |nfe|
      nf = NotaFiscal.find_by_nrChaveNfe(node.css("chNFe").text)
      if nf.nil?
        nota = NotaFiscal.new
        nota.nrChaveNfe = nfe.css("chNFe").text

        if nfe.css("CNPJ").text != ""
          nota.cpfCnpjEmitente = nfe.css("CNPJ").text
        else
          nota.cpfCnpjEmitente = nfe.css("CPF").text
        end  

        nota.nomeEmitente = nfe.css("xNome").text
        nota.inscricaoEstadualEmitente = nfe.css("IE").text
        nota.dtEmissaoNfe = nfe.css("dEmi").text
        nota.tipOperacao = nfe.css("tpNF").text
        nota.valorTotalNfe = nfe.css("vNF").text
        nota.dtRecebimentoNfe = nfe.css("dhRecbto").text.to_time
        nota.codSituacaoNfe =  nfe.css("cSitNFe").text.to_i
        nota.codSituacaoManifestacaoDestinatario = nfe.css("cSitConf").text.to_i
        nota.cpfCnpjDestinatario = cnpj_destinatario
        nome_destinatario = Empresa.find_by_cnpj(cnpj_destinatario)
        nota.nomeDestinatario = nome_destinatario.nome
        nota.empresa_id = nome_destinatario.id
        nota.save
      else
        if nfe.css("cSitNFe").text != nf.codSituacaoNfe.to_s || nfe.css("cSitConf").text != nf.codSituacaoManifestacaoDestinatario.to_s
          nf.update({
            codSituacaoNfe: nfe.css("cSitNFe").text.to_i, 
            codSituacaoManifestacaoDestinatario: nfe.css("cSitConf").text.to_i
          })
        end
      end
    end 

=begin
    h.each do |k,v|
      # If v is nil, an array is being iterated and the value is k.
      # If v is not nil, a hash is being iterated and the value is v.
      value = v || k
      # if value.is_a?(Hash) || value.is_a?(Array)
      # puts "evaluating: #{value} recursively..."
      # puts k,v[:ch_n_fe]
      if value.is_a?(Hash)
        # Tratando o conteúdo de retorno, web service, da tag :ret, aqui trata se no retorno conter vários hash dentro do array
        if value[:ret].is_a?(Array)
          value[:ret].each_index do |x|
            if value[:ret][x].include?(:res_n_fe)
              nf = NotaFiscal.where(nrChaveNfe: value[:ret][x][:res_n_fe][:ch_n_fe]).first
              if nf.nil?
	              nota = NotaFiscal.new
	              nota[:nrChaveNfe] = value[:ret][x][:res_n_fe][:ch_n_fe]
                if value[:ret][x][:res_n_fe].include?(:cnpj)
	                 nota[:cpfCnpjEmitente] = value[:ret][x][:res_n_fe][:cnpj]
                else
                  nota[:cpfCnpjEmitente] = value[:ret][x][:res_n_fe][:cpf]
                end 
	              nota[:nomeEmitente] = value[:ret][x][:res_n_fe][:x_nome]
	              nota[:inscricaoEstadualEmitente] = value[:ret][x][:res_n_fe][:ie]
	              nota[:dtEmissaoNfe] = value[:ret][x][:res_n_fe][:d_emi]
	              nota[:tipoEmissao] = value[:ret][x][:res_n_fe][:tp_emis] 
	              nota[:valorTotalNfe] = value[:ret][x][:res_n_fe][:v_nf]
	              nota[:dtRecebimentoNfe] = value[:ret][x][:res_n_fe][:dh_recbto]
	              nota[:codSituacaoNfe] =  value[:ret][x][:res_n_fe][:c_sit_n_fe]
	              nota[:codSituacaoManifestacaoDestinatario] = value[:ret][x][:res_n_fe][:c_sit_conf]
	              nota[:cpfCnpjDestinatario] = cnpj_destinatario
	              nomeDestinatario = Empresa.where(cnpj: cnpj_destinatario).first
	              nota[:nomeDestinatario] = nomeDestinatario.nome
	              nota[:empresa_id] = nomeDestinatario.id
	              nota.save
	              nota = nil
              else
                if value[:ret][x][:res_n_fe][:c_sit_n_fe] != nf.codSituacaoNfe || value[:ret][x][:res_n_fe][:c_sit_n_fe] != nf.codSituacaoManifestacaoDestinatario
                  nf.update({codSituacaoNfe: value[:ret][x][:res_n_fe][:c_sit_n_fe], codSituacaoManifestacaoDestinatario: value[:ret][x][:res_n_fe][:c_sit_conf]})
                end
              end
            end
          end
        elsif value[:ret].is_a?(Hash)
          if value[:ret].include?(:res_n_fe)
            nf = NotaFiscal.where(nrChaveNfe: value[:ret][:res_n_fe][:ch_n_fe]).first
            if nf.nil?
	            nota = NotaFiscal.new
	            nota[:nrChaveNfe] = value[:ret][:res_n_fe][:ch_n_fe]
              if value[:ret][:res_n_fe].include?(:cnpj)
	              nota[:cpfCnpjEmitente] = value[:ret][:res_n_fe][:cnpj]
              else
                nota[:cpfCnpjEmitente] = value[:ret][:res_n_fe][:cpf]
              end 
	            nota[:nomeEmitente] = value[:ret][:res_n_fe][:x_nome]
	            nota[:inscricaoEstadualEmitente] = value[:ret][:res_n_fe][:ie]
	            nota[:dtEmissaoNfe] = value[:ret][:res_n_fe][:d_emi]
	            nota[:tipoEmissao] = value[:ret][:res_n_fe][:tp_emis]
	            nota[:valorTotalNfe] = value[:ret][:res_n_fe][:v_nf]
	            nota[:dtRecebimentoNfe] = value[:ret][:res_n_fe][:dh_recbto]
	            nota[:codSituacaoNfe] =  value[:ret][:res_n_fe][:c_sit_n_fe]
	            nota[:codSituacaoManifestacaoDestinatario] = value[:ret][:res_n_fe][:c_sit_conf]
	            nota[:cpfCnpjDestinatario] = cnpj_destinatario
	            nomeDestinatario = Empresa.where(cnpj: cnpj_destinatario).first
	            nota[:nomeDestinatario] = nomeDestinatario.nome
	            nota[:empresa_id] = nomeDestinatario.id
	            nota.save
	            nota = nil
            else
              if value[:ret][:res_n_fe][:c_sit_n_fe] != nf.codSituacaoNfe || value[:ret][:res_n_fe][:c_sit_n_fe] != nf.codSituacaoManifestacaoDestinatario
                nf.update({codSituacaoNfe: value[:ret][:res_n_fe][:c_sit_n_fe], codSituacaoManifestacaoDestinatario: value[:ret][:res_n_fe][:c_sit_conf]})
              end
            end
          end
        end
        salvarConsultaNfe(value, cnpj_destinatario)
        # else
        # MODIFY HERE! Look for what you want to find in the hash here
        # if v is nil, just display the array value
        # puts v ? "key: #{k} value: #{v}" : "array value #{k}"
      end
    end
=end
  end

  # Salva no banco informações sobre o manifesto
  # --------------------------------------------
  def self.salvarManifestacaoDestinatario(h)
    h.each do |k,v|
      value = v || k
      if value.is_a?(Hash)
        # Tratando o conteúdo de retorno, web service, da tag :ret_env_evento, aqui trata se no retorno conter vários hash dentro do array
        if value[:ret_env_evento].is_a?(Array)
          value[:ret_env_evento].each_index do |x|
            nf = NotaFiscal.where(nrChaveNfe: value[:ret_env_evento][:ret_evento][x][:inf_evento][:ch_n_fe]).first
            if !nf.nil?
              if value[:ret_env_evento][:ret_evento][x][:inf_evento][:c_stat] == "135"
                nf[:idLoteEvento] = value[:ret_env_evento][:id_lote]
                nf[:nrSequencialEvento] = value[:ret_env_evento][:ret_evento][x][:inf_evento][:n_seq_evento]
                nf[:dataRegistroEvento] = value[:ret_env_evento][:ret_evento][x][:inf_evento][:dh_reg_evento]
                nf[:nrProtocoloEvento] = value[:ret_env_evento][:ret_evento][x][:inf_evento][:n_prot]
                nf[:codSituacaoManifestacaoDestinatario] = value[:ret_env_evento][:ret_evento][x][:inf_evento][:tp_evento]

                # codCiencia = dominio('DM_TIP_EVE', 3, 10)
                # codConfirmar = dominio('DM_TIP_EVE', 3, 9)
                # if value[:ret_env_evento][:ret_evento][x][:inf_evento][:tp_evento] == codCiencia.CódigoValorDomínio
                #   codSitConf = dominio('DM_SIT_CONF', 2, 8) 
                #   nf[:codSituacaoManifestacaoDestinatario] = codSitConf.CódigoValorDomínio
                # elsif value[:ret_env_evento][:ret_evento][x][:inf_evento][:tp_evento] == codConfirmar.CódigoValorDomínio
                #   codSitConf = dominio('DM_SIT_CONF', 2, 5)
                #   nf[:codSituacaoManifestacaoDestinatario] = codSitConf.CódigoValorDomínio
                # end

                nf.save
                else
                  # Exibir mensagem da reijeição ao usuário, ou algum outro status
                end
            end
          end
        elsif value[:ret_env_evento].is_a?(Hash)
          nf = NotaFiscal.where(nrChaveNfe: value[:ret_env_evento][:ret_evento][:inf_evento][:ch_n_fe]).first
          if !nf.nil?
            if value[:ret_env_evento][:ret_evento][:inf_evento][:c_stat] == "135"
              nf[:idLoteEvento] = value[:ret_env_evento][:id_lote]
              nf[:nrSequencialEvento] = value[:ret_env_evento][:ret_evento][:inf_evento][:n_seq_evento]
              nf[:dataRegistroEvento] = value[:ret_env_evento][:ret_evento][:inf_evento][:dh_reg_evento]
              nf[:nrProtocoloEvento] = value[:ret_env_evento][:ret_evento][:inf_evento][:n_prot]
              
              # codCiencia = dominio('DM_TIP_EVE', 3, 10)
              # codConfirmar = dominio('DM_TIP_EVE', 3, 9)
              # if value[:ret_env_evento][:ret_evento][:inf_evento][:tp_evento] == codCiencia.CódigoValorDomínio
              #   codSitConf = dominio('DM_SIT_CONF', 2, 8)
              #   nf[:codSituacaoManifestacaoDestinatario] = codSitConf.CódigoValorDomínio
              # elsif value[:ret_env_evento][:ret_evento][:inf_evento][:tp_evento] == codConfirmar.CódigoValorDomínio
              #   codSitConf = dominio('DM_SIT_CONF', 2, 5)
              #   nf[:codSituacaoManifestacaoDestinatario] = codSitConf.CódigoValorDomínio
              # end

              if value[:ret_env_evento][:ret_evento][:inf_evento][:tp_evento] == NotaFiscal.tipo_eventos[:"Ciência da Emissão"].to_s
                nf[:codSituacaoManifestacaoDestinatario] = NotaFiscal.codSituacaoManifestacaoDestinatarios[:Ciência]
              elsif value[:ret_env_evento][:ret_evento][:inf_evento][:tp_evento] == NotaFiscal.tipo_eventos[:"Confirmação da Operação"].to_s
                nf[:codSituacaoManifestacaoDestinatario] = NotaFiscal.codSituacaoManifestacaoDestinatarios[:Confirmada]
              end

              nf.save
            else
              # Exibir mensagem da reijeição ao usuário, ou algum outro status
            end
          end
        end
        salvarManifestacaoDestinatario(value)
      end
    end
  end

  # Consome o serviço RecepcaoEvento da sefaz
  # -----------------------------------------
  def self.recepcaoEvento(nfe_id, evento, user_id)
    msg = []
    nota_fiscal = NotaFiscal.find(nfe_id)
    emp = Empresa.where("cnpj = #{nota_fiscal.cpfCnpjDestinatario}").first
    xml = xml_for(evento, emp, nota_fiscal)

    begin
      client = Savon::Client.new(wsdl: "https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx?wsdl", ssl_cert_file: "#{emp.path_certificado}/cert.pem", ssl_cert_key_file: "#{emp.path_certificado}/key.pem", ssl_verify_mode: :none)
      response = client.call(:nfe_recepcao_evento, xml: xml, advanced_typecasting: false)
    rescue Exception => e
      return msg.push "Problema com o servidor da sefaz... #{e.message}"
    end

    if !response.nil?
      if response.success?
        data = response.to_array.first
        # raise
        if data[:nfe_recepcao_evento_result][:ret_env_evento][:ret_evento][:inf_evento][:c_stat] == "135"
          salvarManifestacaoDestinatario(data)  
          acao = "#{evento} - #{data[:nfe_recepcao_evento_result][:ret_env_evento][:ret_evento][:inf_evento][:x_evento]}"
          registrarLog(acao, user_id, nfe_id)
          msg.push data[:nfe_recepcao_evento_result][:ret_env_evento][:ret_evento][:inf_evento][:x_evento]
        else 
          msg.push atualiza_status_nfe(nota_fiscal, h, user_id)[0]
          # msg.push consultaProtocolo(nota_fiscal, emp)  
        end
      end
    else
      msg.push "Ocilação no servidor da sefaz, favor tentar em instantes..."        
    end

  end

  # Monta o xml para da ciência ou confirmar a operação
  # ---------------------------------------------------
  def self.xml_for(evento, emp, nota_fiscal)
    certificado = OpenSSL::PKCS12.new(File.read("#{emp.path_certificado}/certificado.pfx"),"#{emp.senha_certificado}")
    
    # codConfirmar = dominio('DM_TIP_EVE', 3, 9)
    # codCiencia = dominio('DM_TIP_EVE', 3, 10)
    
    # Confirmar
    # if evento == codConfirmar.CódigoValorDomínio
      # tagEvento = '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><infEvento Id="'"ID" << evento << nota_fiscal.nrChaveNfe.to_s << "01"'"><cOrgao>91</cOrgao><tpAmb>1</tpAmb><CNPJ>' << nota_fiscal.cpfCnpjDestinatario.to_s << '</CNPJ><chNFe>' << nota_fiscal.nrChaveNfe.to_s << '</chNFe><dhEvento>' << Time.now.strftime("%Y-%m-%d").to_s << 'T' << Time.now.strftime("%H:%M:%S").to_s << '-03:00</dhEvento><tpEvento>' << evento << '</tpEvento><nSeqEvento>1</nSeqEvento><verEvento>1.00</verEvento><detEvento versao="1.00"><descEvento>Confirmacao da Operacao</descEvento></detEvento></infEvento></evento>'
    # Ciência
    # elsif evento == codCiencia.CódigoValorDomínio
      # tagEvento = '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><infEvento Id="'"ID" << evento << nota_fiscal.nrChaveNfe.to_s << "01"'"><cOrgao>91</cOrgao><tpAmb>1</tpAmb><CNPJ>' << nota_fiscal.cpfCnpjDestinatario.to_s  << '</CNPJ><chNFe>' << nota_fiscal.nrChaveNfe.to_s << '</chNFe><dhEvento>' << Time.now.strftime("%Y-%m-%d").to_s << 'T' << Time.now.strftime("%H:%M:%S").to_s << '-03:00</dhEvento><tpEvento>' << evento << '</tpEvento><nSeqEvento>1</nSeqEvento><verEvento>1.00</verEvento><detEvento versao="1.00"><descEvento>Ciencia da Operacao</descEvento></detEvento></infEvento></evento>'
      # tagEvento = '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><infEvento Id="'"ID" << evento << "2315110015328200016755002000159134191195123201"'"><cOrgao>91</cOrgao><tpAmb>1</tpAmb><CNPJ>' << up.NR_EMP_CGC.to_s << up.NR_EMP_COM_CGC.to_s << up.DV_EMP_CGC.to_s  << '</CNPJ><chNFe>23151100153282000167550020001591341911951232</chNFe><dhEvento>' << Time.now.strftime("%Y-%m-%d").to_s << 'T' << Time.now.strftime("%H:%M:%S").to_s << '-03:00</dhEvento><tpEvento>' << evento << '</tpEvento><nSeqEvento>1</nSeqEvento><verEvento>1.00</verEvento><detEvento versao="1.00"><descEvento>Ciencia da Operacao</descEvento></detEvento></infEvento></evento>'
    # end

    # Confirmar
    # ----------------------
    if evento == NotaFiscal.tipo_eventos[:"Confirmação da Operação"].to_s
      tagEvento = '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><infEvento Id="'"ID" << evento << nota_fiscal.nrChaveNfe.to_s << "01"'"><cOrgao>91</cOrgao><tpAmb>1</tpAmb><CNPJ>' << nota_fiscal.cpfCnpjDestinatario.to_s << '</CNPJ><chNFe>' << nota_fiscal.nrChaveNfe.to_s << '</chNFe><dhEvento>' << Time.now.strftime("%Y-%m-%d").to_s << 'T' << Time.now.strftime("%H:%M:%S").to_s << '-03:00</dhEvento><tpEvento>' << evento << '</tpEvento><nSeqEvento>1</nSeqEvento><verEvento>1.00</verEvento><detEvento versao="1.00"><descEvento>Confirmacao da Operacao</descEvento></detEvento></infEvento></evento>'

    # Ciência
    # ----------------------
    elsif evento == NotaFiscal.tipo_eventos[:"Ciência da Emissão"].to_s
      tagEvento = '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><infEvento Id="'"ID" << evento << nota_fiscal.nrChaveNfe.to_s << "01"'"><cOrgao>91</cOrgao><tpAmb>1</tpAmb><CNPJ>' << nota_fiscal.cpfCnpjDestinatario.to_s  << '</CNPJ><chNFe>' << nota_fiscal.nrChaveNfe.to_s << '</chNFe><dhEvento>' << Time.now.strftime("%Y-%m-%d").to_s << 'T' << Time.now.strftime("%H:%M:%S").to_s << '-03:00</dhEvento><tpEvento>' << evento << '</tpEvento><nSeqEvento>1</nSeqEvento><verEvento>1.00</verEvento><detEvento versao="1.00"><descEvento>Ciencia da Operacao</descEvento></detEvento></infEvento></evento>'
    end

    retorno = assinar(tagEvento, 'infEvento', certificado)
    xml = '<?xml version="1.0" encoding="utf-8"?><soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Header><nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/RecepcaoEvento"><versaoDados>1.00</versaoDados><cUF>' << emp[:cod_uf].to_s << '</cUF></nfeCabecMsg></soap12:Header><soap12:Body><nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/RecepcaoEvento"><envEvento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><idLote>' << nota_fiscal.id.to_s << evento << '</idLote>' << retorno << '</envEvento></nfeDadosMsg></soap12:Body></soap12:Envelope>'
  end

  # Assina o xml para a manifestação
  # --------------------------------
  def self.assinar(xml, assinar_tag, certificado)
    # xml = strip_xml(xml)
    xml = Nokogiri::XML(xml, &:noblanks)
    content_sign = xml.at_css(assinar_tag)
    id_sign = content_sign['Id']

    # 1. Digest Hash for all XML
    xml_canon = content_sign.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
    xml_digest = Base64.encode64(OpenSSL::Digest::SHA1.digest(xml_canon)).strip

    # 2. Add Signature Node
    signature = xml.css("Signature").first
    unless signature
      signature = Nokogiri::XML::Node.new('Signature', xml)
      signature.default_namespace = 'http://www.w3.org/2000/09/xmldsig#'
      xml.root().add_child(signature)
    end

    # 3. Add Elements to Signature Node

    # 3.1 Create Signature Info
    signature_info = Nokogiri::XML::Node.new('SignedInfo', xml)

    # 3.2 Add CanonicalizationMethod
    child_node = Nokogiri::XML::Node.new('CanonicalizationMethod', xml)
    child_node['Algorithm'] = 'http://www.w3.org/2001/10/xml-exc-c14n#'
    child_node['Algorithm'] = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
    signature_info.add_child child_node

    # 3.3 Add SignatureMethod
    child_node = Nokogiri::XML::Node.new('SignatureMethod', xml)
    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#rsa-sha1'
    signature_info.add_child child_node

    # 3.4 Create Reference
    reference = Nokogiri::XML::Node.new('Reference', xml)
    reference['URI'] = "##{id_sign}"

    # 3.5 Add Transforms
    transforms = Nokogiri::XML::Node.new('Transforms', xml)

    child_node  = Nokogiri::XML::Node.new('Transform', xml)
    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature'
    transforms.add_child child_node

    child_node  = Nokogiri::XML::Node.new('Transform', xml)
    child_node['Algorithm'] = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
    transforms.add_child child_node

    reference.add_child transforms

    # 3.6 Add Digest
    child_node  = Nokogiri::XML::Node.new('DigestMethod', xml)
    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#sha1'
    reference.add_child child_node

    # 3.6 Add DigestValue
    child_node  = Nokogiri::XML::Node.new('DigestValue', xml)
    child_node.content = xml_digest
    reference.add_child child_node

    # 3.7 Add Reference and Signature Info
    signature_info.add_child reference
    signature.add_child signature_info

    # 4 Sign Signature
    sign_canon = signature_info.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
    signature_hash = certificado.key.sign(OpenSSL::Digest::SHA1.new, sign_canon)
    signature_value = Base64.encode64(signature_hash).gsub("\n", '')

    # 4.1 Add SignatureValue
    child_node = Nokogiri::XML::Node.new('SignatureValue', xml)
    child_node.content = signature_value
    signature.add_child child_node

    # 5 Create KeyInfo
    key_info = Nokogiri::XML::Node.new('KeyInfo', xml)

    # 5.1 Add X509 Data and Certificate
    x509_data = Nokogiri::XML::Node.new('X509Data', xml)
    x509_certificate = Nokogiri::XML::Node.new('X509Certificate', xml)
    x509_certificate.content = certificado.certificate.to_s.gsub(/\-\-\-\-\-[A-Z]+ CERTIFICATE\-\-\-\-\-/, "").gsub(/\n/,"")

    x509_data.add_child x509_certificate
    key_info.add_child x509_data

    # 5.2 Add KeyInfo
    signature.add_child key_info

    # 6 Add Signature
    xml.root().add_child signature

    # Return XML
    xml.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
  end

  # Consome o serviço NfeDownloadNF da sefaz
  # ----------------------------------------
  def self.nfe_download_nf(nfe_id, user_id)
    msg = []    
    nfe = NotaFiscal.find(nfe_id)
    emp = Empresa.where("cnpj = #{nfe.cpfCnpjDestinatario}").first
    xml = '<?xml version="1.0" encoding="utf-8"?><soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Header><nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeDownloadNF"><versaoDados>1.00</versaoDados><cUF>' << emp[:cod_uf].to_s << '</cUF></nfeCabecMsg></soap12:Header><soap12:Body><nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeDownloadNF"><downloadNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><tpAmb>1</tpAmb><xServ>DOWNLOAD NFE</xServ><CNPJ>' << nfe.cpfCnpjDestinatario.to_s  << '</CNPJ><chNFe>' << nfe.nrChaveNfe.to_s << '</chNFe></downloadNFe></nfeDadosMsg></soap12:Body></soap12:Envelope>'
    begin
      client = Savon::Client.new(wsdl: "https://www.nfe.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx?wsdl", ssl_cert_file: "#{emp.path_certificado}/cert.pem", ssl_cert_key_file: "#{emp.path_certificado}/key.pem", ssl_verify_mode: :none)
      response = client.call(:nfe_download_nf, xml: xml, advanced_typecasting: false)
    rescue Exception => e
      return msg.push "Problema com o servidor da sefaz... #{e.message}"
    end

    if !response.nil?
      if response.success? 
        data = response.to_array.first
        if data[:nfe_download_nf_result][:ret_download_n_fe][:ret_n_fe][:c_stat] == "140"
          salvar_download_nfe(response, nfe)
          registrarLog("Download Nfe", user_id, nfe_id)          
        end
        msg.push data[:nfe_download_nf_result][:ret_download_n_fe][:ret_n_fe][:x_motivo]
        msg.push data[:nfe_download_nf_result][:ret_download_n_fe][:ret_n_fe][:c_stat]
      end
    else
      msg.push "Ocilação no servidor da sefaz, favor tentar em instantes..."  
    end
  end

   # Salva no banco a nfe
   # --------------------
  def self.salvar_download_nfe(response, nfe)   
    node = Nokogiri::XML(response.xml)
    node.remove_namespaces!
    produtos = []
    duplicatas = []

    # Atualizando dados da nota
    # -------------------------------------------
      nfe.nrChaveNfe = node.css("protNFe/infProt/chNFe").text
      nfe.nrNfe = node.css("ide/nNF").text
      nfe.codModeloNfe = node.css("ide/mod").text
      nfe.serieNfe = node.css("ide/serie").text
      nfe.dtEmissaoNfe = node.css("ide/dhEmi").text
      nfe.dtSaidaEntradaNfe = node.css("ide/dhSaiEnt").text
      nfe.valorTotalNfe = node.css("total/ICMSTot/vNF").text
      nfe.codDestinoOperacaoDestinatario = node.css("ide/idDest").text
      nfe.codConsumidorFinal = node.css("ide/indFinal").text
      nfe.codPresencaComprador = node.css("ide/indPres").text
      nfe.codProcessoEmissao = node.css("ide/procEmi").text
      nfe.versaoProcesso = node.css("ide/verProc").text
      nfe.tipoEmissao = node.css("ide/tpEmis").text
      nfe.codFinalidadeEmissao = node.css("ide/finNFe").text
      nfe.naturezaOperacao = node.css("ide/natOp").text
      nfe.tipOperacao = node.css("ide/tpNF").text
      nfe.codFormaPagamento = node.css("ide/indPag").text
      nfe.nrProtocoloNfe = node.css("protNFe/infProt/nProt").text
      nfe.dtRecebimentoNfe = node.css("protNFe/infProt/dhRecbto").text
      nfe.informacoesComplementaresNfe = node.css("infAdic/infCpl").text
      nfe.xml_completo = response.to_xml
      nfe.danfe = response.xpath('//xmlns:nfeProc').to_xml 
      empresa = Empresa.where("cnpj = ? ",  node.css("dest/CNPJ").text)
      nfe.empresa_id = empresa[0].id      

      # Totais da Nota
      # --------------------------------------------------------------
      nfe.valorBaseCalculoICMS = node.css("total/ICMSTot/vBC").text
      nfe.valorICMS = node.css("total/ICMSTot/vICMS").text
      nfe.valorICMSDesonerado = node.css("total/ICMSTot/vICMSDeson").text
      nfe.valorBaseCalculoICMSST = node.css("total/ICMSTot/vBCST").text
      nfe.valorICMSSubstituicao = node.css("total/ICMSTot/vST").text 
      nfe.valorTotalProduto = node.css("total/ICMSTot/vProd").text 
      nfe.valorFrete = node.css("total/ICMSTot/vFrete").text 
      nfe.valorSeguro = node.css("total/ICMSTot/vSeg").text
      nfe.valorOutrasDespesasAcessorias = node.css("total/ICMSTot/vOutro").text                  
      nfe.valorTotalIPI = node.css("total/ICMSTot/vIPI").text
      nfe.valorTotalDesconto = node.css("total/ICMSTot/vDesc").text
      nfe.valorTotalII = node.css("total/ICMSTot/vII").text 
      nfe.valorPIS = node.css("total/ICMSTot/vPIS").text 
      nfe.valorCOFINS = node.css("total/ICMSTot/vCOFINS").text 
      nfe.valorAproximadoTributos = node.css("total/ICMSTot/vTotTrib").text

      # Transporte
      # -------------------------------------------------------------------
      nfe.modalidadeFrete = node.css("transp/modFrete").text 
      nfe.cnpj_transportador = node.css("transp/transporta/CNPJ").text 
      nfe.cpf_transportador = node.css("transp/transporta/CPF").text 
      nfe.nome_transportador = node.css("transp/transporta/xNome").text
      nfe.ie_transportador = node.css("transp/transporta/IE").text 
      nfe.endereco_transportador = node.css("transp/transporta/xEnder").text 
      nfe.municipio_transportador = node.css("transp/transporta/xMun").text 
      nfe.uf_transportador = node.css("transp/transporta/UF").text 
      nfe.valor_servico_transporte = node.css("transp/retTransp/vServ").text 
      nfe.valor_bc_retencao_icms_transporte = node.css("transp/retTransp/vBCRet").text
      nfe.aliquota_retencao_icms_transporte = node.css("transp/retTransp/pICMSRet").text 
      nfe.valor_icms_retido_transporte = node.css("transp/retTransp/vICMSRet").text 
      nfe.cfop_transporte = node.css("transp/retTransp/CFOP").text 
      nfe.codigo_municipio_fator_gerador_icms_transporte = node.css("transp/retTransp/cMunFG").text 
      nfe.transporteQtde = node.css("transp/vol/qVol").text 
      nfe.transporteEspecie = node.css("transp/vol/esp").text 
      nfe.transporteMarcaDosVolumes = node.css("transp/vol/marca").text
      nfe.transporteNumeracao = node.css("transp/vol/nVol").text 
      nfe.transportePesoLiquido = node.css("transp/vol/pesoL").text 
      nfe.transportePesoBruto = node.css("transp/vol/pesoB").text 

      # Dados Emitente
      # ------------------------------------------------------
      nfe.nomeEmitente = node.css("emit/xNome").text
      nfe.nomeFantasiaEmitente = node.css("emit/xFant").text

      if node.css("emit/CNPJ").text != ""
        nfe.cpfCnpjEmitente = node.css("emit/CNPJ").text
      else
        nfe.cpfCnpjEmitente = node.css("emit/CPF").text
      end  
      
      nfe.logradouroEmitente = node.css("emit/enderEmit/xLgr").text
      nfe.nrEnderecoEmitente = node.css("emit/enderEmit/nro").text
      nfe.complementoEnderecoEmitente = node.css("emit/enderEmit/xCpl").text
      nfe.bairroEmitente = node.css("emit/enderEmit/xBairro").text
      nfe.cepEmitente = node.css("emit/enderEmit/CEP").text
      nfe.codMunicipioEmitente = node.css("emit/enderEmit/cMun").text
      nfe.municipioEmitente = node.css("emit/enderEmit/xMun").text
      nfe.telefoneEmitente = node.css("emit/enderEmit/fone").text
      nfe.ufEmitente = node.css("emit/enderEmit/UF").text
      nfe.codPaisEmitente = node.css("emit/enderEmit/cPais").text
      nfe.paisEmitente = node.css("emit/enderEmit/xPais").text 
      nfe.inscricaoEstadualEmitente = node.css("emit/IE").text
      nfe.inscricaoEstadualSubsTribEmitente = node.css("emit/IEST").text
      nfe.inscricaoMunicipalEmitente = node.css("emit/IM").text
      nfe.codMunicipioFatorGeradorICMSEmitente = node.css("emit/enderEmit/cMun").text
      nfe.cnaeFiscalEmitente = node.css("emit/CNAE").text
      nfe.crtEmitente = node.css("emit/CRT").text

      # Dados Destinatário
      # ------------------------------------------------------
      nfe.nomeDestinatario = node.css("dest/xNome").text      

      if node.css("dest/CNPJ").text != ""
        nfe.cpfCnpjDestinatario = node.css("dest/CNPJ").text
      else
        nfe.cpfCnpjDestinatario = node.css("dest/CPF").text
      end  

      nfe.logradouroDestinatario = node.css("dest/enderDest/xLgr").text
      nfe.nrEnderecoDestinatario = node.css("dest/enderDest/nro").text
      nfe.complementoEnderecoDestinatario = node.css("dest/enderDest/xCpl").text
      nfe.bairroDestinatario = node.css("dest/enderDest/xBairro").text
      nfe.cepDestinatario = node.css("dest/enderDest/CEP").text
      nfe.codMunicipioDestinatario = node.css("dest/enderDest/cMun").text
      nfe.municipioDestinatario = node.css("dest/enderDest/xMun").text 
      nfe.telefoneDestinatario = node.css("dest/enderDest/fone").text
      nfe.ufDestinatario = node.css("dest/enderDest/UF").text
      nfe.codPaisDestinatario = node.css("dest/enderDest/cPais").text
      nfe.paisDestinatario = node.css("dest/enderDest/xPais").text 
      nfe.inscricaoEstadualDestinatario = node.css("dest/IE").text 
      nfe.indicadorIEDestinatario = node.css("dest/indIEDest").text
      nfe.inscricaoSuframa = node.css("dest/ISUF").text
      nfe.inscricaoMunicipalTomadorServico = node.css("dest/IM").text
      nfe.emailDestinatario = node.css("dest/email").text
      
      # Local entrega
      # ---------------------------------------------------------
      if node.css("entrega/CNPJ").text != ""
        nfe.entregaCpfCnpj = node.css("entrega/CNPJ").text
      else
        nfe.entregaCpfCnpj = node.css("entrega/CPF").text
      end      

      nfe.entregaLogradouro =  node.css("entrega/xLgr").text 
      nfe.entregaNumero = node.css("entrega/nro").text 
      nfe.entregaComplemento = node.css("entrega/xCpl").text 
      nfe.entregaBairro = node.css("entrega/xBairro").text  
      nfe.entregaMunicipio = node.css("entrega/xMun").text
      nfe.entregaUF = node.css("entrega/UF").text

      # Produtos
      # --------------------------------------------------------
      node.css("det").each do |det|
        item = Hash.new
        item[:nrItem] =  det.attribute("nItem").text 
        item[:descricao] = det.css("prod/xProd").text
        item[:qtdeComercial] = det.css("prod/qCom").text 
        item[:qtdeTributavel] = det.css("prod/qTrib").text  
        item[:unidadeComercial] = det.css("prod/uCom").text
        item[:unidadeTributavel] = det.css("prod/uTrib").text
        item[:valorUnitarioComercializacao] = det.css("prod/vUnCom").text
        item[:valorUnitarioTributacao] = det.css("prod/vUnTrib").text 
        item[:codProduto] = det.css("prod/cProd").text  
        item[:codNCM] = det.css("prod/NCM").text
        item[:codExTIPI] = det.css("prod/EXTIPI").text       
        item[:cfop] = det.css("prod/CFOP").text
        item[:outrasDespesasAcessorias] = det.css("prod/vOutro").text 
        item[:valorDesconto] = det.css("prod/vDesc").text  
        item[:valorTotalFrete] = det.css("prod/vFrete").text
        item[:valorSeguro] = det.css("prod/vSeg").text       
        item[:indicadorComposicaoValorTotalNfe] = det.css("prod/indTot").text
        item[:codEANComercial] = det.css("prod/cEAN").text 
        item[:codEANTributavel] = det.css("prod/cEANTrib").text  
        item[:nrPedidoCompra] = det.css("prod/xPed").text
        item[:itemPedidoCompra] = det.css("prod/itemPedidoCompra").text                             
        item[:valorAproximadoTributos] = det.css("imposto/vTotTrib").text
        item[:nrFCI] = det.css("prod/nFCI").text 
        item[:informacoesAdicionaisProduto] = det.css("infAdProd").text
        item[:valorProduto] = det.css("prod/vProd").text 

        # - PIS
        # ---------------------------------------------
        if det.css("imposto/PIS").text != ""
          if det.css("imposto/PIS/PISAliq").text != ""
            item[:codSituacaoTribPIS] = det.css("imposto/PIS/PISAliq/CST").text
            item[:valorBCPIS] = det.css("imposto/PIS/PISAliq/vBC").text 
            item[:valorAliquotaPIS] = det.css("imposto/PIS/PISAliq/pPIS").text
            item[:valorPIS] = det.css("imposto/PIS/PISAliq/vPIS").text
          elsif det.css("imposto/PIS/PISOutr").text != ""
            item[:codSituacaoTribPIS] = det.css("imposto/PIS/PISOutr/CST").text
            item[:valorBCPIS] = det.css("imposto/PIS/PISOutr/vBC").text
            item[:valorAliquotaPIS] = det.css("imposto/PIS/PISOutr/pPIS").text
            item[:valorPIS] = det.css("imposto/PIS/PISOutr/vPIS").text
          else
             if det.css("imposto/PIS/PISNT").text != ""    
                item[:codSituacaoTribPIS] = det.css("imposto/PIS/PISNT/CST").text
             end 
          end 
        end 

        # - COFINS
        # ----------------------------------------------
        if det.css("imposto/COFINS").text != ""
          if det.css("imposto/COFINS/COFINSAliq").text != ""
            item[:codSituacaoTribCofins] = det.css("imposto/COFINS/COFINSAliq/CST").text
            item[:valorBCCofins] = det.css("imposto/COFINS/COFINSAliq/vBC").text
            item[:valorAliquotaCofins] = det.css("imposto/COFINS/COFINSAliq/pCOFINS").text
            item[:valorCofins] = det.css("imposto/COFINS/COFINSAliq/vCOFINS").text
          elsif det.css("imposto/COFINS/COFINSOutr").text != ""
            item[:codSituacaoTribCofins] = det.css("imposto/COFINS/COFINSOutr/CST").text
            item[:valorBCCofins] = det.css("imposto/COFINS/COFINSOutr/vBC").text
            item[:valorAliquotaCofins] = det.css("imposto/COFINS/COFINSOutr/pCOFINS").text
            item[:valorCofins] = det.css("imposto/COFINS/COFINSOutr/vCOFINS").text
          else
             if det.css("imposto/COFINS/COFINSNT").text != ""
                item[:codSituacaoTribCofins] = det.css("imposto/COFINS/COFINSNT/CST").text
             end 
          end 
        end 

        #  - ICMS
        # ---------------------------------------------
        if det.css("imposto/ICMS").text != ""
          if det.css("imposto/ICMS/ICMS00").text != ""           
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMS00/orig").text
            item[:codTributacaoICMS] = det.css("imposto/ICMS/ICMS00/CST").text
            item[:modalidadeBCICMS] = det.css("imposto/ICMS/ICMS00/modBC").text
            item[:valorBCICMS] = det.css("imposto/ICMS/ICMS00/vBC").text
            item[:valorAliquotaImpostoICMS] = det.css("imposto/ICMS/ICMS00/pICMS").text
            item[:valorICMS] = det.css("imposto/ICMS/ICMS00/vICMS").text
          elsif det.css("imposto/ICMS/ICMS20").text != ""           
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMS20/orig").text
            item[:codTributacaoICMS] = det.css("imposto/ICMS/ICMS20/CST").text
            item[:modalidadeBCICMS] = det.css("imposto/ICMS/ICMS20/modBC").text
            item[:percentual_reducao_bc_icms] = det.css("imposto/ICMS/ICMS20/pRedBC").text
            item[:valorBCICMS] = det.css("imposto/ICMS/ICMS20/vBC").text
            item[:valorAliquotaImpostoICMS] = det.css("imposto/ICMS/ICMS20/pICMS").text
            item[:valorICMS] = det.css("imposto/ICMS/ICMS20/vICMS").text
          elsif det.css("imposto/ICMS/ICMS40").text != ""
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMS40/orig").text
            item[:codTributacaoICMS] = det.css("imposto/ICMS/ICMS40/CST").text
          elsif det.css("imposto/ICMS/ICMS60").text != ""
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMS60/orig").text
            item[:codTributacaoICMS] = det.css("imposto/ICMS/ICMS60/CST").text
            item[:valorBCSTRet] = det.css("imposto/ICMS/ICMS60/vBCSTRet").text
            item[:valorICMSSTRet] = det.css("imposto/ICMS/ICMS60/vICMSSTRet").text
          elsif det.css("imposto/ICMS/ICMS90").text != ""           
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMS90/orig").text
            item[:codTributacaoICMS] = det.css("imposto/ICMS/ICMS90/CST").text
            item[:modalidadeBCICMS] = det.css("imposto/ICMS/ICMS90/modBC").text
            item[:valorBCICMS] = det.css("imposto/ICMS/ICMS90/vBC").text
            item[:valorAliquotaImpostoICMS] = det.css("imposto/ICMS/ICMS90/pICMS").text
            item[:valorICMS] = det.css("imposto/ICMS/ICMS90/vICMS").text
            item[:modalidade_determinacao_bc_icms_st] = det.css("imposto/ICMS/ICMS90/modBCST").text
            item[:valor_bc_icms_st] = det.css("imposto/ICMS/ICMS90/vBCST").text
            item[:aliquota_icms_st] = det.css("imposto/ICMS/ICMS90/pICMSST").text
            item[:valor_icms_st] = det.css("imposto/ICMS/ICMS90/vICMSST").text
            item[:percentual_reducao_bc_icms_st] = det.css("imposto/ICMS/ICMS90/pRedBCST").text
            item[:percentual_margem_valor_adicionado_icms_st] = det.css("imposto/ICMS/ICMS90/pMVAST").text                              
          elsif det.css("imposto/ICMS/ICMSSN101").text != ""
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMSSN101/orig").text
            item[:csosn] = det.css("imposto/ICMS/ICMSSN101/CSOSN").text
            item[:p_cred_sn] = det.css("imposto/ICMS/ICMSSN101/pCredSN").text
            item[:v_cred_icmssn] = det.css("imposto/ICMS/ICMSSN101/vCredICMSSN").text                             
          elsif det.css("imposto/ICMS/ICMSSN102").text != ""
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMSSN102/orig").text
            item[:csosn] = det.css("imposto/ICMS/ICMSSN102/CSOSN").text                          
          elsif det.css("imposto/ICMS/ICMSSN500").text != ""
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMSSN500/orig").text
            item[:csosn] = det.css("imposto/ICMS/ICMSSN500/CSOSN").text
            item[:valorBCSTRet] = det.css("imposto/ICMS/ICMSSN500/vBCSTRet").text
            item[:valorICMSSTRet] = det.css("imposto/ICMS/ICMSSN500/vICMSSTRet").text                                                       
          elsif det.css("imposto/ICMS/ICMSSN900").text != ""
                item[:origemMercadoria] = det.css("imposto/ICMS/ICMSSN900/orig").text
                item[:csosn] = det.css("imposto/ICMS/ICMSSN900/CSOSN").text
                item[:modalidadeBCICMS] = det.css("imposto/ICMS/ICMSSN900/modBC").text
                item[:valorBCICMS] = det.css("imposto/ICMS/ICMSSN900/vBC").text
                item[:percentual_reducao_bc_icms] = det.css("imposto/ICMS/ICMSSN900/pRedBC").text
                item[:valorAliquotaImpostoICMS] = det.css("imposto/ICMS/ICMSSN900/pICMS").text
                item[:valorICMS] = det.css("imposto/ICMS/ICMSSN900/vICMS").text
                item[:modalidade_determinacao_bc_icms_st] = det.css("imposto/ICMS/ICMSSN900/modBCST").text
                item[:percentual_margem_valor_adicionado_icms_st] = det.css("imposto/ICMS/ICMSSN900/pMVAST").text
                item[:percentual_reducao_bc_icms_st] = det.css("imposto/ICMS/ICMSSN900/pRedBCST").text
                item[:valor_bc_icms_st] = det.css("imposto/ICMS/ICMSSN900/vBCST").text
                item[:aliquota_icms_st] = det.css("imposto/ICMS/ICMSSN900/pICMSST").text
                item[:valor_icms_st] = det.css("imposto/ICMS/ICMSSN900/vICMSST").text
                item[:p_cred_sn] = det.css("imposto/ICMS/ICMSSN101/pCredSN").text
                item[:v_cred_icmssn] = det.css("imposto/ICMS/ICMSSN101/vCredICMSSN").text                                                                                                                                                                                                                                
          end 
        end 

        #  - IPI
        # ---------------------------------------------
        if det.css("imposto/IPI").text != "" 
            item[:classe_enquadramento_ipi_cigarros_bebidas] = det.css("imposto/IPI/clEnq").text
            item[:cnpj_produtor_mercadoria] = det.css("imposto/IPI/CNPJProd").text
            item[:codigo_selo_controle_ipi] = det.css("imposto/IPI/cSelo").text
            item[:qtde_selo_controle_ipi] = det.css("imposto/IPI/qSelo").text
            item[:codEnquadramentoIPI] = det.css("imposto/IPI/cEnq").text
          if det.css("imposto/IPI/IPITrib").text != ""
            item[:codSituacaoTribIPI] = det.css("imposto/IPI/IPITrib/CST").text
            item[:valorBCIPI] = det.css("imposto/IPI/IPITrib/vBC").text    
            item[:valorAliquotaIPI] = det.css("imposto/IPI/IPITrib/pIPI").text
            item[:qtde_total_unidade_padrao] = det.css("imposto/IPI/IPITrib/qUnid").text
            item[:valor_unidade_tributavel] = det.css("imposto/IPI/IPITrib/vUnid").text
            item[:valorIPI] = det.css("imposto/IPI/IPITrib/vIPI").text  
          end

          if det.css("imposto/IPI/IPINT").text != ""
              item[:codSituacaoTribIPI] = det.css("imposto/IPI/IPINT/CST").text    
          end
        end 
       
        #  - II => Imposto de Importação
        # ---------------------------------------------
        if det.css("imposto/II").text != ""
          item[:valor_bc_imposto_importacao] = det.css("imposto/II/vBC").text
          item[:valor_despesas_aduaneiras] = det.css("imposto/II/vDespAdu").text
          item[:valor_imposto_importacao] = det.css("imposto/II/vII").text
          item[:valor_imposto_iof] = det.css("imposto/II/vIOF").text
        end 
        produtos.push(item)
      end
      
      # Duplicatas
      # -------------------------------------------------------
      node.css("dup").each do |cobr|
        dup = Hash.new
        dup[:nrDuplicata] =  cobr.css("nDup").text 
        dup[:dtVencimento] = cobr.css("dVenc").text
        dup[:valorDuplicata] = cobr.css("vDup").text 
        duplicatas.push(dup)
      end
  
      # Nome dos relacionamentos (nested)
      # -----------------------------------------
      nfe.notaProdutos.build(produtos)
      nfe.notaDuplicatas.build(duplicatas)
      nfe.save

=begin
      h.each do |k,v|
         value = v || k
         if value.is_a?(Hash)
            if value[:det].is_a?(Array) # && !NotaProduto.exists?(notaFiscal_id: nfe_id)
               value[:det].each_index do |x|
                  if value[:det][x].include?(:prod)
                     item = NotaProduto.new
                     item[:nrItem] = value[:det][x][:@n_item]
                     item[:descricao] = value[:det][x][:prod][:x_prod]
                     item[:qtdeComercial] = value[:det][x][:prod][:q_com]
                     item[:unidadeComercial] = value[:det][x][:prod][:u_com]
                     item[:qtdeTributavel] = value[:det][x][:prod][:q_trib]
                     item[:unidadeTributavel] = value[:det][x][:prod][:u_trib]
                     item[:valorUnitarioComercializacao] = value[:det][x][:prod][:v_un_com]
                     item[:valorUnitarioTributacao] = value[:det][x][:prod][:v_un_trib]
                     item[:codProduto] = value[:det][x][:prod][:c_prod]
                     item[:codNCM] = value[:det][x][:prod][:ncm]
                     unless value[:det][x][:extipi].nil?;item[:codExTIPI] = value[:det][x][:prod][:extipi] end   
                     item[:cfop] = value[:det][x][:prod][:cfop]
                     unless value[:det][x][:prod][:vOutro].nil?;item[:outrasDespesasAcessorias] = value[:det][x][:prod][:vOutro] end
                     unless value[:det][x][:prod][:v_desc].nil?;item[:valorDesconto] = value[:det][x][:prod][:v_desc] end
                     unless value[:det][x][:prod][:v_frete].nil?;item[:valorTotalFrete] = value[:det][x][:prod][:v_frete] end 
                     unless value[:det][x][:prod][:v_seg].nil?;item[:valorSeguro] = value[:det][x][:prod][:v_seg] end 
                     item[:indicadorComposicaoValorTotalNfe] = value[:det][x][:prod][:ind_tot] 
                     item[:codEANComercial] = value[:det][x][:prod][:c_ean]
                     item[:codEANTributavel] = value[:det][x][:prod][:c_ean_trib]
                     unless value[:det][x][:prod][:x_ped].nil?;item[:nrPedidoCompra] = value[:det][x][:prod][:x_ped] end
                     unless value[:det][x][:prod][:n_item_ped].nil?;item[:itemPedidoCompra] = value[:det][x][:prod][:n_item_ped] end
                     unless value[:det][x][:prod][:nr_fci].nil?;item[:nrFCI] = value[:det][x][:prod][:n_fci] end
                     item[:valorProduto] = value[:det][x][:prod][:v_prod]

                     item[:valorTotalTributos] = value[:det][x][:imposto][:v_tot_trib]
                 
                     if value[:det][x].include?(:inf_ad_prod)
                        item[:informacoesAdicionaisProduto] = value[:det][x][:inf_ad_prod]
                     end
                  
                     # Impostos
                     # -------------------------------------------------------------------------
                     
                     # - ICMS 00/20/40/50/90/101/102/500/900  
                     if value[:det][x][:imposto][:icms].include?(:icms00)
                        item[:origemMercadoria] = value[:det][x][:imposto][:icms][:icms00][:orig]
                        item[:codTributacaoICMS] = value[:det][x][:imposto][:icms][:icms00][:cst]
                        item[:modalidadeBCICMS] = value[:det][x][:imposto][:icms][:icms00][:mod_bc]
                        item[:valorBCICMS] = value[:det][x][:imposto][:icms][:icms00][:v_bc]
                        item[:valorAliquotaImpostoICMS] = value[:det][x][:imposto][:icms][:icms00][:p_icms]
                        item[:valorICMS] = value[:det][x][:imposto][:icms][:icms00][:v_icms]
                      elsif value[:det][x][:imposto][:icms].include?(:icms20)
                        item[:origemMercadoria] = value[:det][x][:imposto][:icms][:icms20][:orig]
                        item[:codTributacaoICMS] = value[:det][x][:imposto][:icms][:icms20][:cst]
                        item[:modalidadeBCICMS] = value[:det][x][:imposto][:icms][:icms20][:mod_bc]
                        item[:percentual_reducao_bc_icms] = value[:det][x][:imposto][:icms][:icms20][:p_red_bc]
                        item[:valorBCICMS] = value[:det][x][:imposto][:icms][:icms00][:v_bc]
                        item[:valorAliquotaImpostoICMS] = value[:det][x][:imposto][:icms][:icms00][:p_icms]
                        item[:valorICMS] = value[:det][x][:imposto][:icms][:icms00][:v_icms]
                      elsif value[:det][x][:imposto][:icms].include?(:icms40)
                        item[:origemMercadoria] = value[:det][x][:imposto][:icms][:icms40][:orig]
                        item[:codTributacaoICMS] = value[:det][x][:imposto][:icms][:icms40][:cst]                        
                     elsif value[:det][x][:imposto][:icms].include?(:icms60) 
                        item[:origemMercadoria] = value[:det][x][:imposto][:icms][:icms60][:orig]
                        item[:codTributacaoICMS] = value[:det][x][:imposto][:icms][:icms60][:cst]
                        item[:valorBCSTRet] = value[:det][x][:imposto][:icms][:icms60][:v_bcst_ret]
                        item[:valorICMSSTRet] = value[:det][x][:imposto][:icms][:icms60][:v_icmsst_ret]
                      elsif value[:det][x][:imposto][:icms].include?(:icms90)
                        item[:origemMercadoria] = value[:det][x][:imposto][:icms][:icms90][:orig]
                        item[:codTributacaoICMS] = value[:det][x][:imposto][:icms][:icms90][:cst]
                        item[:modalidadeBCICMS] = value[:det][x][:imposto][:icms][:icms90][:mod_bc]
                        item[:valorBCICMS] = value[:det][x][:imposto][:icms][:icms90][:v_bc]
                        item[:valorAliquotaImpostoICMS] = value[:det][x][:imposto][:icms][:icms90][:p_icms]
                        item[:valorICMS] = value[:det][x][:imposto][:icms][:icms90][:v_icms]
                        item[:modalidade_determinacao_bc_icms_st] = value[:det][x][:imposto][:icms][:icms90][:mod_bcst]
                        item[:valor_bc_icms_st] = value[:det][x][:imposto][:icms][:icms90][:v_bcst]                              
                        item[:aliquota_icms_st] = value[:det][x][:imposto][:icms][:icms90][:p_icmsst]
                        item[:valor_icms_st] = value[:det][x][:imposto][:icms][:icms90][:v_icmsst]      
                        item[:percentual_reducao_bc_icms_st] = value[:det][x][:imposto][:icms][:icms90][:p_red_bcst]      
                        item[:percentual_margem_valor_adicionado_icms_st] = value[:det][x][:imposto][:icms][:icms90][:p_mvast]      
                     elsif value[:det][x][:imposto][:icms].include?(:icmssn101)
                        item[:origemMercadoria] = value[:det][x][:imposto][:icms][:icmssn101][:orig]
                        item[:csosn] = value[:det][x][:imposto][:icms][:icmssn101][:csosn]
                        item[:p_cred_sn] = value[:det][x][:imposto][:icms][:icmssn101][:p_cred_sn]
                        item[:v_cred_icmssn] = value[:det][x][:imposto][:icms][:icmssn101][:v_cred_icmssn]                        
                     elsif value[:det][x][:imposto][:icms].include?(:icmssn102)
                        item[:origemMercadoria] = value[:det][x][:imposto][:icms][:icmssn102][:orig]
                        item[:csosn] = value[:det][x][:imposto][:icms][:icmssn102][:csosn]                         
                     elsif value[:det][x][:imposto][:icms].include?(:icmssn500)
                        item[:origemMercadoria] = value[:det][x][:imposto][:icms][:icmssn500][:orig]
                        item[:csosn] = value[:det][x][:imposto][:icms][:icmssn500][:csosn] 
                        item[:valorBCSTRet] = value[:det][x][:imposto][:icms][:icmssn500][:v_bcst_ret]
                        item[:valorICMSSTRet] = value[:det][x][:imposto][:icms][:icmssn500][:v_icmsst_ret] 
                     elsif value[:det][x][:imposto][:icms].include?(:icmssn900)
                        item[:origemMercadoria] = value[:det][x][:imposto][:icms][:icmssn900][:orig]
                        item[:csosn] = value[:det][x][:imposto][:icms][:icmssn900][:csosn] 
                        item[:modalidadeBCICMS] = value[:det][x][:imposto][:icms][:icmssn900][:mod_bc]
                        item[:valorBCICMS] = value[:det][x][:imposto][:icms][:icmssn900][:v_bc]                              
                        item[:percentual_reducao_bc_icms] = value[:det][x][:imposto][:icms][:icmssn900][:p_red_bc]      
                        item[:valorAliquotaImpostoICMS] = value[:det][x][:imposto][:icms][:icmssn900][:p_icms]      
                        item[:valorICMS] = value[:det][x][:imposto][:icms][:icmssn900][:v_icms]      
                        item[:modalidade_determinacao_bc_icms_st] = value[:det][x][:imposto][:icms][:icmssn900][:mod_bcst]                                   
                        item[:percentual_margem_valor_adicionado_icms_st] = value[:det][x][:imposto][:icms][:icmssn900][:p_mvast]      
                        item[:percentual_reducao_bc_icms_st] = value[:det][x][:imposto][:icms][:icmssn900][:p_red_bcst]                              
                        item[:valor_bc_icms_st] = value[:det][x][:imposto][:icms][:icmssn900][:v_bcst]      
                        item[:aliquota_icms_st] = value[:det][x][:imposto][:icms][:icmssn900][:p_icmsst]      
                        item[:valor_icms_st] = value[:det][x][:imposto][:icms][:icmssn900][:v_icmsst]      
                        item[:p_cred_sn] = value[:det][x][:imposto][:icms][:icmssn101][:p_cred_sn]
                        item[:v_cred_icmssn] = value[:det][x][:imposto][:icms][:icmssn101][:v_cred_icmssn]                                                                                                                             
                     end

                     #  - IPI
                     # ---------------------------------------------
                     if value[:det][x][:imposto].include?(:ipi)
                        unless value[:det][x][:imposto][:ipi][:cl_enq].nil?;item[:classe_enquadramento_ipi_cigarros_bebidas] = value[:det][x][:imposto][:ipi][:cl_enq] end
                        unless value[:det][x][:imposto][:ipi][:cnpj_prod].nil?;item[:cnpj_produtor_mercadoria] = value[:det][x][:imposto][:ipi][:cnpj_prod] end
                        unless value[:det][x][:imposto][:ipi][:c_selo].nil?;item[:codigo_selo_controle_ipi] = value[:det][x][:imposto][:ipi][:c_selo] end
                        unless value[:det][x][:imposto][:ipi][:q_selo].nil?;item[:qtde_selo_controle_ipi] = value[:det][x][:imposto][:ipi][:q_selo] end
                        unless value[:det][x][:imposto][:ipi][:c_enq].nil?;item[:codEnquadramentoIPI] = value[:det][x][:imposto][:ipi][:c_enq] end

                        if value[:det][x][:imposto][:ipi].include?(:ipi_trib)
                          unless value[:det][x][:imposto][:ipi][:ipi_trib][:cst].nil?;item[:codSituacaoTribIPI] = value[:det][x][:imposto][:ipi][:ipi_trib][:cst] end
                          unless value[:det][x][:imposto][:ipi][:ipi_trib][:v_bc].nil?;item[:valorBCIPI] = value[:det][x][:imposto][:ipi][:ipi_trib][:v_bc] end
                          unless value[:det][x][:imposto][:ipi][:ipi_trib][:p_ipi].nil?;item[:valorAliquotaIPI] = value[:det][x][:imposto][:ipi][:ipi_trib][:p_ipi] end
                          unless value[:det][x][:imposto][:ipi][:ipi_trib][:q_unid].nil?;item[:qtde_total_unidade_padrao] = value[:det][x][:imposto][:ipi][:ipi_trib][:q_unid] end
                          unless value[:det][x][:imposto][:ipi][:ipi_trib][:v_unid].nil?;item[:valor_unidade_tributavel] = value[:det][x][:imposto][:ipi][:ipi_trib][:v_unid] end
                          unless value[:det][x][:imposto][:ipi][:ipi_trib].nil?;item[:valorIPI] = value[:det][x][:imposto][:ipi][:ipi_trib][:v_ipi] end
                        end  
                        
                        if value[:det][x][:imposto][:ipi].include?(:ipint)
                          unless value[:det][x][:imposto][:ipi][:ipint].nil?;item[:codSituacaoTribIPI] = value[:det][x][:imposto][:ipi][:ipint][:cst] end
                        end
                     end  

                     #  - II => Imposto de Importação
                     # ---------------------------------------------
                     if value[:det][x][:imposto].include?(:ii)
                        unless value[:det][x][:imposto][:ii][:v_bc].nil?;item[:valor_bc_imposto_importacao] = value[:det][x][:imposto][:ii][:v_bc] end
                        unless value[:det][x][:imposto][:ii][:v_desp_adu].nil?;item[:valor_despesas_aduaneiras] = value[:det][x][:imposto][:ii][:v_desp_adu] end
                        unless value[:det][x][:imposto][:ii][:v_ii].nil?;item[:valor_imposto_importacao] = value[:det][x][:imposto][:ii][:v_ii] end
                        unless value[:det][x][:imposto][:ii][:v_iof].nil?;item[:valor_imposto_iof] = value[:det][x][:imposto][:ii][:v_iof] end
                     end 

                     #  - PIS
                     # ---------------------------------------------
                     if value[:det][x][:imposto].include?(:pis)
                        unless value[:det][x][:imposto][:pis][:pis_aliq].nil?
                           item[:codSituacaoTribPIS] = value[:det][x][:imposto][:pis][:pis_aliq][:cst]
                           item[:valorBCPIS] = value[:det][x][:imposto][:pis][:pis_aliq][:v_bc] 
                           item[:valorAliquotaPIS] = value[:det][x][:imposto][:pis][:pis_aliq][:p_pis]
                           item[:valorPIS] = value[:det][x][:imposto][:pis][:pis_aliq][:v_pis] 
                        end
                        
                        unless value[:det][x][:imposto][:pis][:pis_outr].nil?
                           item[:codSituacaoTribPIS] = value[:det][x][:imposto][:pis][:pis_outr][:cst]
                           item[:valorBCPIS] = value[:det][x][:imposto][:pis][:pis_outr][:v_bc] 
                           item[:valorAliquotaPIS] = value[:det][x][:imposto][:pis][:pis_outr][:p_pis]
                           item[:valorPIS] = value[:det][x][:imposto][:pis][:pis_outr][:v_pis] 
                        end

                        if value[:det][x][:imposto][:pis].include?(:pisnt)
                           item[:codSituacaoTribPIS] = value[:det][x][:imposto][:pis][:pisnt][:cst]
                        end                    
                     end  

                     # - COFINS
                     # ----------------------------------------------
                     if value[:det][x][:imposto].include?(:cofins)
                        unless value[:det][x][:imposto][:cofins][:cofins_aliq].nil?
                           item[:codSituacaoTribCofins] = value[:det][x][:imposto][:cofins][:cofins_aliq][:cst] 
                           item[:valorBCCofins] = value[:det][x][:imposto][:cofins][:cofins_aliq][:v_bc] 
                           item[:valorAliquotaCofins] = value[:det][x][:imposto][:cofins][:cofins_aliq][:p_cofins]
                           item[:valorCofins] = value[:det][x][:imposto][:cofins][:cofins_aliq][:v_cofins]
                        end

                        unless value[:det][x][:imposto][:cofins][:cofins_outr].nil?
                           item[:codSituacaoTribCofins] = value[:det][x][:imposto][:cofins][:cofins_outr][:cst] 
                           item[:valorBCCofins] = value[:det][x][:imposto][:cofins][:cofins_outr][:v_bc] 
                           item[:valorAliquotaCofins] = value[:det][x][:imposto][:cofins][:cofins_outr][:p_cofins]
                           item[:valorCofins] = value[:det][x][:imposto][:cofins][:cofins_outr][:v_cofins]
                        end

                        if value[:det][x][:imposto][:cofins].include?(:cofinsnt)
                           item[:codSituacaoTribCofins] = value[:det][x][:imposto][:cofins][:cofinsnt][:cst]
                        end                   
                     end  

                    item.notaFiscal = NotaFiscal.find(nf.id)  # Associação
                    item.save
                  end
               end  
            end        
            if value[:ret_n_fe].is_a?(Hash)
               if value[:ret_n_fe].include?(:ch_n_fe)
                  nf[:nrNfe] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:n_nf]  
                  nf[:codModeloNfe] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:mod]
                  nf[:serieNfe] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:serie]
                  unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:dh_sai_ent].nil?;nf[:dtSaidaEntradaNfe] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:dh_sai_ent] end
                  nf[:codDestinoOperacaoDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:id_dest]
                  nf[:codConsumidorFinal] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:ind_final]
                  nf[:codPresencaComprador] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:ind_pres]
                  nf[:codProcessoEmissao] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:proc_emi]
                  nf[:versaoProcesso] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:ver_proc]
                  nf[:codFinalidadeEmissao] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:fin_n_fe]
                  nf[:naturezaOperacao] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:nat_op]
                  nf[:tipOperacao] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:tp_nf]
                  nf[:codFormaPagamento] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:ide][:ind_pag]

                  nf[:nomeFantasiaEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:x_fant]
                  nf[:logradouroEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:x_lgr]
                  nf[:nrEnderecoEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:nro]
                  nf[:complementoEnderecoEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:x_cpl]
                  nf[:bairroEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:x_bairro]
                  nf[:cepEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:cep]
                  nf[:codMunicipioEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:c_mun]
                  nf[:municipioEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:x_mun]
                  nf[:telefoneEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:fone]
                  nf[:ufEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:uf]
                  nf[:codPaisEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:c_pais]
                  nf[:paisEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:x_pais]
                  nf[:codMunicipioFatorGeradorICMSEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:ender_emit][:c_mun]       
                  nf[:inscricaoEstadualSubsTribEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:iest]                        
                  nf[:crtEmitente] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:emit][:crt] 

                  nf[:nomeDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:x_nome]
                  nf[:logradouroDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:x_lgr]             
                  nf[:nrEnderecoDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:nro]
                  nf[:complementoEnderecoDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:x_cpl]
                  nf[:bairroDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:x_bairro]
                  nf[:cepDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:cep]
                  nf[:codMunicipioDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:c_mun]
                  nf[:municipioDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:x_mun]
                  nf[:telefoneDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:fone]
                  nf[:ufDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:uf]
                  nf[:codPaisDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:c_pais]
                  nf[:paisDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ender_dest][:x_pais]
                  nf[:indicadorIEDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ind_ie_dest]
                  nf[:inscricaoEstadualDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:ie]
                  nf[:inscricaoSuframa] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:isuf]
                  nf[:inscricaoMunicipalTomadorServico] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:im]                        
                  nf[:emailDestinatario] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:dest][:email]

                  nf[:nrProtocoloNfe] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:prot_n_fe][:inf_prot][:n_prot]

                  nf[:valorBaseCalculoICMS] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_bc]
                  nf[:valorICMS] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_icms]
                  nf[:valorICMSDesonerado] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_icms_deson]
                  nf[:valorBaseCalculoICMSST] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_bcst]
                  nf[:valorICMSSubstituicao] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_st]
                  nf[:valorTotalProduto] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_prod]
                  nf[:valorFrete] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_frete]
                  nf[:valorSeguro] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_seg]
                  nf[:valorOutrasDespesasAcessorias]  = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_outro]
                  nf[:valorTotalIPI] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_ipi]
                  nf[:valorTotalDesconto] =value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_desc]
                  nf[:valorTotalII] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_ii]
                  nf[:valorPIS] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_pis]
                  nf[:valorCOFINS] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_cofins]
                  nf[:valorAproximadoTributos] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:total][:icms_tot][:v_tot_trib]

                  nf[:modalidadeFrete] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:mod_frete]

                  if value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp].include?(:vol)
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:q_vol].nil?;nf[:transporteQtde] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:q_vol] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:esp].nil?;nf[:transporteEspecie] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:esp] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:marca].nil?;nf[:transporteMarcaDosVolumes] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:marca] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:n_vol].nil?;nf[:transporteNumeracao] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:n_vol] end   
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:peso_l].nil?;nf[:transportePesoLiquido] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:peso_l] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:peso_b].nil?;nf[:transportePesoBruto] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:vol][:peso_b] end                
                  end

                  if value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp].include?(:transporta)
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:cnpj].nil?;nf[:cnpj_transportador] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:cnpj] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:cpf].nil?;nf[:cpf_transportador] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:cpf] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:x_nome].nil?;nf[:nome_transportador] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:x_nome] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:ie].nil?;nf[:ie_transportador] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:ie] end   
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:x_ender].nil?;nf[:endereco_transportador] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:x_ender] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:x_mun].nil?;nf[:municipio_transportador] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:x_mun] end                
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:uf].nil?;nf[:uf_transportador] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:transporta][:uf] end                
                  end
 
                  if value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp].include?(:retTransp)
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:v_serv].nil?;nf[:valor_servico_transporte] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:v_serv] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:v_bc_ret].nil?;nf[:valor_bc_retencao_icms_transporte] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:v_bc_ret] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:p_icms_ret].nil?;nf[:aliquota_retencao_icms_transporte] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:p_icms_ret] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:p_icms_ret].nil?;nf[:valor_icms_retido_transporte] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:v_icms_ret] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:cfop].nil?;nf[:valor_icms_retido_transporte] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:cfop] end   
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:c_mun_fg].nil?;nf[:endereco_transportador] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:transp][:retTransp][:c_mun_fg] end
                  end

                  unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:inf_adic].nil?;nf[:informacoesComplementaresNfe] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:inf_adic][:inf_cpl] end

                  if value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe].include?(:entrega)
                    if value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega].include?(:cnpj)
                      nf[:entregaCpfCnpj] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:cnpj]
                    else
                      nf[:entregaCpfCnpj] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:cpf]
                    end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:x_lgr].nil?;nf[:entregaLogradouro] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:x_lgr] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:nro].nil?;nf[:entregaNumero] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:nro] end                
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:x_cpl].nil?;nf[:entregaComplemento] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:x_cpl] end 
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:x_bairro].nil?;nf[:entregaBairro] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:x_bairro] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:x_mun].nil?;nf[:entregaMunicipio] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:x_mun] end
                    unless value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:uf].nil?;nf[:entregaUF] = value[:ret_n_fe][:proc_n_fe][:nfe_proc][:n_fe][:inf_n_fe][:entrega][:x_uf] end
                  end  

                  nf.save
            end 
            end          
            if value[:det].is_a?(Hash)  # && !NotaProduto.exists?(notaFiscal_id: nfe_id)
               if value[:det].include?(:prod)
                  item = NotaProduto.new
                  item[:nrItem] = value[:det][:@n_item]
                  item[:descricao] = value[:det][:prod][:x_prod]
                  item[:qtdeComercial] = value[:det][:prod][:q_com]
                  item[:unidadeComercial] = value[:det][:prod][:u_com]
                  item[:qtdeTributavel] = value[:det][:prod][:q_trib]
                  item[:unidadeTributavel] = value[:det][:prod][:u_trib]
                  item[:valorUnitarioComercializacao] = value[:det][:prod][:v_un_com]
                  item[:valorUnitarioTributacao] = value[:det][:prod][:v_un_trib]
                  item[:codProduto] = value[:det][:prod][:c_prod]
                  item[:codNCM] = value[:det][:prod][:ncm]
                  unless value[:det][:extipi].nil?;item[:codExTIPI] = value[:det][:prod][:extipi] end   
                  item[:cfop] = value[:det][:prod][:cfop]
                  unless value[:det][:prod][:vOutro].nil?;item[:outrasDespesasAcessorias] = value[:det][:prod][:vOutro] end
                  unless value[:det][:prod][:v_desc].nil?;item[:valorDesconto] = value[:det][:prod][:v_desc] end
                  unless value[:det][:prod][:v_frete].nil?;item[:valorTotalFrete] = value[:det][:prod][:v_frete] end 
                  unless value[:det][:prod][:v_seg].nil?;item[:valorSeguro] = value[:det][:prod][:v_seg] end 
                  item[:indicadorComposicaoValorTotalNfe] = value[:det][:prod][:ind_tot] 
                  item[:codEANComercial] = value[:det][:prod][:c_ean]
                  item[:codEANTributavel] = value[:det][:prod][:c_ean_trib]
                  unless value[:det][:prod][:x_ped].nil?;item[:nrPedidoCompra] = value[:det][:prod][:x_ped] end
                  unless value[:det][:prod][:n_item_ped].nil?;item[:itemPedidoCompra] = value[:det][:prod][:n_item_ped] end
                  unless value[:det][:prod][:nr_fci].nil?;item[:nrFCI] = value[:det][:prod][:n_fci] end
                  item[:valorProduto] = value[:det][:prod][:v_prod]

                  item[:valorTotalTributos] = value[:det][:imposto][:v_tot_trib]

                  if value[:det].include?(:infAdProd)
                    item[:informacoesAdicionaisProduto] = value[:det][:infAdProd]
                  end

                  # Impostos
                  # -------------------------------------------------------------------------
                 
                  # - ICMS 00/20/40/50/90/101/102/500/900  
                  if value[:det][:imposto][:icms].include?(:icms00)
                    item[:origemMercadoria] = value[:det][:imposto][:icms][:icms00][:orig]
                    item[:codTributacaoICMS] = value[:det][:imposto][:icms][:icms00][:cst]
                    item[:modalidadeBCICMS] = value[:det][:imposto][:icms][:icms00][:mod_bc]
                    item[:valorBCICMS] = value[:det][:imposto][:icms][:icms00][:v_bc]
                    item[:valorAliquotaImpostoICMS] = value[:det][:imposto][:icms][:icms00][:p_icms]
                    item[:valorICMS] = value[:det][:imposto][:icms][:icms00][:v_icms]
                  elsif value[:det][:imposto][:icms].include?(:icms20)
                    item[:origemMercadoria] = value[:det][:imposto][:icms][:icms20][:orig]
                    item[:codTributacaoICMS] = value[:det][:imposto][:icms][:icms20][:cst]
                    item[:modalidadeBCICMS] = value[:det][:imposto][:icms][:icms20][:mod_bc]
                    item[:percentual_reducao_bc_icms] = value[:det][:imposto][:icms][:icms20][:p_red_bc]
                    item[:valorBCICMS] = value[:det][:imposto][:icms][:icms00][:v_bc]
                    item[:valorAliquotaImpostoICMS] = value[:det][:imposto][:icms][:icms00][:p_icms]
                    item[:valorICMS] = value[:det][:imposto][:icms][:icms00][:v_icms]
                  elsif value[:det][:imposto][:icms].include?(:icms40)
                    item[:origemMercadoria] = value[:det][:imposto][:icms][:icms40][:orig]
                    item[:codTributacaoICMS] = value[:det][:imposto][:icms][:icms40][:cst]                        
                  elsif value[:det][:imposto][:icms].include?(:icms60) 
                    item[:origemMercadoria] = value[:det][:imposto][:icms][:icms60][:orig]
                    item[:codTributacaoICMS] = value[:det][:imposto][:icms][:icms60][:cst]
                    item[:valorBCSTRet] = value[:det][:imposto][:icms][:icms60][:v_bcst_ret]
                    item[:valorICMSSTRet] = value[:det][:imposto][:icms][:icms60][:v_icmsst_ret]
                  elsif value[:det][:imposto][:icms].include?(:icms90)
                    item[:origemMercadoria] = value[:det][:imposto][:icms][:icms90][:orig]
                    item[:codTributacaoICMS] = value[:det][:imposto][:icms][:icms90][:cst]
                    item[:modalidadeBCICMS] = value[:det][:imposto][:icms][:icms90][:mod_bc]
                    item[:valorBCICMS] = value[:det][:imposto][:icms][:icms90][:v_bc]
                    item[:valorAliquotaImpostoICMS] = value[:det][:imposto][:icms][:icms90][:p_icms]
                    item[:valorICMS] = value[:det][:imposto][:icms][:icms90][:v_icms]
                    item[:modalidade_determinacao_bc_icms_st] = value[:det][:imposto][:icms][:icms90][:mod_bcst]
                    item[:valor_bc_icms_st] = value[:det][:imposto][:icms][:icms90][:v_bcst]                              
                    item[:aliquota_icms_st] = value[:det][:imposto][:icms][:icms90][:p_icmsst]
                    item[:valor_icms_st] = value[:det][:imposto][:icms][:icms90][:v_icmsst]      
                    item[:percentual_reducao_bc_icms_st] = value[:det][:imposto][:icms][:icms90][:p_red_bcst]      
                    item[:percentual_margem_valor_adicionado_icms_st] = value[:det][:imposto][:icms][:icms90][:p_mvast]      
                  elsif value[:det][:imposto][:icms].include?(:icmssn101)
                    item[:origemMercadoria] = value[:det][:imposto][:icms][:icmssn101][:orig]
                    item[:csosn] = value[:det][:imposto][:icms][:icmssn101][:csosn]
                    item[:p_cred_sn] = value[:det][:imposto][:icms][:icmssn101][:p_cred_sn]
                    item[:v_cred_icmssn] = value[:det][:imposto][:icms][:icmssn101][:v_cred_icmssn]                        
                  elsif value[:det][:imposto][:icms].include?(:icmssn102)
                    item[:origemMercadoria] = value[:det][:imposto][:icms][:icmssn102][:orig]
                    item[:csosn] = value[:det][:imposto][:icms][:icmssn102][:csosn]                         
                  elsif value[:det][:imposto][:icms].include?(:icmssn500)
                    item[:origemMercadoria] = value[:det][:imposto][:icms][:icmssn500][:orig]
                    item[:csosn] = value[:det][:imposto][:icms][:icmssn500][:csosn] 
                    item[:valorBCSTRet] = value[:det][:imposto][:icms][:icmssn500][:v_bcst_ret]
                    item[:valorICMSSTRet] = value[:det][:imposto][:icms][:icmssn500][:v_icmsst_ret] 
                  elsif value[:det][:imposto][:icms].include?(:icmssn900)
                    item[:origemMercadoria] = value[:det][:imposto][:icms][:icmssn900][:orig]
                    item[:csosn] = value[:det][:imposto][:icms][:icmssn900][:csosn] 
                    item[:modalidadeBCICMS] = value[:det][:imposto][:icms][:icmssn900][:mod_bc]
                    item[:valorBCICMS] = value[:det][:imposto][:icms][:icmssn900][:v_bc]                              
                    item[:percentual_reducao_bc_icms] = value[:det][:imposto][:icms][:icmssn900][:p_red_bc]      
                    item[:valorAliquotaImpostoICMS] = value[:det][:imposto][:icms][:icmssn900][:p_icms]      
                    item[:valorICMS] = value[:det][:imposto][:icms][:icmssn900][:v_icms]      
                    item[:modalidade_determinacao_bc_icms_st] = value[:det][:imposto][:icms][:icmssn900][:mod_bcst]                                   
                    item[:percentual_margem_valor_adicionado_icms_st] = value[:det][:imposto][:icms][:icmssn900][:p_mvast]      
                    item[:percentual_reducao_bc_icms_st] = value[:det][:imposto][:icms][:icmssn900][:p_red_bcst]                              
                    item[:valor_bc_icms_st] = value[:det][:imposto][:icms][:icmssn900][:v_bcst]      
                    item[:aliquota_icms_st] = value[:det][:imposto][:icms][:icmssn900][:p_icmsst]      
                    item[:valor_icms_st] = value[:det][:imposto][:icms][:icmssn900][:v_icmsst]      
                    item[:p_cred_sn] = value[:det][:imposto][:icms][:icmssn101][:p_cred_sn]
                    item[:v_cred_icmssn] = value[:det][:imposto][:icms][:icmssn101][:v_cred_icmssn]                                                                                                                             
                  end

                 #  - IPI
                 # ---------------------------------------------
                 if value[:det][:imposto].include?(:ipi)
                    unless value[:det][:imposto][:ipi][:cl_enq].nil?;item[:classe_enquadramento_ipi_cigarros_bebidas] = value[:det][:imposto][:ipi][:cl_enq] end
                    unless value[:det][:imposto][:ipi][:cnpj_prod].nil?;item[:cnpj_produtor_mercadoria] = value[:det][:imposto][:ipi][:cnpj_prod] end
                    unless value[:det][:imposto][:ipi][:c_selo].nil?;item[:codigo_selo_controle_ipi] = value[:det][:imposto][:ipi][:c_selo] end
                    unless value[:det][:imposto][:ipi][:q_selo].nil?;item[:qtde_selo_controle_ipi] = value[:det][:imposto][:ipi][:q_selo] end
                    unless value[:det][:imposto][:ipi][:c_enq].nil?;item[:codEnquadramentoIPI] = value[:det][:imposto][:ipi][:c_enq] end

                    if value[:det][:imposto][:ipi].include?(:ipi_trib)
                      unless value[:det][:imposto][:ipi][:ipi_trib][:cst].nil?;item[:codSituacaoTribIPI] = value[:det][:imposto][:ipi][:ipi_trib][:cst] end
                      unless value[:det][:imposto][:ipi][:ipi_trib][:v_bc].nil?;item[:valorBCIPI] = value[:det][:imposto][:ipi][:ipi_trib][:v_bc] end
                      unless value[:det][:imposto][:ipi][:ipi_trib][:p_ipi].nil?;item[:valorAliquotaIPI] = value[:det][:imposto][:ipi][:ipi_trib][:p_ipi] end
                      unless value[:det][:imposto][:ipi][:ipi_trib][:q_unid].nil?;item[:qtde_total_unidade_padrao] = value[:det][:imposto][:ipi][:ipi_trib][:q_unid] end
                      unless value[:det][:imposto][:ipi][:ipi_trib][:v_unid].nil?;item[:valor_unidade_tributavel] = value[:det][:imposto][:ipi][:ipi_trib][:v_unid] end
                      unless value[:det][:imposto][:ipi][:ipi_trib].nil?;item[:valorIPI] = value[:det][:imposto][:ipi][:ipi_trib][:v_ipi] end
                    end  
                    
                    if value[:det][:imposto][:ipi].include?(:ipint)
                      unless value[:det][:imposto][:ipi][:ipint].nil?;item[:codSituacaoTribIPI] = value[:det][:imposto][:ipi][:ipint][:cst] end
                    end
                 end  

                 #  - II => Imposto de Importação
                 # ---------------------------------------------
                 if value[:det][:imposto].include?(:ii)
                    unless value[:det][:imposto][:ii][:v_bc].nil?;item[:valor_bc_imposto_importacao] = value[:det][:imposto][:ii][:v_bc] end
                    unless value[:det][:imposto][:ii][:v_desp_adu].nil?;item[:valor_despesas_aduaneiras] = value[:det][:imposto][:ii][:v_desp_adu] end
                    unless value[:det][:imposto][:ii][:v_ii].nil?;item[:valor_imposto_importacao] = value[:det][:imposto][:ii][:v_ii] end
                    unless value[:det][:imposto][:ii][:v_iof].nil?;item[:valor_imposto_iof] = value[:det][:imposto][:ii][:v_iof] end
                 end

                  #  - PIS
                  # ---------------------------------------------
                  if value[:det][:imposto].include?(:pis)
                     unless value[:det][:imposto][:pis][:pis_aliq].nil?
                        item[:codSituacaoTribPIS] = value[:det][:imposto][:pis][:pis_aliq][:cst]
                        item[:valorBCPIS] = value[:det][:imposto][:pis][:pis_aliq][:v_bc]
                        item[:valorAliquotaPIS] = value[:det][:imposto][:pis][:pis_aliq][:p_pis]
                        item[:valorPIS] = value[:det][:imposto][:pis][:pis_aliq][:v_pis]
                     end

                     unless value[:det][:imposto][:pis][:pis_outr].nil?
                        item[:codSituacaoTribPIS] = value[:det][:imposto][:pis][:pis_outr][:cst]
                        item[:valorBCPIS] = value[:det][:imposto][:pis][:pis_outr][:v_bc]
                        item[:valorAliquotaPIS] = value[:det][:imposto][:pis][:pis_outr][:p_pis]
                        item[:valorPIS] = value[:det][:imposto][:pis][:pis_outr][:v_pis]
                     end

                     if value[:det][:imposto][:pis].include?(:pisnt)
                        item[:codSituacaoTribPIS] = value[:det][:imposto][:pis][:pisnt][:cst]
                     end                 
                  end  

                  # - COFINS
                  # ----------------------------------------------
                  if value[:det][:imposto].include?(:cofins)
                     unless value[:det][:imposto][:cofins][:cofins_aliq].nil?
                        item[:codSituacaoTribCofins] = value[:det][:imposto][:cofins][:cofins_aliq][:cst]
                        item[:valorBCCofins] = value[:det][:imposto][:cofins][:cofins_aliq][:v_bc]
                        item[:valorAliquotaCofins] = value[:det][:imposto][:cofins][:cofins_aliq][:p_cofins]
                        item[:valorCofins] = value[:det][:imposto][:cofins][:cofins_aliq][:v_cofins]  
                     end

                     unless value[:det][:imposto][:cofins][:cofins_outr].nil?
                        item[:codSituacaoTribCofins] = value[:det][:imposto][:cofins][:cofins_outr][:cst]
                        item[:valorBCCofins] = value[:det][:imposto][:cofins][:cofins_outr][:v_bc]
                        item[:valorAliquotaCofins] = value[:det][:imposto][:cofins][:cofins_outr][:p_cofins]
                        item[:valorCofins] = value[:det][:imposto][:cofins][:cofins_outr][:v_cofins]  
                     end

                     if value[:det][:imposto][:cofins].include?(:cofinsnt)
                        item[:codSituacaoTribCofins] = value[:det][:imposto][:cofins][:cofinsnt][:cst]
                     end                     
                  end  

                  item.notaFiscal = NotaFiscal.find(nf.id)  # Associação
                  item.save  
               end
            end
            if value[:cobr].is_a?(Hash) # && !NotaDuplicata.exists?(notaFiscal_id: nfe_id)
               if value[:cobr][:dup].is_a?(Hash)
                  dup = NotaDuplicata.new
                  unless value[:cobr][:dup][:n_dup].nil?;dup[:nrDuplicata] = value[:cobr][:dup][:n_dup] end
                  unless value[:cobr][:dup][:d_venc].nil?;dup[:dtVencimento] = value[:cobr][:dup][:d_venc] end
                  dup[:valorDuplicata] = value[:cobr][:dup][:v_dup] 
                  dup.notaFiscal = NotaFiscal.find(nf.id)  # Associação
                  dup.save 
               elsif value[:cobr][:dup].is_a?(Array)
                  value[:cobr][:dup].each_index do |x|
                     dup = NotaDuplicata.new
                     unless value[:cobr][:dup][x][:n_dup].nil?;dup[:nrDuplicata] = value[:cobr][:dup][x][:n_dup] end
                     unless value[:cobr][:dup][x][:d_venc].nil?;dup[:dtVencimento] = value[:cobr][:dup][x][:d_venc] end
                     dup[:valorDuplicata] = value[:cobr][:dup][x][:v_dup]                 
                     dup.notaFiscal = NotaFiscal.find(nf.id)  # Associação
                     dup.save 
                  end  
               end 
            end  
            salvarDownloadNfe(value,nf)
         end
      end
=end        
   end

  # Registra na tabela log as ações do usuário
  # ------------------------------------------
  def self.registrarLog(acao, user_id, nfe_id)
    log = Log.new
    log[:acao] = acao
    log.user = User.find(user_id) #Acossiação 
    log.nota_fiscal = NotaFiscal.find(nfe_id) #Acossiação obs log.nota_fiscal é nome da associação na tabala de log
    log.save
  end  

  # Atualiza o status da nfe de acordo com o evento
  # -----------------------------------------------
  def self.atualiza_status_nfe(nf, h, user_id)
    msg = []
    h.each do |k,v|
      value = v || k
      if value.is_a?(Hash)
        
        # codCiencia = dominio('DM_TIP_EVE', 3, 10)
        # codConfirmar = dominio('DM_TIP_EVE', 3, 9)
        # cod_evento = ""
        # if value[:inf_evento][:tp_evento] == codCiencia.CódigoValorDomínio
        #   codSitConf = dominio('DM_SIT_CONF', 2, 8)
        #   cod_evento = codSitConf.CódigoValorDomínio
        # elsif value[:inf_evento][:tp_evento] == codConfirmar.CódigoValorDomínio
        #   codSitConf = dominio('DM_SIT_CONF', 2, 5)
        #   cod_evento = codSitConf.CódigoValorDomínio
        # end         

        cod_evento_dest = 0 

        if value[:inf_evento][:tp_evento] == NotaFiscal.tipo_eventos[:"Ciência da Emissão"].to_s
          cod_evento_dest = NotaFiscal.codSituacaoManifestacaoDestinatarios[:Ciência]
        elsif value[:inf_evento][:tp_evento] == NotaFiscal.tipo_eventos[:"Confirmação da Operação"].to_s
          cod_evento_dest = NotaFiscal.codSituacaoManifestacaoDestinatarios[:Confirmada]
        end         
        
        if value[:inf_evento][:c_stat] == "573" 
          nf.update({idLoteEvento: value[:id_lote], nrSequencialEvento: value[:inf_evento][:n_seq_evento], dataRegistroEvento: value[:inf_evento][:dh_reg_evento],
                    codSituacaoManifestacaoDestinatario: cod_evento_dest}) 
          registrarLog("Status da manifestação atualizado - #{value[:inf_evento][:x_evento]}", user_id, nf.id)
          return msg.push "Nota atualizada com sucesso."
        elsif value[:inf_evento][:c_stat] == "650"
          nf.update({idLoteEvento: value[:id_lote], nrSequencialEvento: value[:inf_evento][:n_seq_evento], dataRegistroEvento: value[:inf_evento][:dh_reg_evento],
                    codSituacaoNfe: NotaFiscal.codSituacaoNfes[:Cancelada], codSituacaoManifestacaoDestinatario: cod_evento_dest}) 
          registrarLog("Status da nfe atualizado - #{value[:inf_evento][:x_evento]}", user_id, nf.id)  
          return msg.push "Nota atualizada com sucesso."  
        else
          # return msg.push "Problemas na atualização, tente novamente em instantes...."
          return "Problemas na atualização, código status: #{value[:inf_evento]}. Informe ao administrador."
        end
        
      end
    end   

  end

=begin
  # Consome o serviço NfeConsultaProtocolo da sefaz
  # -----------------------------------------------
  # Obs: atenção o webservice a ser usado e o mesmo da uf do emitente
  # def self.consultaProtocolo(nfe, emp)
  #   msg = []
  #   webservice = Webservices.where("cod_uf = #{nfe.ufEmitente}" ).first
  #   xml = '<?xml version="1.0" encoding="UTF-8"?><soap12:Envelope xmlns:soap12="http://www.w3.org/2003/05/soap-envelope" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <soap12:Header><nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta2"><cUF>' << webservice[:cod_uf].to_s << '</cUF><versaoDados>3.10</versaoDados></nfeCabecMsg></soap12:Header><soap12:Body><nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta2"><consSitNFe versao="3.10" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>1</tpAmb><xServ>CONSULTAR</xServ><chNFe>'<< nfe.nrChaveNfe.to_s << '</chNFe></consSitNFe></nfeDadosMsg></soap12:Body></soap12:Envelope>'
  #   wsdl = webservice[:endereco]
    
  #   begin
  #     client = Savon::Client.new(wsdl: wsdl, ssl_cert_file: "#{emp.path_certificado}/cert.pem", ssl_cert_key_file: "#{emp.path_certificado}/key.pem", endpoint: wsdl, ssl_verify_mode: :none)
  #     response = client.call(:nfe_consulta_nf2 , xml: xml, advanced_typecasting: false)
  #   rescue Exception => e
  #     return msg.push "Problema com o servidor da sefaz... #{e.message}"
  #   end

  #   if !response.nil?
  #     if response.success?
  #       data = response.to_array.first
  #       if data[:nfe_consulta_nf2_result][:ret_cons_sit_n_fe][:c_stat] == "100"
  #         msg.push salvarConsultaProtocolo(nfe, data)
  #       else
  #         msg.push "#{data[:nfe_consulta_nf2_result][:ret_cons_sit_n_fe][:c_stat]} - #{data[:nfe_consulta_nf2_result][:ret_cons_sit_n_fe][:x_motivo]}"
  #       end
  #     end
  #   else
  #     msg.push "Ocilação no servidor da sefaz, favor tentar em instantes..."        
  #   end

  # end  

  # Atualiza as colunas sobre o evento na tabela nota fiscal
  # --------------------------------------------------------
  # def self.salvarConsultaProtocolo(nf, h)
  #   msg = []
  #   h.each do |k,v|
  #     value = v || k
  #     if value.is_a?(Hash)
  #       if value[:ret_cons_sit_n_fe][:proc_evento_n_fe].is_a?(Hash)
  #         if value[:ret_cons_sit_n_fe][:proc_evento_n_fe][:ret_evento].include?(:inf_evento)       

  #           codCiencia = dominio('DM_TIP_EVE', 3, 10)
  #           codConfirmar = dominio('DM_TIP_EVE', 8, 9)
  #           cod_evento = ""
            
  #           if value[:ret_cons_sit_n_fe][:proc_evento_n_fe][:ret_evento][:inf_evento][:tp_evento] == codCiencia.CódigoValorDomínio
  #             codSitConf = dominio('DM_SIT_CONF', 2, 8)
  #             cod_evento = codSitConf.CódigoValorDomínio
  #           elsif value[:ret_cons_sit_n_fe][:proc_evento_n_fe][:ret_evento][:inf_evento][:tp_evento] == codConfirmar.CódigoValorDomínio
  #             codSitConf = dominio('DM_SIT_CONF', 2, 5)
  #             cod_evento = codSitConf.CódigoValorDomínio
  #           end   

  #           nf.update({idLoteEvento: "#{nf.id}#{value[:ret_cons_sit_n_fe][:proc_evento_n_fe][:ret_evento][:inf_evento][:tp_evento]}", 
  #                       nrSequencialEvento: value[:ret_cons_sit_n_fe][:proc_evento_n_fe][:ret_evento][:inf_evento][:n_seq_evento],
  #                       dataRegistroEvento: value[:ret_cons_sit_n_fe][:proc_evento_n_fe][:ret_evento][:inf_evento][:dh_reg_evento],
  #                       nrProtocoloEvento: value[:ret_cons_sit_n_fe][:proc_evento_n_fe][:ret_evento][:inf_evento][:n_prot],
  #                       codSituacaoManifestacaoDestinatario: cod_evento}) 
  #           return msg.push "Nota atualizada com sucesso."
  #         end  
  #       elsif value[:ret_cons_sit_n_fe][:proc_evento_n_fe].is_a?(Array)
  #         z = data[:ret_cons_sit_n_fe][:proc_evento_n_fe].length - 1  # Só interessa acessar o ultimo elemento do array, ou seja o ultimo evento ocorrido com a nf 

  #         codCiencia = dominio('DM_TIP_EVE', 3, 10)
  #         codConfirmar = dominio('DM_TIP_EVE', 8, 9)
  #         cod_evento = ""
          
  #         if value[:ret_cons_sit_n_fe][:proc_evento_n_fe][z][:ret_evento][:inf_evento][:tp_evento] == codCiencia.CódigoValorDomínio
  #           codSitConf = dominio('DM_SIT_CONF', 2, 8)
  #           cod_evento = codSitConf.CódigoValorDomínio
  #         elsif value[:ret_cons_sit_n_fe][:proc_evento_n_fe][z][:ret_evento][:inf_evento][:tp_evento] == codConfirmar.CódigoValorDomínio
  #           codSitConf = dominio('DM_SIT_CONF', 2, 5)
  #           cod_evento = codSitConf.CódigoValorDomínio
  #         end   

  #         nf.update({idLoteEvento: "#{nf.id}#{value[:ret_cons_sit_n_fe][:proc_evento_n_fe][z][:inf_evento][:tp_evento]}", 
  #                               nrSequencialEvento: value[:ret_cons_sit_n_fe][:proc_evento_n_fe][z][:ret_evento][:inf_evento][:n_seq_evento],
  #                               dataRegistroEvento: value[:ret_cons_sit_n_fe][:proc_evento_n_fe][z][:ret_evento][:inf_evento][:dh_reg_evento],
  #                               nrProtocoloEvento: value[:ret_cons_sit_n_fe][:proc_evento_n_fe][z][:ret_evento][:inf_evento][:n_prot],
  #                               codSituacaoManifestacaoDestinatario: cod_evento})
  #         return msg.push "Nota atualizada com sucesso."
  #       else
  #         return msg.push "Retorno da sefaz não consta alterações de status."
  #       end
  #       # salvarConsultaProtocolo(nf,value)
  #     end
  #   end    
  # end  
=end

  def self.importar_xml(arquivo_xml, user_id)
    # arquivo_xml = "/home/samuel/35151204620018000147550010000610371136273330.xml"
    xml = Nokogiri::XML(File.open(arquivo_xml))
    begin
      node = xml.xpath("//xmlns:nfeProc")[0]
      chave_nfe = node.css("protNFe/infProt/chNFe").text
    rescue
      return nil, "Arquivo inválido!", :error
    end

    nfe = NotaFiscal.find_by_nrChaveNfe(chave_nfe)

    # Verifica se a nota já existe
    # ----------------------------------------------------------
    if nfe
      return nfe, "Nota já existente.", :error
    else      
      nfe = NotaFiscal.new
      produtos = []
      duplicatas = []

      # Dados da Nota
      # -------------------------------------------------------
      nfe.nrChaveNfe = node.css("protNFe/infProt/chNFe").text
      nfe.nrNfe = node.css("ide/nNF").text
      nfe.codModeloNfe = node.css("ide/mod").text
      nfe.serieNfe = node.css("ide/serie").text
      nfe.dtEmissaoNfe = node.css("ide/dhEmi").text
      nfe.dtSaidaEntradaNfe = node.css("ide/dhSaiEnt").text
      nfe.valorTotalNfe = node.css("total/ICMSTot/vNF").text
      nfe.codDestinoOperacaoDestinatario = node.css("ide/idDest").text
      nfe.codConsumidorFinal = node.css("ide/indFinal").text
      nfe.codPresencaComprador = node.css("ide/indPres").text
      nfe.codProcessoEmissao = node.css("ide/procEmi").text
      nfe.versaoProcesso = node.css("ide/verProc").text
      nfe.tipoEmissao = node.css("ide/tpEmis").text
      nfe.codFinalidadeEmissao = node.css("ide/finNFe").text
      nfe.naturezaOperacao = node.css("ide/natOp").text
      nfe.tipOperacao = node.css("ide/tpNF").text
      nfe.codFormaPagamento = node.css("ide/indPag").text
      nfe.nrProtocoloNfe = node.css("protNFe/infProt/nProt").text
      nfe.dtRecebimentoNfe = node.css("protNFe/infProt/dhRecbto").text
      nfe.informacoesComplementaresNfe = node.css("infAdic/infCpl").text
      nfe.xml_completo = xml.xpath("//xmlns:nfeProc").to_xml
      nfe.danfe = xml.xpath("//xmlns:nfeProc").to_xml
      empresa = Empresa.where("cnpj = ? ",  node.css("dest/CNPJ").text)
      nfe.empresa_id = empresa[0].id      


      # Totais da Nota
      # --------------------------------------------------------------
      nfe.valorBaseCalculoICMS = node.css("total/ICMSTot/vBC").text
      nfe.valorICMS = node.css("total/ICMSTot/vICMS").text
      nfe.valorICMSDesonerado = node.css("total/ICMSTot/vICMSDeson").text
      nfe.valorBaseCalculoICMSST = node.css("total/ICMSTot/vBCST").text
      nfe.valorICMSSubstituicao = node.css("total/ICMSTot/vST").text 
      nfe.valorTotalProduto = node.css("total/ICMSTot/vProd").text 
      nfe.valorFrete = node.css("total/ICMSTot/vFrete").text 
      nfe.valorSeguro = node.css("total/ICMSTot/vSeg").text
      nfe.valorOutrasDespesasAcessorias = node.css("total/ICMSTot/vOutro").text                  
      nfe.valorTotalIPI = node.css("total/ICMSTot/vIPI").text
      nfe.valorTotalDesconto = node.css("total/ICMSTot/vDesc").text
      nfe.valorTotalII = node.css("total/ICMSTot/vII").text 
      nfe.valorPIS = node.css("total/ICMSTot/vPIS").text 
      nfe.valorCOFINS = node.css("total/ICMSTot/vCOFINS").text 
      nfe.valorAproximadoTributos = node.css("total/ICMSTot/vTotTrib").text

      # Transporte
      # -------------------------------------------------------------------
      nfe.modalidadeFrete = node.css("transp/modFrete").text 
      nfe.cnpj_transportador = node.css("transp/transporta/CNPJ").text 
      nfe.cpf_transportador = node.css("transp/transporta/CPF").text 
      nfe.nome_transportador = node.css("transp/transporta/xNome").text
      nfe.ie_transportador = node.css("transp/transporta/IE").text 
      nfe.endereco_transportador = node.css("transp/transporta/xEnder").text 
      nfe.municipio_transportador = node.css("transp/transporta/xMun").text 
      nfe.uf_transportador = node.css("transp/transporta/UF").text 
      nfe.valor_servico_transporte = node.css("transp/retTransp/vServ").text 
      nfe.valor_bc_retencao_icms_transporte = node.css("transp/retTransp/vBCRet").text
      nfe.aliquota_retencao_icms_transporte = node.css("transp/retTransp/pICMSRet").text 
      nfe.valor_icms_retido_transporte = node.css("transp/retTransp/vICMSRet").text 
      nfe.cfop_transporte = node.css("transp/retTransp/CFOP").text 
      nfe.codigo_municipio_fator_gerador_icms_transporte = node.css("transp/retTransp/cMunFG").text 
      nfe.transporteQtde = node.css("transp/vol/qVol").text 
      nfe.transporteEspecie = node.css("transp/vol/esp").text 
      nfe.transporteMarcaDosVolumes = node.css("transp/vol/marca").text
      nfe.transporteNumeracao = node.css("transp/vol/nVol").text 
      nfe.transportePesoLiquido = node.css("transp/vol/pesoL").text 
      nfe.transportePesoBruto = node.css("transp/vol/pesoB").text 

      # Dados Emitente
      # ------------------------------------------------------
      nfe.nomeEmitente = node.css("emit/xNome").text
      nfe.nomeFantasiaEmitente = node.css("emit/xFant").text

      if node.css("emit/CNPJ").text != ""
        nfe.cpfCnpjEmitente = node.css("emit/CNPJ").text
      else
        nfe.cpfCnpjEmitente = node.css("emit/CPF").text
      end  
      
      nfe.logradouroEmitente = node.css("emit/enderEmit/xLgr").text
      nfe.nrEnderecoEmitente = node.css("emit/enderEmit/nro").text
      nfe.complementoEnderecoEmitente = node.css("emit/enderEmit/xCpl").text
      nfe.bairroEmitente = node.css("emit/enderEmit/xBairro").text
      nfe.cepEmitente = node.css("emit/enderEmit/CEP").text
      nfe.codMunicipioEmitente = node.css("emit/enderEmit/cMun").text
      nfe.municipioEmitente = node.css("emit/enderEmit/xMun").text
      nfe.telefoneEmitente = node.css("emit/enderEmit/fone").text
      nfe.ufEmitente = node.css("emit/enderEmit/UF").text
      nfe.codPaisEmitente = node.css("emit/enderEmit/cPais").text
      nfe.paisEmitente = node.css("emit/enderEmit/xPais").text 
      nfe.inscricaoEstadualEmitente = node.css("emit/IE").text
      nfe.inscricaoEstadualSubsTribEmitente = node.css("emit/IEST").text
      nfe.inscricaoMunicipalEmitente = node.css("emit/IM").text
      nfe.codMunicipioFatorGeradorICMSEmitente = node.css("emit/enderEmit/cMun").text
      nfe.cnaeFiscalEmitente = node.css("emit/CNAE").text
      nfe.crtEmitente = node.css("emit/CRT").text

      # Dados Destinatário
      # ------------------------------------------------------
      nfe.nomeDestinatario = node.css("dest/xNome").text      

      if node.css("dest/CNPJ").text != ""
        nfe.cpfCnpjDestinatario = node.css("dest/CNPJ").text
      else
        nfe.cpfCnpjDestinatario = node.css("dest/CPF").text
      end  

      nfe.logradouroDestinatario = node.css("dest/enderDest/xLgr").text
      nfe.nrEnderecoDestinatario = node.css("dest/enderDest/nro").text
      nfe.complementoEnderecoDestinatario = node.css("dest/enderDest/xCpl").text
      nfe.bairroDestinatario = node.css("dest/enderDest/xBairro").text
      nfe.cepDestinatario = node.css("dest/enderDest/CEP").text
      nfe.codMunicipioDestinatario = node.css("dest/enderDest/cMun").text
      nfe.municipioDestinatario = node.css("dest/enderDest/xMun").text 
      nfe.telefoneDestinatario = node.css("dest/enderDest/fone").text
      nfe.ufDestinatario = node.css("dest/enderDest/UF").text
      nfe.codPaisDestinatario = node.css("dest/enderDest/cPais").text
      nfe.paisDestinatario = node.css("dest/enderDest/xPais").text 
      nfe.inscricaoEstadualDestinatario = node.css("dest/IE").text 
      nfe.indicadorIEDestinatario = node.css("dest/indIEDest").text
      nfe.inscricaoSuframa = node.css("dest/ISUF").text
      nfe.inscricaoMunicipalTomadorServico = node.css("dest/IM").text
      nfe.emailDestinatario = node.css("dest/email").text
      
      # Status
      # ---------------------------------------------------------
      if node.css("protNFe/infProt/cStat").text == "100"
        nfe.codSituacaoNfe = 1
        nfe.codSituacaoManifestacaoDestinatario = 0
      end

      # Local entrega
      # ---------------------------------------------------------
      if node.css("entrega/CNPJ").text != ""
        nfe.entregaCpfCnpj = node.css("entrega/CNPJ").text
      else
        nfe.entregaCpfCnpj = node.css("entrega/CPF").text
      end      

      nfe.entregaLogradouro =  node.css("entrega/xLgr").text 
      nfe.entregaNumero = node.css("entrega/nro").text 
      nfe.entregaComplemento = node.css("entrega/xCpl").text 
      nfe.entregaBairro = node.css("entrega/xBairro").text  
      nfe.entregaMunicipio = node.css("entrega/xMun").text
      nfe.entregaUF = node.css("entrega/UF").text
    
      # Produtos
      # --------------------------------------------------------
      xml.xpath("//xmlns:det").each do |det|
        item = Hash.new
        item[:nrItem] =  det.attribute("nItem").text 
        item[:descricao] = det.css("prod/xProd").text
        item[:qtdeComercial] = det.css("prod/qCom").text 
        item[:qtdeTributavel] = det.css("prod/qTrib").text  
        item[:unidadeComercial] = det.css("prod/uCom").text
        item[:unidadeTributavel] = det.css("prod/uTrib").text
        item[:valorUnitarioComercializacao] = det.css("prod/vUnCom").text
        item[:valorUnitarioTributacao] = det.css("prod/vUnTrib").text 
        item[:codProduto] = det.css("prod/cProd").text  
        item[:codNCM] = det.css("prod/NCM").text
        item[:codExTIPI] = det.css("prod/EXTIPI").text       
        item[:cfop] = det.css("prod/CFOP").text
        item[:outrasDespesasAcessorias] = det.css("prod/vOutro").text 
        item[:valorDesconto] = det.css("prod/vDesc").text  
        item[:valorTotalFrete] = det.css("prod/vFrete").text
        item[:valorSeguro] = det.css("prod/vSeg").text       
        item[:indicadorComposicaoValorTotalNfe] = det.css("prod/indTot").text
        item[:codEANComercial] = det.css("prod/cEAN").text 
        item[:codEANTributavel] = det.css("prod/cEANTrib").text  
        item[:nrPedidoCompra] = det.css("prod/xPed").text
        item[:itemPedidoCompra] = det.css("prod/itemPedidoCompra").text                             
        item[:valorAproximadoTributos] = det.css("imposto/vTotTrib").text
        item[:nrFCI] = det.css("prod/nFCI").text 
        item[:informacoesAdicionaisProduto] = det.css("infAdProd").text
        item[:valorProduto] = det.css("prod/vProd").text 

        # - PIS
        # ---------------------------------------------
        if det.css("imposto/PIS").text != ""
          if det.css("imposto/PIS/PISAliq").text != ""
            item[:codSituacaoTribPIS] = det.css("imposto/PIS/PISAliq/CST").text
            item[:valorBCPIS] = det.css("imposto/PIS/PISAliq/vBC").text 
            item[:valorAliquotaPIS] = det.css("imposto/PIS/PISAliq/pPIS").text
            item[:valorPIS] = det.css("imposto/PIS/PISAliq/vPIS").text
          elsif det.css("imposto/PIS/PISOutr").text != ""
            item[:codSituacaoTribPIS] = det.css("imposto/PIS/PISOutr/CST").text
            item[:valorBCPIS] = det.css("imposto/PIS/PISOutr/vBC").text
            item[:valorAliquotaPIS] = det.css("imposto/PIS/PISOutr/pPIS").text
            item[:valorPIS] = det.css("imposto/PIS/PISOutr/vPIS").text
          else
             if det.css("imposto/PIS/PISNT").text != ""    
                item[:codSituacaoTribPIS] = det.css("imposto/PIS/PISNT/CST").text
             end 
          end 
        end 

        # - COFINS
        # ----------------------------------------------
        if det.css("imposto/COFINS").text != ""
          if det.css("imposto/COFINS/COFINSAliq").text != ""
            item[:codSituacaoTribCofins] = det.css("imposto/COFINS/COFINSAliq/CST").text
            item[:valorBCCofins] = det.css("imposto/COFINS/COFINSAliq/vBC").text
            item[:valorAliquotaCofins] = det.css("imposto/COFINS/COFINSAliq/pCOFINS").text
            item[:valorCofins] = det.css("imposto/COFINS/COFINSAliq/vCOFINS").text
          elsif det.css("imposto/COFINS/COFINSOutr").text != ""
            item[:codSituacaoTribCofins] = det.css("imposto/COFINS/COFINSOutr/CST").text
            item[:valorBCCofins] = det.css("imposto/COFINS/COFINSOutr/vBC").text
            item[:valorAliquotaCofins] = det.css("imposto/COFINS/COFINSOutr/pCOFINS").text
            item[:valorCofins] = det.css("imposto/COFINS/COFINSOutr/vCOFINS").text
          else
             if det.css("imposto/COFINS/COFINSNT").text != ""
                item[:codSituacaoTribCofins] = det.css("imposto/COFINS/COFINSNT/CST").text
             end 
          end 
        end 

        #  - ICMS
        # ---------------------------------------------
        if det.css("imposto/ICMS").text != ""
          if det.css("imposto/ICMS/ICMS00").text != ""           
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMS00/orig").text
            item[:codTributacaoICMS] = det.css("imposto/ICMS/ICMS00/CST").text
            item[:modalidadeBCICMS] = det.css("imposto/ICMS/ICMS00/modBC").text
            item[:valorBCICMS] = det.css("imposto/ICMS/ICMS00/vBC").text
            item[:valorAliquotaImpostoICMS] = det.css("imposto/ICMS/ICMS00/pICMS").text
            item[:valorICMS] = det.css("imposto/ICMS/ICMS00/vICMS").text
          elsif det.css("imposto/ICMS/ICMS20").text != ""           
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMS20/orig").text
            item[:codTributacaoICMS] = det.css("imposto/ICMS/ICMS20/CST").text
            item[:modalidadeBCICMS] = det.css("imposto/ICMS/ICMS20/modBC").text
            item[:percentual_reducao_bc_icms] = det.css("imposto/ICMS/ICMS20/pRedBC").text
            item[:valorBCICMS] = det.css("imposto/ICMS/ICMS20/vBC").text
            item[:valorAliquotaImpostoICMS] = det.css("imposto/ICMS/ICMS20/pICMS").text
            item[:valorICMS] = det.css("imposto/ICMS/ICMS20/vICMS").text
          elsif det.css("imposto/ICMS/ICMS40").text != ""
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMS40/orig").text
            item[:codTributacaoICMS] = det.css("imposto/ICMS/ICMS40/CST").text
          elsif det.css("imposto/ICMS/ICMS60").text != ""
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMS60/orig").text
            item[:codTributacaoICMS] = det.css("imposto/ICMS/ICMS60/CST").text
            item[:valorBCSTRet] = det.css("imposto/ICMS/ICMS60/vBCSTRet").text
            item[:valorICMSSTRet] = det.css("imposto/ICMS/ICMS60/vICMSSTRet").text
          elsif det.css("imposto/ICMS/ICMS90").text != ""           
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMS90/orig").text
            item[:codTributacaoICMS] = det.css("imposto/ICMS/ICMS90/CST").text
            item[:modalidadeBCICMS] = det.css("imposto/ICMS/ICMS90/modBC").text
            item[:valorBCICMS] = det.css("imposto/ICMS/ICMS90/vBC").text
            item[:valorAliquotaImpostoICMS] = det.css("imposto/ICMS/ICMS90/pICMS").text
            item[:valorICMS] = det.css("imposto/ICMS/ICMS90/vICMS").text
            item[:modalidade_determinacao_bc_icms_st] = det.css("imposto/ICMS/ICMS90/modBCST").text
            item[:valor_bc_icms_st] = det.css("imposto/ICMS/ICMS90/vBCST").text
            item[:aliquota_icms_st] = det.css("imposto/ICMS/ICMS90/pICMSST").text
            item[:valor_icms_st] = det.css("imposto/ICMS/ICMS90/vICMSST").text
            item[:percentual_reducao_bc_icms_st] = det.css("imposto/ICMS/ICMS90/pRedBCST").text
            item[:percentual_margem_valor_adicionado_icms_st] = det.css("imposto/ICMS/ICMS90/pMVAST").text                              
          elsif det.css("imposto/ICMS/ICMSSN101").text != ""
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMSSN101/orig").text
            item[:csosn] = det.css("imposto/ICMS/ICMSSN101/CSOSN").text
            item[:p_cred_sn] = det.css("imposto/ICMS/ICMSSN101/pCredSN").text
            item[:v_cred_icmssn] = det.css("imposto/ICMS/ICMSSN101/vCredICMSSN").text                             
          elsif det.css("imposto/ICMS/ICMSSN102").text != ""
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMSSN102/orig").text
            item[:csosn] = det.css("imposto/ICMS/ICMSSN102/CSOSN").text                          
          elsif det.css("imposto/ICMS/ICMSSN500").text != ""
            item[:origemMercadoria] = det.css("imposto/ICMS/ICMSSN500/orig").text
            item[:csosn] = det.css("imposto/ICMS/ICMSSN500/CSOSN").text
            item[:valorBCSTRet] = det.css("imposto/ICMS/ICMSSN500/vBCSTRet").text
            item[:valorICMSSTRet] = det.css("imposto/ICMS/ICMSSN500/vICMSSTRet").text                                                       
          elsif det.css("imposto/ICMS/ICMSSN900").text != ""
                item[:origemMercadoria] = det.css("imposto/ICMS/ICMSSN900/orig").text
                item[:csosn] = det.css("imposto/ICMS/ICMSSN900/CSOSN").text
                item[:modalidadeBCICMS] = det.css("imposto/ICMS/ICMSSN900/modBC").text
                item[:valorBCICMS] = det.css("imposto/ICMS/ICMSSN900/vBC").text
                item[:percentual_reducao_bc_icms] = det.css("imposto/ICMS/ICMSSN900/pRedBC").text
                item[:valorAliquotaImpostoICMS] = det.css("imposto/ICMS/ICMSSN900/pICMS").text
                item[:valorICMS] = det.css("imposto/ICMS/ICMSSN900/vICMS").text
                item[:modalidade_determinacao_bc_icms_st] = det.css("imposto/ICMS/ICMSSN900/modBCST").text
                item[:percentual_margem_valor_adicionado_icms_st] = det.css("imposto/ICMS/ICMSSN900/pMVAST").text
                item[:percentual_reducao_bc_icms_st] = det.css("imposto/ICMS/ICMSSN900/pRedBCST").text
                item[:valor_bc_icms_st] = det.css("imposto/ICMS/ICMSSN900/vBCST").text
                item[:aliquota_icms_st] = det.css("imposto/ICMS/ICMSSN900/pICMSST").text
                item[:valor_icms_st] = det.css("imposto/ICMS/ICMSSN900/vICMSST").text
                item[:p_cred_sn] = det.css("imposto/ICMS/ICMSSN101/pCredSN").text
                item[:v_cred_icmssn] = det.css("imposto/ICMS/ICMSSN101/vCredICMSSN").text                                                                                                                                                                                                                                
          end 
        end 

        #  - IPI
        # ---------------------------------------------
        if det.css("imposto/IPI").text != "" 
            item[:classe_enquadramento_ipi_cigarros_bebidas] = det.css("imposto/IPI/clEnq").text
            item[:cnpj_produtor_mercadoria] = det.css("imposto/IPI/CNPJProd").text
            item[:codigo_selo_controle_ipi] = det.css("imposto/IPI/cSelo").text
            item[:qtde_selo_controle_ipi] = det.css("imposto/IPI/qSelo").text
            item[:codEnquadramentoIPI] = det.css("imposto/IPI/cEnq").text
          if det.css("imposto/IPI/IPITrib").text != ""
            item[:codSituacaoTribIPI] = det.css("imposto/IPI/IPITrib/CST").text
            item[:valorBCIPI] = det.css("imposto/IPI/IPITrib/vBC").text    
            item[:valorAliquotaIPI] = det.css("imposto/IPI/IPITrib/pIPI").text
            item[:qtde_total_unidade_padrao] = det.css("imposto/IPI/IPITrib/qUnid").text
            item[:valor_unidade_tributavel] = det.css("imposto/IPI/IPITrib/vUnid").text
            item[:valorIPI] = det.css("imposto/IPI/IPITrib/vIPI").text  
          end

          if det.css("imposto/IPI/IPINT").text != ""
              item[:codSituacaoTribIPI] = det.css("imposto/IPI/IPINT/CST").text    
          end
        end 
       
        #  - II => Imposto de Importação
        # ---------------------------------------------
        if det.css("imposto/II").text != ""
          item[:valor_bc_imposto_importacao] = det.css("imposto/II/vBC").text
          item[:valor_despesas_aduaneiras] = det.css("imposto/II/vDespAdu").text
          item[:valor_imposto_importacao] = det.css("imposto/II/vII").text
          item[:valor_imposto_iof] = det.css("imposto/II/vIOF").text
        end 
        produtos.push(item)
      end
      
      # Duplicatas
      # -------------------------------------------------------
      xml.xpath("//xmlns:dup").each do |cobr|
        dup = Hash.new
        dup[:nrDuplicata] =  cobr.css("nDup").text 
        dup[:dtVencimento] = cobr.css("dVenc").text
        dup[:valorDuplicata] = cobr.css("vDup").text 
        duplicatas.push(dup)
      end

      # Nome dos relacionamentos (nested)
      # -----------------------------------------
      nfe.notaProdutos.build(produtos)
      nfe.notaDuplicatas.build(duplicatas)
        
      if nfe.save
        registrarLog("Nota importada do arquivo xml", user_id, nfe.id)
        return nfe, "Nota importada com sucesso!", :success
      else
        return nfe, "Não foi possível importar o XML: #{nfe.errors.full_messages.join("<br/>")}", :error
      end
    end
  end
    
  def self.atualiza_pis_confins
      # nfe = NotaFiscal.find(975)
      nfes = NotaFiscal.where("danfe is not null")
      nfes.each do |nfe|
         xml = Nokogiri::XML(nfe.danfe)
         xml.xpath("//xmlns:det").each do |node|
            # puts node.css("imposto/PISST")
            # exit
            itens = NotaProduto.where("notaFiscal_id = ? and codProduto = ?", nfe.id, node.css("prod/cProd").text)
            # Nota com mais de um produto com o mesmo codigo 
            # ----------------------------------------------
            if itens.length > 1 
               itens.each do |item|
                  if node.css("prod/cProd").text == item.codProduto && node.attribute("nItem").text == item.nrItem.to_s
                     #  - PIS
                     # ---------------------------------------------
                     if node.css("imposto/PIS").text != ""
                        if node.css("imposto/PIS/PISAliq").text != ""
                           item.update({
                              codSituacaoTribPIS: node.css("imposto/PIS/PISAliq/CST").text,
                              valorBCPIS: node.css("imposto/PIS/PISAliq/vBC").text,
                              valorAliquotaPIS: node.css("imposto/PIS/PISAliq/pPIS").text,
                              valorPIS: node.css("imposto/PIS/PISAliq/vPIS").text
                           })
                        elsif node.css("imposto/PIS/PISOutr").text != ""
                           item.update({
                              codSituacaoTribPIS: node.css("imposto/PIS/PISOutr/CST").text,
                              valorBCPIS: node.css("imposto/PIS/PISOutr/vBC").text,
                              valorAliquotaPIS: node.css("imposto/PIS/PISOutr/pPIS").text,
                              valorPIS: node.css("imposto/PIS/PISOutr/vPIS").text
                              }) 
                        else
                           if node.css("imposto/PIS/PISNT").text != ""    
                              item.update({codSituacaoTribPIS: node.css("imposto/PIS/PISNT/CST").text})
                           end 
                        end 
                     end 

                     # - COFINS
                     # ----------------------------------------------
                     if node.css("imposto/COFINS").text != ""
                        if node.css("imposto/COFINS/COFINSAliq").text != ""
                           item.update({
                              codSituacaoTribCofins: node.css("imposto/COFINS/COFINSAliq/CST").text,
                              valorBCCofins: node.css("imposto/COFINS/COFINSAliq/vBC").text,
                              valorAliquotaCofins: node.css("imposto/COFINS/COFINSAliq/pCOFINS").text,
                              valorCofins: node.css("imposto/COFINS/COFINSAliq/vCOFINS").text
                           })
                        elsif node.css("imposto/COFINS/COFINSOutr").text != ""
                           item.update({
                              codSituacaoTribCofins: node.css("imposto/COFINS/COFINSOutr/CST").text,
                              valorBCCofins: node.css("imposto/COFINS/COFINSOutr/vBC").text,
                              valorAliquotaCofins: node.css("imposto/COFINS/COFINSOutr/pCOFINS").text,
                              valorCofins: node.css("imposto/COFINS/COFINSOutr/vCOFINS").text
                           })                        
                        else
                           if node.css("imposto/COFINS/COFINSNT").text != ""
                              item.update({codSituacaoTribCofins: node.css("imposto/COFINS/COFINSNT/CST").text})
                           end 
                        end 
                     end 
                  end 
               end
            else
               if node.css("prod/cProd").text == itens[0][:codProduto] && node.attribute("nItem").text == itens[0].nrItem.to_s
                  #  - PIS
                  # ---------------------------------------------
                  if node.css("imposto/PIS").text != ""
                     if node.css("imposto/PIS/PISAliq").text != ""
                        itens[0].update({
                           codSituacaoTribPIS: node.css("imposto/PIS/PISAliq/CST").text,
                           valorBCPIS: node.css("imposto/PIS/PISAliq/vBC").text,
                           valorAliquotaPIS: node.css("imposto/PIS/PISAliq/pPIS").text,
                           valorPIS: node.css("imposto/PIS/PISAliq/vPIS").text
                        })
                     elsif node.css("imposto/PIS/PISOutr").text != ""
                        itens[0].update({
                           codSituacaoTribPIS: node.css("imposto/PIS/PISOutr/CST").text,
                           valorBCPIS: node.css("imposto/PIS/PISOutr/vBC").text,
                           valorAliquotaPIS: node.css("imposto/PIS/PISOutr/pPIS").text,
                           valorPIS: node.css("imposto/PIS/PISOutr/vPIS").text
                        })                   
                     else
                        if node.css("imposto/PIS/PISNT").text != ""    
                           itens[0].update({codSituacaoTribPIS: node.css("imposto/PIS/PISNT/CST").text})
                        end 
                     end 
                  end 

                  # - COFINS
                  # ----------------------------------------------
                  if node.css("imposto/COFINS").text != ""
                     if node.css("imposto/COFINS/COFINSAliq").text != ""
                        itens[0].update({
                           codSituacaoTribCofins: node.css("imposto/COFINS/COFINSAliq/CST").text,
                           valorBCCofins: node.css("imposto/COFINS/COFINSAliq/vBC").text,
                           valorAliquotaCofins: node.css("imposto/COFINS/COFINSAliq/pCOFINS").text,
                           valorCofins: node.css("imposto/COFINS/COFINSAliq/vCOFINS").text
                        })
                     elsif node.css("imposto/COFINS/COFINSOutr").text != ""
                        itens[0].update({
                           codSituacaoTribCofins: node.css("imposto/COFINS/COFINSOutr/CST").text,
                           valorBCCofins: node.css("imposto/COFINS/COFINSOutr/vBC").text,
                           valorAliquotaCofins: node.css("imposto/COFINS/COFINSOutr/pCOFINS").text,
                           valorCofins: node.css("imposto/COFINS/COFINSOutr/vCOFINS").text
                        })                    
                     else
                        if node.css("imposto/COFINS/COFINSNT").text != ""
                           itens[0].update({codSituacaoTribCofins: node.css("imposto/COFINS/COFINSNT/CST").text})
                        end 
                     end 
                  end 
                end           
            end
         end    
      end
  end

  def self.atualiza_icms
      # nfe = NotaFiscal.find(982)
      nfes = NotaFiscal.where("danfe is not null")
      nfes.each do |nfe|
         xml = Nokogiri::XML(nfe.danfe)
         xml.xpath("//xmlns:det").each do |node|
            # if node.css("imposto/ICMS/ICMSSN900").text != ""
            #   puts node.css("imposto/ICMS/ICMSSN900")
            #   # return
            # end  
            itens = NotaProduto.where("notaFiscal_id = ? and codProduto = ?", nfe.id, node.css("prod/cProd").text)
            # Nota com mais de um produto com o mesmo codigo 
            # ----------------------------------------------
            if itens.length > 1 
               itens.each do |item|
                  if node.css("prod/cProd").text == item.codProduto && node.attribute("nItem").text == item.nrItem.to_s
                     #  - ICMS
                     # ---------------------------------------------
                     if node.css("imposto/ICMS").text != ""
                        if node.css("imposto/ICMS/ICMS00").text != ""
                           item.update({
                              origemMercadoria: node.css("imposto/ICMS/ICMS00/orig").text,
                              codTributacaoICMS: node.css("imposto/ICMS/ICMS00/CST").text,
                              modalidadeBCICMS: node.css("imposto/ICMS/ICMS00/modBC").text,
                              valorBCICMS: node.css("imposto/ICMS/ICMS00/vBC").text,
                              valorAliquotaImpostoICMS: node.css("imposto/ICMS/ICMS00/pICMS").text,
                              valorICMS: node.css("imposto/ICMS/ICMS00/vICMS").text
                           })
                        elsif node.css("imposto/ICMS/ICMS20").text != ""
                           item.update({
                              origemMercadoria: node.css("imposto/ICMS/ICMS20/orig").text,
                              codTributacaoICMS: node.css("imposto/ICMS/ICMS20/CST").text,
                              modalidadeBCICMS: node.css("imposto/ICMS/ICMS20/modBC").text,
                              percentual_reducao_bc_icms: node.css("imposto/ICMS/ICMS20/pRedBC").text,
                              valorBCICMS: node.css("imposto/ICMS/ICMS20/vBC").text,
                              valorAliquotaImpostoICMS: node.css("imposto/ICMS/ICMS20/pICMS").text,
                              valorICMS: node.css("imposto/ICMS/ICMS20/vICMS").text
                            }) 
                        elsif node.css("imposto/ICMS/ICMS40").text != ""
                           item.update({
                              origemMercadoria: node.css("imposto/ICMS/ICMS40/orig").text,
                              codTributacaoICMS: node.css("imposto/ICMS/ICMS40/CST").text
                            })    
                        elsif node.css("imposto/ICMS/ICMS60").text != ""
                           item.update({
                              origemMercadoria: node.css("imposto/ICMS/ICMS60/orig").text,
                              codTributacaoICMS: node.css("imposto/ICMS/ICMS60/CST").text,
                              valorBCSTRet: node.css("imposto/ICMS/ICMS60/vBCSTRet").text,
                              valorICMSSTRet: node.css("imposto/ICMS/ICMS60/vICMSSTRet").text
                            })    
                        elsif node.css("imposto/ICMS/ICMS90").text != ""
                           item.update({
                              origemMercadoria: node.css("imposto/ICMS/ICMS90/orig").text,
                              codTributacaoICMS: node.css("imposto/ICMS/ICMS90/CST").text,
                              modalidadeBCICMS: node.css("imposto/ICMS/ICMS90/modBC").text,
                              valorBCICMS: node.css("imposto/ICMS/ICMS90/vBC").text,
                              valorAliquotaImpostoICMS: node.css("imposto/ICMS/ICMS90/pICMS").text,
                              valorICMS: node.css("imposto/ICMS/ICMS90/vICMS").text,
                              modalidade_determinacao_bc_icms_st: node.css("imposto/ICMS/ICMS90/modBCST").text,
                              valor_bc_icms_st: node.css("imposto/ICMS/ICMS90/vBCST").text,
                              aliquota_icms_st: node.css("imposto/ICMS/ICMS90/pICMSST").text,
                              valor_icms_st: node.css("imposto/ICMS/ICMS90/vICMSST").text,
                              percentual_reducao_bc_icms_st: node.css("imposto/ICMS/ICMS90/pRedBCST").text,
                              percentual_margem_valor_adicionado_icms_st: node.css("imposto/ICMS/ICMS90/pMVAST").text                              
                            }) 
                        elsif node.css("imposto/ICMS/ICMSSN101").text != ""
                           item.update({
                              origemMercadoria: node.css("imposto/ICMS/ICMSSN101/orig").text,
                              csosn: node.css("imposto/ICMS/ICMSSN101/CSOSN").text,
                              p_cred_sn: node.css("imposto/ICMS/ICMSSN101/pCredSN").text,
                              v_cred_icmssn: node.css("imposto/ICMS/ICMSSN101/vCredICMSSN").text                             
                            })                                                                                                                
                        elsif node.css("imposto/ICMS/ICMSSN102").text != ""
                           item.update({
                              origemMercadoria: node.css("imposto/ICMS/ICMSSN102/orig").text,
                              csosn: node.css("imposto/ICMS/ICMSSN102/CSOSN").text                          
                            })  
                        elsif node.css("imposto/ICMS/ICMSSN500").text != ""
                           item.update({
                              origemMercadoria: node.css("imposto/ICMS/ICMSSN500/orig").text,
                              csosn: node.css("imposto/ICMS/ICMSSN500/CSOSN").text,
                              valorBCSTRet: node.css("imposto/ICMS/ICMSSN500/vBCSTRet").text,
                              valorICMSSTRet: node.css("imposto/ICMS/ICMSSN500/vICMSSTRet").text                                                       
                            })  
                        elsif node.css("imposto/ICMS/ICMSSN900").text != ""
                           item.update({
                              origemMercadoria: node.css("imposto/ICMS/ICMSSN900/orig").text,
                              csosn: node.css("imposto/ICMS/ICMSSN900/CSOSN").text,
                              modalidadeBCICMS: node.css("imposto/ICMS/ICMSSN900/modBC").text,
                              valorBCICMS: node.css("imposto/ICMS/ICMSSN900/vBC").text,
                              percentual_reducao_bc_icms: node.css("imposto/ICMS/ICMSSN900/pRedBC").text,
                              valorAliquotaImpostoICMS: node.css("imposto/ICMS/ICMSSN900/pICMS").text,
                              valorICMS: node.css("imposto/ICMS/ICMSSN900/vICMS").text,
                              modalidade_determinacao_bc_icms_st: node.css("imposto/ICMS/ICMSSN900/modBCST").text,
                              percentual_margem_valor_adicionado_icms_st: node.css("imposto/ICMS/ICMSSN900/pMVAST").text,                              
                              percentual_reducao_bc_icms_st: node.css("imposto/ICMS/ICMSSN900/pRedBCST").text,
                              valor_bc_icms_st: node.css("imposto/ICMS/ICMSSN900/vBCST").text,
                              aliquota_icms_st: node.css("imposto/ICMS/ICMSSN900/pICMSST").text,
                              valor_icms_st: node.css("imposto/ICMS/ICMSSN900/vICMSST").text,
                              p_cred_sn: node.css("imposto/ICMS/ICMSSN101/pCredSN").text,
                              v_cred_icmssn: node.css("imposto/ICMS/ICMSSN101/vCredICMSSN").text                                
                            })                                                                                                                                                                                                  
                        end 
                     end 
                  end 
               end
            else
               if node.css("prod/cProd").text == itens[0][:codProduto] && node.attribute("nItem").text == itens[0].nrItem.to_s
                 #  - ICMS
                 # ---------------------------------------------
                 if node.css("imposto/ICMS").text != ""
                    if node.css("imposto/ICMS/ICMS00").text != ""
                       itens[0].update({
                          origemMercadoria: node.css("imposto/ICMS/ICMS00/orig").text,
                          codTributacaoICMS: node.css("imposto/ICMS/ICMS00/CST").text,
                          modalidadeBCICMS: node.css("imposto/ICMS/ICMS00/modBC").text,
                          valorBCICMS: node.css("imposto/ICMS/ICMS00/vBC").text,
                          valorAliquotaImpostoICMS: node.css("imposto/ICMS/ICMS00/pICMS").text,
                          valorICMS: node.css("imposto/ICMS/ICMS00/vICMS").text
                       })
                    elsif node.css("imposto/ICMS/ICMS20").text != ""
                       itens[0].update({
                          origemMercadoria: node.css("imposto/ICMS/ICMS20/orig").text,
                          codTributacaoICMS: node.css("imposto/ICMS/ICMS20/CST").text,
                          modalidadeBCICMS: node.css("imposto/ICMS/ICMS20/modBC").text,
                          percentual_reducao_bc_icms: node.css("imposto/ICMS/ICMS20/pRedBC").text,
                          valorBCICMS: node.css("imposto/ICMS/ICMS20/vBC").text,
                          valorAliquotaImpostoICMS: node.css("imposto/ICMS/ICMS20/pICMS").text,
                          valorICMS: node.css("imposto/ICMS/ICMS20/vICMS").text
                        }) 
                    elsif node.css("imposto/ICMS/ICMS40").text != ""
                       itens[0].update({
                          origemMercadoria: node.css("imposto/ICMS/ICMS40/orig").text,
                          codTributacaoICMS: node.css("imposto/ICMS/ICMS40/CST").text
                        })    
                    elsif node.css("imposto/ICMS/ICMS60").text != ""
                       itens[0].update({
                          origemMercadoria: node.css("imposto/ICMS/ICMS60/orig").text,
                          codTributacaoICMS: node.css("imposto/ICMS/ICMS60/CST").text,
                          valorBCSTRet: node.css("imposto/ICMS/ICMS60/vBCSTRet").text,
                          valorICMSSTRet: node.css("imposto/ICMS/ICMS60/vICMSSTRet").text
                        })    
                    elsif node.css("imposto/ICMS/ICMS90").text != ""
                       itens[0].update({
                          origemMercadoria: node.css("imposto/ICMS/ICMS90/orig").text,
                          codTributacaoICMS: node.css("imposto/ICMS/ICMS90/CST").text,
                          modalidadeBCICMS: node.css("imposto/ICMS/ICMS90/modBC").text,
                          valorBCICMS: node.css("imposto/ICMS/ICMS90/vBC").text,
                          valorAliquotaImpostoICMS: node.css("imposto/ICMS/ICMS90/pICMS").text,
                          valorICMS: node.css("imposto/ICMS/ICMS90/vICMS").text,
                          modalidade_determinacao_bc_icms_st: node.css("imposto/ICMS/ICMS90/modBCST").text,
                          valor_bc_icms_st: node.css("imposto/ICMS/ICMS90/vBCST").text,
                          aliquota_icms_st: node.css("imposto/ICMS/ICMS90/pICMSST").text,
                          valor_icms_st: node.css("imposto/ICMS/ICMS90/vICMSST").text,
                          percentual_reducao_bc_icms_st: node.css("imposto/ICMS/ICMS90/pRedBCST").text,
                          percentual_margem_valor_adicionado_icms_st: node.css("imposto/ICMS/ICMS90/pMVAST").text                              
                        }) 
                    elsif node.css("imposto/ICMS/ICMSSN101").text != ""
                       itens[0].update({
                          origemMercadoria: node.css("imposto/ICMS/ICMSSN101/orig").text,
                          csosn: node.css("imposto/ICMS/ICMSSN101/CSOSN").text,
                          p_cred_sn: node.css("imposto/ICMS/ICMSSN101/pCredSN").text,
                          v_cred_icmssn: node.css("imposto/ICMS/ICMSSN101/vCredICMSSN").text                             
                        })                                                                                                                
                    elsif node.css("imposto/ICMS/ICMSSN102").text != ""
                       itens[0].update({
                          origemMercadoria: node.css("imposto/ICMS/ICMSSN102/orig").text,
                          csosn: node.css("imposto/ICMS/ICMSSN102/CSOSN").text                          
                        })  
                    elsif node.css("imposto/ICMS/ICMSSN500").text != ""
                       itens[0].update({
                          origemMercadoria: node.css("imposto/ICMS/ICMSSN500/orig").text,
                          csosn: node.css("imposto/ICMS/ICMSSN500/CSOSN").text,
                          valorBCSTRet: node.css("imposto/ICMS/ICMSSN500/vBCSTRet").text,
                          valorICMSSTRet: node.css("imposto/ICMS/ICMSSN500/vICMSSTRet").text                                                       
                        })  
                    elsif node.css("imposto/ICMS/ICMSSN900").text != ""
                       itens[0].update({
                          origemMercadoria: node.css("imposto/ICMS/ICMSSN900/orig").text,
                          csosn: node.css("imposto/ICMS/ICMSSN900/CSOSN").text,
                          modalidadeBCICMS: node.css("imposto/ICMS/ICMSSN900/modBC").text,
                          valorBCICMS: node.css("imposto/ICMS/ICMSSN900/vBC").text,
                          percentual_reducao_bc_icms: node.css("imposto/ICMS/ICMSSN900/pRedBC").text,
                          valorAliquotaImpostoICMS: node.css("imposto/ICMS/ICMSSN900/pICMS").text,
                          valorICMS: node.css("imposto/ICMS/ICMSSN900/vICMS").text,
                          modalidade_determinacao_bc_icms_st: node.css("imposto/ICMS/ICMSSN900/modBCST").text,
                          percentual_margem_valor_adicionado_icms_st: node.css("imposto/ICMS/ICMSSN900/pMVAST").text,                              
                          percentual_reducao_bc_icms_st: node.css("imposto/ICMS/ICMSSN900/pRedBCST").text,
                          valor_bc_icms_st: node.css("imposto/ICMS/ICMSSN900/vBCST").text,
                          aliquota_icms_st: node.css("imposto/ICMS/ICMSSN900/pICMSST").text,
                          valor_icms_st: node.css("imposto/ICMS/ICMSSN900/vICMSST").text,
                          p_cred_sn: node.css("imposto/ICMS/ICMSSN101/pCredSN").text,
                          v_cred_icmssn: node.css("imposto/ICMS/ICMSSN101/vCredICMSSN").text                                
                        })                                                                                                                                                                                                  
                    end 
                 end  
               end           
            end
          end    
      end
  end

  def self.atualiza_ipi_ii
      # nfe = NotaFiscal.find(968)
      nfes = NotaFiscal.where("danfe is not null")
      nfes.each do |nfe|
         xml = Nokogiri::XML(nfe.danfe)
         xml.xpath("//xmlns:det").each do |node|
            # if node.css("imposto/II/vIOF").text != ""
            #   puts node.css("imposto/II/vIOF")
            #   # return
            # end  
            itens = NotaProduto.where("notaFiscal_id = ? and codProduto = ?", nfe.id, node.css("prod/cProd").text)
            # Nota com mais de um produto com o mesmo codigo 
            # ----------------------------------------------
            if itens.length > 1 
               itens.each do |item|
                  if node.css("prod/cProd").text == item.codProduto && node.attribute("nItem").text == item.nrItem.to_s
                     #  - IPI
                     # ---------------------------------------------
                     if node.css("imposto/IPI").text != "" 
                       item.update({
                          classe_enquadramento_ipi_cigarros_bebidas: node.css("imposto/IPI/clEnq").text,
                          cnpj_produtor_mercadoria: node.css("imposto/IPI/CNPJProd").text,
                          codigo_selo_controle_ipi: node.css("imposto/IPI/cSelo").text,
                          qtde_selo_controle_ipi: node.css("imposto/IPI/qSelo").text,
                          codEnquadramentoIPI: node.css("imposto/IPI/cEnq").text
                        })  
                        
                        if node.css("imposto/IPI/IPITrib").text != ""
                          item.update({
                            codSituacaoTribIPI: node.css("imposto/IPI/IPITrib/CST").text,    
                            valorBCIPI: node.css("imposto/IPI/IPITrib/vBC").text,    
                            valorAliquotaIPI: node.css("imposto/IPI/IPITrib/pIPI").text,    
                            qtde_total_unidade_padrao: node.css("imposto/IPI/IPITrib/qUnid").text,
                            valor_unidade_tributavel: node.css("imposto/IPI/IPITrib/vUnid").text,
                            valorIPI: node.css("imposto/IPI/IPITrib/vIPI").text  
                          })
                        end

                        if node.css("imposto/IPI/IPINT").text != ""
                          item.update({
                            codSituacaoTribIPI: node.css("imposto/IPI/IPINT/CST").text    
                          })
                        end
                     end 
                     
                     #  - II => Imposto de Importação
                     # ---------------------------------------------
                     if node.css("imposto/II").text != ""
                        item.update({  
                          valor_bc_imposto_importacao: node.css("imposto/II/vBC").text,    
                          valor_despesas_aduaneiras: node.css("imposto/II/vDespAdu").text,    
                          valor_imposto_importacao: node.css("imposto/II/vII").text,
                          valor_imposto_iof: node.css("imposto/II/vIOF").text
                        })                      
                     end                      
                  end 
               end
            else
               if node.css("prod/cProd").text == itens[0][:codProduto] && node.attribute("nItem").text == itens[0].nrItem.to_s
                 #  - IPI
                 # ---------------------------------------------
                 if node.css("imposto/IPI").text != "" 
                   itens[0].update({
                      classe_enquadramento_ipi_cigarros_bebidas: node.css("imposto/IPI/clEnq").text,
                      cnpj_produtor_mercadoria: node.css("imposto/IPI/CNPJProd").text,
                      codigo_selo_controle_ipi: node.css("imposto/IPI/cSelo").text,
                      qtde_selo_controle_ipi: node.css("imposto/IPI/qSelo").text,
                      codEnquadramentoIPI: node.css("imposto/IPI/cEnq").text
                    })  
                    
                    if node.css("imposto/IPI/IPITrib").text != ""
                      itens[0].update({
                        codSituacaoTribIPI: node.css("imposto/IPI/IPITrib/CST").text,    
                        valorBCIPI: node.css("imposto/IPI/IPITrib/vBC").text,    
                        valorAliquotaIPI: node.css("imposto/IPI/IPITrib/pIPI").text,    
                        qtde_total_unidade_padrao: node.css("imposto/IPI/IPITrib/qUnid").text,
                        valor_unidade_tributavel: node.css("imposto/IPI/IPITrib/vUnid").text,
                        valorIPI: node.css("imposto/IPI/IPITrib/vIPI").text  
                      })
                    end

                    if node.css("imposto/IPI/IPINT").text != ""
                      itens[0].update({
                        codSituacaoTribIPI: node.css("imposto/IPI/IPINT/CST").text    
                      })
                    end
                 end 
                 
                 #  - II => Imposto de Importação
                 # ---------------------------------------------
                 if node.css("imposto/II").text != ""
                    itens[0].update({  
                      valor_bc_imposto_importacao: node.css("imposto/II/vBC").text,    
                      valor_despesas_aduaneiras: node.css("imposto/II/vDespAdu").text,    
                      valor_imposto_importacao: node.css("imposto/II/vII").text,
                      valor_imposto_iof: node.css("imposto/II/vIOF").text
                    })                      
                 end                  
               end           
            end
          end    
      end
  end
end