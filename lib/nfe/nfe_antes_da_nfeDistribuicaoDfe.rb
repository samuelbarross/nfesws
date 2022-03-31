class Nfe

  # Realiza a busca por nosta fiscais destinadas a todas a empresas cadastradas
  # ---------------------------------------------------------------------------
  def self.consulta_todas_nfe
  	Empresa.where("senha_certificado is not null and senha_certificado != ''").each do |emp|
      # Verifica a validade do certificado
      # ----------------------------------
      certificado = OpenSSL::X509::Certificate.new(File.read("#{emp.path_certificado}/cert.pem"))
      if (certificado.not_after.strftime("%d/%m/%Y").to_date - DateTime.now.to_date).to_i.zero? 
    	 consulta_nfe_destinatario(emp)
      end 
    end
  end

  # Consome o serviço NFeConsultaDest da sefaz
  # ------------------------------------------
  def self.consulta_nfe_destinatario(emp)
    begin 
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
            salvar_cron(response.xml, emp.cnpj, data[:nfe_consulta_nf_dest_result][:ret_cons_n_fe_dest][:x_motivo])
            salvar_consulta_nfe(response, cnpj_destinatario)
          else
            retorno += "#{Time.new} #{emp.nome} #{data}"
            salvar_cron(response.xml, emp.cnpj, data[:nfe_consulta_nf_dest_result][:ret_cons_n_fe_dest][:x_motivo])
            puts retorno
          end          
          emp.update({ult_nsu: data[:nfe_consulta_nf_dest_result][:ret_cons_n_fe_dest][:ult_nsu]})  
        else
          retorno += "#{Time.new} #{emp.nome} #{data}"
          salvar_cron(response.xml, emp.cnpj, data[:nfe_consulta_nf_dest_result][:ret_cons_n_fe_dest][:x_motivo])
          puts retorno
        end
      else
        retorno += "#{Time.new} #{response.to_array.first}"
        salvar_cron(response.xml, emp.cnpj, "#{response.to_array.first}")
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

  # Salva as informações iniciais da nota
  # -----------------------------------------------------
  def self.salvar_consulta_nfe(response, cnpj_destinatario)
    node = Nokogiri::XML(response.xml)
    node.remove_namespaces!

    nf = nil

    # Inclui um nova nota fiscal.
    #--------------------------------
    node.css("resNFe").each do |nfe|
      nf = NotaFiscal.find_by_nrChaveNfe(nfe.css("chNFe").text)
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
        registrar_log("Nota encontrada para o destinatário" , 22, nota.id) # Usuário de sistema chamado sws id=22, registrar log que a nota foi encontrada pela cron.
      end
    end 

    # Atualiza o status da nota caso a mesma tenha sido cancelada pelo fornecedor/emitente.
    #--------------------------------------------------------------------------------------
    node.css("resCanc").each do |nfc|
      nf = NotaFiscal.find_by_nrChaveNfe(nfc.css("chNFe").text)
      unless nf.nil?
        if nfc.css("cSitNFe").text != nf.codSituacaoNfe.to_s || nfc.css("cSitConf").text != nf.codSituacaoManifestacaoDestinatario.to_s
          nf.update({
            codSituacaoNfe: nfc.css("cSitNFe").text.to_i, 
            codSituacaoManifestacaoDestinatario: nfc.css("cSitConf").text.to_i
          })          
          
          if nfc.css("cSitNFe").text != nf.codSituacaoNfe.to_s
            registrar_log("Status da nota atualizado para #{nf.codSituacaoNfe}" , 22, nf.id)  # Usuário de sistema chamado sws id=22, registrar log para saber que a nota foi REENVIADA pela sefaz e encontrada pela cron.
          elsif nfc.css("cSitConf").text != nf.codSituacaoManifestacaoDestinatario.to_s
            registrar_log("Status da manifestação atualizado para #{nf.codSituacaoManifestacaoDestinatario}" , 22, nf.id) 
          else
            registrar_log("Status nota/manifestação atualizados para #{nf.codSituacaoNfe}/#{nf.codSituacaoManifestacaoDestinatario}" , 22, nf.id)   
          end   
        end
      end  
    end
  end

  # Salva no banco informações sobre o manifesto
  # --------------------------------------------
  def self.salvar_manifestacao_destinatario(h)
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
        salvar_manifestacao_destinatario(value)
      end
    end
  end

  # Consome o serviço RecepcaoEvento da sefaz
  # -----------------------------------------
  def self.recepcao_evento(nfe_id, evento, user_id, just = "")
    nota_fiscal = NotaFiscal.find(nfe_id)
    emp = Empresa.where("cnpj = #{nota_fiscal.cpfCnpjDestinatario}").first
    xml = xml_for(evento, emp, nota_fiscal, just)
    
    begin
      client = Savon::Client.new(wsdl: "https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx?wsdl", ssl_cert_file: "#{emp.path_certificado}/cert.pem", ssl_cert_key_file: "#{emp.path_certificado}/key.pem", ssl_verify_mode: :none)
      response = client.call(:nfe_recepcao_evento, xml: xml, advanced_typecasting: false)
    rescue Exception => e
      certificado = OpenSSL::X509::Certificate.new(File.read("#{emp.path_certificado}/cert.pem"))
      if (certificado.not_after.strftime("%d/%m/%Y").to_date - DateTime.now.to_date).to_i.zero? 
        return "Operação inválida, certificado vencido..."
      end       
      # puts "ERRO: Problema com o servidor da sefaz... #{e.message}"
      return "Problemas com o servidor da sefaz..."
    end

    if !response.nil?
      if response.success?
        data = response.to_array.first
        if data[:nfe_recepcao_evento_result][:ret_env_evento][:ret_evento][:inf_evento][:c_stat] == "135"
          salvar_manifestacao_destinatario(data)  
          acao = "#{evento} - #{data[:nfe_recepcao_evento_result][:ret_env_evento][:ret_evento][:inf_evento][:x_evento]}"
          registrar_log(acao, user_id, nfe_id)
          return data[:nfe_recepcao_evento_result][:ret_env_evento][:ret_evento][:inf_evento][:x_evento]
        else 
          # return atualiza_status_nfe(nota_fiscal, response, user_id) 
          return "status: #{data[:nfe_recepcao_evento_result][:ret_env_evento][:ret_evento][:inf_evento][:c_stat]}, #{data[:nfe_recepcao_evento_result][:ret_env_evento][:ret_evento][:inf_evento][:x_motivo]}."
        end
      end
    else
      return "Ocilação no servidor da sefaz, favor tentar em instantes..."        
    end
  end

  # Monta o xml para da ciência ou confirmar a operação
  # ---------------------------------------------------
  def self.xml_for(evento, emp, nota_fiscal, just = "")
    certificado = OpenSSL::PKCS12.new(File.read("#{emp.path_certificado}/certificado.pfx"),"#{emp.senha_certificado}")
    
    # Confirmar
    # ----------------------
    if evento == NotaFiscal.tipo_eventos[:"Confirmação da Operação"].to_s
      tagEvento = '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><infEvento Id="'"ID" << evento << nota_fiscal.nrChaveNfe.to_s << "01"'"><cOrgao>91</cOrgao><tpAmb>1</tpAmb><CNPJ>' << nota_fiscal.cpfCnpjDestinatario.to_s << '</CNPJ><chNFe>' << nota_fiscal.nrChaveNfe.to_s << '</chNFe><dhEvento>' << Time.now.strftime("%Y-%m-%d").to_s << 'T' << Time.now.strftime("%H:%M:%S").to_s << '-03:00</dhEvento><tpEvento>' << evento << '</tpEvento><nSeqEvento>1</nSeqEvento><verEvento>1.00</verEvento><detEvento versao="1.00"><descEvento>Confirmacao da Operacao</descEvento></detEvento></infEvento></evento>'

    # Ciência
    # ----------------------
    elsif evento == NotaFiscal.tipo_eventos[:"Ciência da Emissão"].to_s
      tagEvento = '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><infEvento Id="'"ID" << evento << nota_fiscal.nrChaveNfe.to_s << "01"'"><cOrgao>91</cOrgao><tpAmb>1</tpAmb><CNPJ>' << nota_fiscal.cpfCnpjDestinatario.to_s  << '</CNPJ><chNFe>' << nota_fiscal.nrChaveNfe.to_s << '</chNFe><dhEvento>' << Time.now.strftime("%Y-%m-%d").to_s << 'T' << Time.now.strftime("%H:%M:%S").to_s << '-03:00</dhEvento><tpEvento>' << evento << '</tpEvento><nSeqEvento>1</nSeqEvento><verEvento>1.00</verEvento><detEvento versao="1.00"><descEvento>Ciencia da Operacao</descEvento></detEvento></infEvento></evento>'

    # Desconhecimento da Operação
    # ----------------------------      
    elsif evento == NotaFiscal.tipo_eventos[:"Desconhecimento da Operação"].to_s
      tagEvento = '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><infEvento Id="'"ID" << evento << nota_fiscal.nrChaveNfe.to_s << "01"'"><cOrgao>91</cOrgao><tpAmb>1</tpAmb><CNPJ>' << nota_fiscal.cpfCnpjDestinatario.to_s  << '</CNPJ><chNFe>' << nota_fiscal.nrChaveNfe.to_s << '</chNFe><dhEvento>' << Time.now.strftime("%Y-%m-%d").to_s << 'T' << Time.now.strftime("%H:%M:%S").to_s << '-03:00</dhEvento><tpEvento>' << evento << '</tpEvento><nSeqEvento>1</nSeqEvento><verEvento>1.00</verEvento><detEvento versao="1.00"><descEvento>Desconhecimento da Operacao</descEvento></detEvento></infEvento></evento>'

    # Operação não Realizada
    # ----------------------      
    elsif evento == NotaFiscal.tipo_eventos[:"Operação não Realizada"].to_s
      tagEvento = '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00"><infEvento Id="'"ID" << evento << nota_fiscal.nrChaveNfe.to_s << "01"'"><cOrgao>91</cOrgao><tpAmb>1</tpAmb><CNPJ>' << nota_fiscal.cpfCnpjDestinatario.to_s  << '</CNPJ><chNFe>' << nota_fiscal.nrChaveNfe.to_s << '</chNFe><dhEvento>' << Time.now.strftime("%Y-%m-%d").to_s << 'T' << Time.now.strftime("%H:%M:%S").to_s << '-03:00</dhEvento><tpEvento>' << evento << '</tpEvento><nSeqEvento>1</nSeqEvento><verEvento>1.00</verEvento><detEvento versao="1.00"><descEvento>Operacao nao Realizada</descEvento><xJust>' << just << '</xJust></detEvento></infEvento></evento>'
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
      certificado = OpenSSL::X509::Certificate.new(File.read("#{emp.path_certificado}/cert.pem"))
      if (certificado.not_after.strftime("%d/%m/%Y").to_date - DateTime.now.to_date).to_i.zero? 
        return msg.push "Operação inválida, certificado vencido..."
      end       
      # puts "ERRO: Problema com o servidor da sefaz... #{e.message}"
      return msg.push "Problemas com o servidor da sefaz, tente mais tarde..."
    end

    if !response.nil?
      if response.success? 
        data = response.to_array.first
        # binding.pry
        if data[:nfe_download_nf_result][:ret_download_n_fe][:ret_n_fe][:c_stat] == "140"
          salvar_download_nfe(response, nfe)
          registrar_log("Download Nfe", user_id, nfe_id)          
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
  end

  # Registra na tabela log as ações do usuário
  # ------------------------------------------
  def self.registrar_log(acao, user_id, nfe_id)
    log = Log.new
    log[:acao] = acao
    log.user = User.find(user_id) #Acossiação 
    log.nota_fiscal = NotaFiscal.find(nfe_id) #Acossiação obs log.nota_fiscal é nome da associação na tabala de log
    log.save
  end  

=begin
  # Atualiza o status da nfe de acordo com o evento
  # -----------------------------------------------
  def self.atualiza_status_nfe(nf, response, user_id)
    node = Nokogiri::XML(response.xml)
    node.remove_namespaces!
    
    cod_evento_dest = 0 
  
    if node.css("retEnvEvento/retEvento/infEvento/tpEvento").text == NotaFiscal.tipo_eventos[:"Ciência da Emissão"].to_s
      cod_evento_dest = NotaFiscal.codSituacaoManifestacaoDestinatarios[:Ciência]
    elsif node.css("retEnvEvento/retEvento/infEvento/tpEvento").text == NotaFiscal.tipo_eventos[:"Confirmação da Operação"].to_s
      cod_evento_dest = NotaFiscal.codSituacaoManifestacaoDestinatarios[:Confirmada]
    end  

    if node.css("retEnvEvento/retEvento/infEvento/cStat").text == "573" # Duplicidade
      nf.update({ idLoteEvento: node.css("retEnvEvento/idLote").text, 
                  nrSequencialEvento: node.css("retEnvEvento/retEvento/infEvento/nSeqEvento").text, 
                  dataRegistroEvento: node.css("retEnvEvento/retEvento/infEvento/dhRegEvento").text.to_time,
                  codSituacaoManifestacaoDestinatario: cod_evento_dest
                }) 

      registrar_log("Status da manifestação atualizado - #{node.css("retEnvEvento/retEvento/infEvento/xEvento").text}", user_id, nf.id)      

      return "Nota atualizada com sucesso."

    elsif node.css("retEnvEvento/retEvento/infEvento/cStat").text == "650" # Cancelada
      nf.update({ idLoteEvento: node.css("retEnvEvento/idLote").text, 
                  nrSequencialEvento: node.css("retEnvEvento/retEvento/infEvento/nSeqEvento").text, 
                  dataRegistroEvento: node.css("retEnvEvento/retEvento/infEvento/dhRegEvento").text.to_time,
                  codSituacaoNfe: NotaFiscal.codSituacaoNfes[:Cancelada], 
                  codSituacaoManifestacaoDestinatario: cod_evento_dest
                }) 

      registrar_log("Status da nfe atualizado - #{node.css("retEnvEvento/retEvento/infEvento/xEvento").text}", user_id, nf.id)  

      return "Nota atualizada com sucesso."  

    else
      return "Problemas na atualização, status: #{node.css("retEnvEvento/retEvento/infEvento/cStat").text}, #{node.css("retEnvEvento/retEvento/infEvento/xMotivo").text}."
    end
  end
=end

  # Importa a nota fiscal direto do arquivo xml
  # -------------------------------------------
  def self.importar_xml(arquivo_xml, user_id)
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
        registrar_log("Nota importada do arquivo xml", user_id, nfe.id)
        return nfe, "Nota importada com sucesso!", :success
      else
        return nfe, "Não foi possível importar o XML: #{nfe.errors.full_messages.join("<br/>")}", :error
      end
    end
  end

    def self.salvar_cron(arquivo_xml_retorno, cnpj, mensagem)
        cron = Cron.new
        cron.data = Time.new
        cron.cnpj = cnpj
        cron.xml_retorno = arquivo_xml_retorno
        cron.mensagem = mensagem
        cron.save    
    end

    def self.importa_cte(path)
        begin
            Dir.glob(path << "/*-cte.xml").each do |arquivo|
                xml = Nokogiri::XML(File.open(arquivo))
                node = xml.xpath("//xmlns:cteProc")[0]
                chave_cte = node.css("protCTe/infProt/chCTe").text

                cte = Cte.find_by_chave_cte(chave_cte)

                unless cte.presence
                    cte = Cte.new
                    cte_notas = []

                    # Dados do CT-e
                    # ------------------------------------------
                    cte.chave_cte = chave_cte
                    cte.codigo_uf = node.css("ide/cUF").text
                    cte.codigo_ct = node.css("ide/cCT").text
                    cte.codigo_fop = node.css("ide/CFOP").text
                    cte.natureza_operacao = node.css("ide/natOp").text
                    cte.forma_pagamento = node.css("ide/forPag").text
                    cte.modelo = node.css("ide/mod").text
                    cte.serie = node.css("ide/serie").text
                    cte.numero_ct = node.css("ide/nCT").text
                    cte.data_hora_emissao = Time.parse(node.css("ide/dhEmi").text)
                    cte.tipo_impressao = node.css("ide/tpImp").text
                    cte.tipo_emissao = node.css("ide/tpEmis").text
                    cte.codigo_dv = node.css("ide/cDV").text
                    cte.tipo_ambiente = node.css("ide/tpAmb").text
                    cte.tipo_cte = node.css("ide/tpCTe").text
                    cte.processo_emissao = node.css("ide/procEmi").text
                    cte.versao_processo_emissao = node.css("ide/verProc").text
                    cte.cte_referenciado = node.css("ide/refCTE").text
                    cte.codigo_municipio_envio = node.css("ide/cMunEnv").text
                    cte.nome_municipio_envio = node.css("ide/xMunEnv").text
                    cte.uf_envio = node.css("ide/UFEnv").text
                    cte.modal = node.css("ide/modal").text
                    cte.tipo_servico = node.css("ide/tpServ").text
                    cte.codigo_municipio_inicio = node.css("ide/cMunIni").text
                    cte.nome_municipio_inicio = node.css("ide/xMunIni").text
                    cte.uf_inicio = node.css("ide/UFIni").text
                    cte.codigo_municipio_fim = node.css("ide/cMunFim").text
                    cte.nome_municipio_fim = node.css("ide/xMunFim").text
                    cte.uf_fim = node.css("ide/UFFim").text
                    cte.retira = node.css("ide/retira").text
                    cte.detalhes_retira = node.css("ide/xDetRetira").text

                    if node.css("ide/toma03").presence
                        cte.toma = node.css("ide/toma03/toma").text
                    else
                        cte.toma = node.css("ide/toma4/toma").text
                        cte.cnpj_tomador = node.css("ide/toma4/CNPJ").text
                        cte.cpf_tomador = node.css("ide/toma4/CPF").text
                        cte.ie_tomador = node.css("ide/toma4/IE").text
                        cte.nome_tomador = node.css("ide/toma4/xNome").text.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ' '})
                        cte.nome_fantasia_tomador = node.css("ide/toma4/xFant").text.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ' '})
                        cte.fone_tomador = node.css("ide/toma4/fone").text
                        cte.logradouro_tomador = node.css("ide/toma4/enderToma/xLgr").text
                        cte.numero_endereco_tomador = node.css("ide/toma4/enderToma/nro").text
                        cte.endereco_complemento_tomador = node.css("ide/toma4/enderToma/xCpl").text
                        cte.bairro_tomador = node.css("ide/toma4/enderToma/xBairro").text
                        cte.codigo_municipio_tomador = node.css("ide/toma4/enderToma/cMun").text
                        cte.nome_municipio_tomador = node.css("rem/enderReme/xMun").text
                        cte.cep_tomador = node.css("ide/toma4/enderToma/CEP").text
                        cte.uf_tomador = node.css("ide/toma4/enderToma/UF").text
                        cte.codigo_pais_tomador = node.css("ide/toma4/enderToma/cPais").text
                        cte.nome_pais_tomador = node.css("ide/toma4/enderToma/xPais").text
                        cte.email_tomador = node.css("ide/toma4/email").text
                    end

                    cte.observacoes = node.css("compl/xObs").text

                    # Observações do Contribuinte
                    # ------------------------------------------
                    obs_cliente = ""
                    node.css("compl/ObsCont").each do |obs_cont|
                        if obs_cont.attribute("xCampo").text == "Identificador"
                            if obs_cont.css("xTexto").text.index("|").presence
                                cte.identificador_cte  =  obs_cont.css("xTexto").text[obs_cont.css("xTexto").text.index(".") + 1..obs_cont.css("xTexto").text.index(" ") - 1]
                            else
                                cte.identificador_cte  =  obs_cont.css("xTexto").text[obs_cont.css("xTexto").text.index(".") + 1..obs_cont.css("xTexto").text.length]
                            end
                        elsif obs_cont.attribute("xCampo").text == "CodRemetente"
                            if obs_cont.css("xTexto").text.index("-").presence
                                cte.codigo_remetente = obs_cont.css("xTexto").text[0..obs_cont.css("xTexto").text.index("-")- 1]
                            else
                                cte.codigo_remetente = obs_cont.css("xTexto").text
                            end
                        elsif obs_cont.attribute("xCampo").text == "CodDestinario"
                            if obs_cont.css("xTexto").text.index("-").presence
                                cte.codigo_destinatario = obs_cont.css("xTexto").text[0..obs_cont.css("xTexto").text.index("-")- 1]
                            else
                                cte.codigo_destinatario = obs_cont.css("xTexto").text
                            end
                        else
                            obs_cliente << obs_cont.css("xTexto").text << " "
                        end   
                    end
                    
                    cte.observacoes_cliente = obs_cliente

                    # Dados do Emitente
                    # -----------------------------------------------------------------
                    cte.cnpj_emitente = node.css("emit/CNPJ").text
                    cte.inscricao_estadual_emitente = node.css("emit/IE").text
                    cte.nome_emitente = node.css("emit/xNome").text
                    cte.nome_fantasia_emitente = node.css("emit/xFant").text
                    cte.logradouro_emitente = node.css("emit/enderEmit/xLgr").text
                    cte.numero_endereco_emitente = node.css("emit/enderEmit/nro").text
                    cte.complemento_endereco_emitente = node.css("emit/enderEmit/xCpl").text
                    cte.bairro_emitente = node.css("emit/enderEmit/xBairro").text
                    cte.codigo_municipio_emitente = node.css("emit/enderEmit/cMun").text
                    cte.nome_municipio_emitente = node.css("emit/enderEmit/xMun").text
                    cte.cep_emitente = node.css("emit/enderEmit/CEP").text
                    cte.uf_emitente = node.css("emit/enderEmit/UF").text
                    cte.fone_emitente = node.css("emit/enderEmit/fone").text

                    # Dados do Remetente
                    # -----------------------------------------------------------------
                    cte.cnpj_remetente = node.css("rem/CNPJ").text
                    cte.cpf_remetente = node.css("rem/CPF").text
                    cte.inscricao_estadual_remetente = node.css("rem/IE").text
                    cte.nome_remetente = node.css("rem/xNome").text.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ' '})
                    cte.nome_fantasia_remetente = node.css("dest/xFant").text
                    cte.fone_remetente = node.css("rem/fone").text
                    cte.logradouro_remetente = node.css("rem/enderReme/xLgr").text.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ' '})
                    cte.numero_endereco_remetente = node.css("rem/enderReme/nro").text
                    cte.complemento_endereco_remetente = node.css("rem/enderReme/xCpl").text.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ' '})
                    cte.bairro_remetente = node.css("rem/enderReme/xBairro").text
                    cte.codigo_municipio_remetente = node.css("rem/enderReme/cMun").text
                    cte.nome_municipio_remetente = node.css("rem/enderReme/xMun").text
                    cte.cep_remetente = node.css("rem/enderReme/CEP").text
                    cte.uf_remetente = node.css("rem/enderReme/UF").text
                    cte.codigo_pais_remetente = node.css("rem/enderReme/cPais").text
                    cte.nome_pais_remetente = node.css("rem/enderReme/xPais").text
                    cte.email_remetente = node.css("rem/email").text

                    # Dados do Destinatário
                    # -----------------------------------------------------------------
                    cte.cnpj_destinatario = node.css("dest/CNPJ").text
                    cte.cpf_destinatario = node.css("dest/CPF").text
                    cte.inscricao_estadual_destinatario = node.css("dest/IE").text
                    cte.nome_destinatario = node.css("dest/xNome").text.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ' '})
                    cte.fone_destinatario = node.css("dest/fone").text
                    cte.suframa_destinatario = node.css("dest/ISUF").text
                    cte.logradouro_destinatario = node.css("dest/enderDest/xLgr").text.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ' '})
                    cte.numero_endereco_destinatario = node.css("dest/enderDest/nro").text
                    cte.complemento_endereco_destinatario = node.css("dest/enderDest/xCpl").text
                    cte.bairro_destinatario = node.css("dest/enderDest/xBairro").text
                    cte.codigo_municipio_destinatario = node.css("dest/enderDest/cMun").text
                    cte.nome_municipio_destinatario = node.css("dest/enderDest/xMun").text
                    cte.cep_destinatario = node.css("dest/enderDest/CEP").text
                    cte.uf_destinatario = node.css("dest/enderDest/UF").text
                    cte.codigo_pais_destinatario = node.css("dest/enderDest/cPais").text
                    cte.nome_pais_destinatario = node.css("dest/enderDest/xPais").text
                    cte.email_destinatario = node.css("dest/email").text


                    # Valores da Prestação de Serviço
                    # -----------------------------------------------------------------
                    cte.valor_total_prestacao_servico = node.css("vPrest/vTPrest").text
                    cte.valor_receber = node.css("vPrest/vRec").text

                    node.css("vPrest/Comp").each do |comp|
                        if comp.css("xNome").text == "FRETE PESO"
                            cte.valor_frete_peso  = comp.css("vComp").text
                        elsif comp.css("xNome").text == "FRETE VALOR"
                            cte.valor_frete  = comp.css("vComp").text
                        elsif comp.css("xNome").text == "DEBITO/CREDITO"
                            cte.valor_debito_credito  = comp.css("vComp").text
                        elsif comp.css("xNome").text == "CAT"
                            cte.valor_cat  = comp.css("vComp").text
                        elsif comp.css("xNome").text == "PEDAGIO"
                            cte.valor_pedagio  = comp.css("vComp").text
                        elsif comp.css("xNome").text == "DESPACHO"
                            cte.valor_despacho  = comp.css("vComp").text
                        elsif comp.css("xNome").text == "GRIS"
                            cte.valor_gris  = comp.css("vComp").text
                        elsif comp.css("xNome").text == "ITR"
                            cte.valor_itr  = comp.css("vComp").text
                        else
                            cte.valor_outros_ademe  = comp.css("vComp").text            
                        end
                    end

                    # Informações relativas aos Impostos
                    # -----------------------------------------------------------------
                    if node.css("imp/ICMS/ICMS00").presence
                        cte.classificacao_tributaria_servico =  node.css("imp/ICMS/ICMS00/CST").text
                        cte.valor_bc_icms =  node.css("imp/ICMS/ICMS00/vBC").text
                        cte.percentual_aliquota_icms =  node.css("imp/ICMS/ICMS00/pICMS").text
                        cte.valor_icms =  node.css("imp/ICMS/ICMS00/vICMS").text
                    elsif node.css("imp/ICMS/ICMS20").presence
                        cte.classificacao_tributaria_servico =  node.css("imp/ICMS/ICMS20/CST").text
                        cte.percentual_reducao_bc =  node.css("imp/ICMS/ICMS20/pRedBC").text
                        cte.valor_bc_icms =  node.css("imp/ICMS/ICMS20/vBC").text
                        cte.percentual_aliquota_icms =  node.css("imp/ICMS/ICMS20/pICMS").text
                        cte.valor_icms =  node.css("imp/ICMS/ICMS20/vICMS").text
                    elsif node.css("imp/ICMS/ICMS45").presence
                        cte.classificacao_tributaria_servico =  node.css("imp/ICMS/ICMS45/CST").text
                    elsif node.css("imp/ICMS/ICMS60").presence
                        cte.classificacao_tributaria_servico =  node.css("imp/ICMS/ICMS60/CST").text
                        cte.valor_bc_icms_st_retido =  node.css("imp/ICMS/ICMS60/vBCSTRet").text
                        cte.valor_icms_st_retido =  node.css("imp/ICMS/ICMS60/vICMSSTRet").text
                        cte.percentual_aliquota_icms_retido =  node.css("imp/ICMS/ICMS60/pICMSSTRet").text
                        cte.valor_credito =  node.css("imp/ICMS/ICMS60/vCred").text
                    elsif node.css("imp/ICMS/ICMS90").presence
                        cte.classificacao_tributaria_servico =  node.css("imp/ICMS/ICMS90/CST").text
                        cte.percentual_reducao_bc =  node.css("imp/ICMS/ICMS90/pRedBC").text
                        cte.valor_bc_icms =  node.css("imp/ICMS/ICMS90/vBC").text
                        cte.percentual_aliquota_icms =  node.css("imp/ICMS/ICMS90/pICMS").text
                        cte.valor_icms =  node.css("imp/ICMS/ICMS90/vICMS").text
                        cte.valor_credito =  node.css("imp/ICMS/ICMS90/vCred").text
                    elsif node.css("imp/ICMS/ICMSOutraUF").presence
                        cte.classificacao_tributaria_servico =  node.css("imp/ICMS/ICMSOutraUF/CST").text
                        cte.percentual_reducao_bc_outra_uf =  node.css("imp/ICMS/ICMSOutraUF/pRedBCOutraUF").text
                        cte.valor_bc_icms_outra_uf =  node.css("imp/ICMS/ICMSOutraUF/vBCOutraUF").text
                        cte.percentual_aliquota_icms_outra_uf =  node.css("imp/ICMS/ICMSOutraUF/pICMSOutraUF").text
                        cte.valor_icms_outra_uf =  node.css("imp/ICMS/ICMSOutraUF/vICMSOutraUF").text
                     elsif node.css("imp/ICMS/ICMSSN").presence
                        cte.indicador_icms_sn =  node.css("imp/ICMS/ICMSSN/indSN").text
                    end

                    cte.valor_total_tributos = node.css("imp/ICMS/vTotTrib").text
                    cte.informacoes_adicionais_fisco = node.css("imp/ICMS/infAdFisco").text


                    # Grupo de informações do CT-e Normal CG e Substituto
                    # --------------------------------------------------------
                    cte.valor_carga = node.css("infCTeNorm/infCarga/vCarga").text
                    cte.produto_predominante = node.css("infCTeNorm/infCarga/proPred").text
                    cte.outras_caracteristicas_carga = node.css("infCTeNorm/infCarga/xOutCat").text

                    node.css("infCTeNorm/infCarga/infQ").each do |infq|
                        if infq.css("tpMed").text == "PESO BRUTO"
                            cte.unidade_peso_bruto = infq.css("cUnid").text
                            cte.medida_peso_bruto = infq.css("tpMed").text
                            cte.quantidade_peso_bruto = infq.css("qCarga").text
                        elsif infq.css("tpMed").text == "PESO BASE DE CALCULO"
                            cte.unidade_peso_base_calculo = infq.css("cUnid").text
                            cte.medida_peso_base_calculo = infq.css("tpMed").text
                            cte.quantidade_peso_base_calculo = infq.css("qCarga").text
                        else
                            cte.unidade_quantidade_volume = infq.css("cUnid").text
                            cte.medida_quantidade_volume = infq.css("tpMed").text
                            cte.quantidade_volume = infq.css("qCarga").text
                        end
                    end

                    # Notas do CT-e
                    # -------------------------------------------------------
                    if node.css("infDoc").presence
                        node.css("infDoc/infNFe").each do |infq|
                            notas = Hash.new
                            notas[:chave_nfe] =  infq.css("chave").text
                            cte_notas.push(notas)
                        end
                        cte.cte_notas.build(cte_notas)
                    end

                    if node.css("seg").presence
                        cte.responsavel_seguro = node.css("seg/respSeg").text
                        cte.nome_seguradora = node.css("seg/xSeg").text
                        cte.numero_apolice = node.css("seg/nApol").text
                        cte.numero_averbacao = node.css("seg/nAver").text
                        cte.valor_carga_averbacao = node.css("seg/vCarga").text
                    end    
                    
                    if node.css("infCTeNorm/infModal").presence 
                        cte.versao_modal = node.css("infCTeNorm/infModal").attribute("versaoModal").text
                        cte.rntrc = node.css("infCTeNorm/infModal/rodo/RNTRC").text
                        cte.lota = node.css("infCTeNorm/infModal/rodo/lota").text
                        cte.ciot = node.css("infCTeNorm/infModal/rodo/CIOT").text
                    end


                    cte.ambiente_protocolo = node.css("protCTe/infProt/tpAmb").text
                    cte.protocolo_versao_aplicacao = node.css("protCTe/infProt/verAplic").text
                    cte.data_recebimento = Time.parse(node.css("protCTe/infProt/dhRecbto").text)
                    cte.protocolo_versao_aplicacao = node.css("protCTe/infProt/verAplic").text
                    cte.numero_protocolo = node.css("protCTe/infProt/nProt").text
                    cte.digest_value = node.css("protCTe/infProt/digVal").text
                    cte.codigo_status_resposta_cte = node.css("protCTe/infProt/cStat").text
                    cte.descricao_motivo_status = node.css("protCTe/infProt/xMotivo").text
                    cte.chave_cte_complementar = node.css("infCteComp/chave").text

                    cte.save
                #else
                    #File.rename("/media/samuel/MULTIBOOT/XmlTomadorServico/23150470037379000190570010000113501010698456-cte.xml", "/media/samuel/MULTIBOOT/XmlTomadorServico/23150470037379000190570010000113501010698456-cte_ok.xml")
                end
            end    
        rescue => e
            return e.message
        end    
    end

    def self.importa_mdfe(path)
        begin
            Dir.glob(path << "/*-mdfe.xml").each do |arquivo|
                xml = Nokogiri::XML(File.open(arquivo))
                node = xml.xpath("//xmlns:mdfeProc")[0]
                chave_mdfe = node.css("protMDFe/infProt/chMDFe").text
                
                mdfe = Mdfe.find_by_chave_mdfe(chave_mdfe)

                unless mdfe.presence
                    mdfe = Mdfe.new
                    mdfe_ctes = []

                    # Dados do MDF-e
                    # ------------------------------------------
                    mdfe.chave_mdfe = chave_mdfe
                    mdfe.codigo_uf = node.css("ide/cUF").text
                    mdfe.tipo_ambiente = node.css("ide/tpAmb").text
                    mdfe.tipo_emitente = node.css("ide/tpEmit").text
                    mdfe.tipo_transportador = node.css("ide/tpTransp").text
                    mdfe.modelo = node.css("ide/mod").text
                    mdfe.serie = node.css("ide/serie").text
                    mdfe.numero_manifesto = node.css("ide/nMDF").text
                    mdfe.codigo_manifesto = node.css("ide/cMDF").text
                    mdfe.codigo_dv = node.css("ide/cDV").text
                    mdfe.modal = node.css("ide/modal").text
                    mdfe.data_hora_emissao = Time.parse(node.css("ide/dhEmi").text)
                    mdfe.tipo_emissao = node.css("ide/tpEmis").text
                    mdfe.processo_emissao = node.css("ide/procEmi").text
                    mdfe.versao_processo_emissao = node.css("ide/verProc").text
                    mdfe.uf_inicio = node.css("ide/UFIni").text
                    mdfe.uf_fim = node.css("ide/UFFim").text
                    mdfe.codigo_municipio_carrega = node.css("ide/infMunCarrega/cMunCarrega").text
                    mdfe.nome_municipio_carrega = node.css("ide/infMunCarrega/xMunCarrega").text

                    # Percurso
                    # ------------------------------------------
                    percursos = ""
                    node.css("ide/infPercurso").each do |percurso|
                        percursos << "-" << percurso.css("UFPer").text
                    end
                    
                    mdfe.percurso = percursos[1..percursos.length]


                    # mdfe.data_hora_inicio_viagem = Time.parse(node.css("ide/dhIniViagem").text)

                    # Dados do Emitente
                    # -----------------------------------------------------------------
                    mdfe.cnpj_emitente = node.css("emit/CNPJ").text
                    mdfe.inscricao_estadual_emitente = node.css("emit/IE").text
                    mdfe.nome_emitente = node.css("emit/xNome").text
                    mdfe.nome_fantasia_emitente = node.css("emit/xFant").text
                    mdfe.logradouro_emitente = node.css("emit/enderEmit/xLgr").text
                    mdfe.numero_endereco_emitente = node.css("emit/enderEmit/nro").text
                    mdfe.complemento_endereco_emitente = node.css("emit/enderEmit/xCpl").text
                    mdfe.bairro_emitente = node.css("emit/enderEmit/xBairro").text
                    mdfe.codigo_municipio_emitente = node.css("emit/enderEmit/cMun").text
                    mdfe.nome_municipio_emitente = node.css("emit/enderEmit/xMun").text
                    mdfe.cep_emitente = node.css("emit/enderEmit/CEP").text
                    mdfe.uf_emitente = node.css("emit/enderEmit/UF").text
                    mdfe.fone_emitente = node.css("emit/enderEmit/fone").text
                    mdfe.email_emitente = node.css("emit/enderEmit/email").text

                    mdfe.versao_modal = node.css("infModal").attribute("versaoModal").text
                    mdfe.rntrc = node.css("infModal/rodo/RNTRC").text
                    mdfe.ciot = node.css("infModal/rodo/CIOT").text

                    mdfe.codigo_interno_veiculo_tracao = node.css("infModal/rodo/veicTracao/cInt").text
                    mdfe.placa_tracao = node.css("infModal/rodo/veicTracao/placa").text
                    mdfe.renavam_tracao = node.css("infModal/rodo/veicTracao/RENAVAM").text
                    mdfe.tara_tracao = node.css("infModal/rodo/veicTracao/tara").text
                    mdfe.capacidade_tracao_kg = node.css("infModal/rodo/veicTracao/capKG").text
                    mdfe.capacidade_tracao_m3 = node.css("infModal/rodo/veicTracao/capM3").text

                    if node.css("infModal/rodo/veicTracao/prop").presence
                        mdfe.proprietario_tracao_cpf = node.css("infModal/rodo/veicTracao/prop/CPF").text
                        mdfe.proprietario_tracao_cnpj = node.css("infModal/rodo/veicTracao/prop/CNPJ").text
                        mdfe.proprietatio_tracao_rntrc = node.css("infModal/rodo/veicTracao/prop/RNTRC").text
                        mdfe.proprietario_tracao_nome = node.css("infModal/rodo/veicTracao/prop/xNome").text
                        mdfe.proprietario_tracao_ie = node.css("infModal/rodo/veicTracao/prop/IE").text
                        mdfe.proprietario_tracao_uf = node.css("infModal/rodo/veicTracao/prop/UF").text
                        mdfe.tipo_proprietario_tracao = node.css("infModal/rodo/veicTracao/prop/tpProp").text
                    end
                    
                    x = 0
                    node.css("infModal/rodo/veicTracao/condutor").each do |condutor|
                        x += 1
                        if x == 1    
                            mdfe.condutor1_tracao_nome = condutor.css("xNome").text
                            mdfe.condutor1_tracao_cpf = condutor.css("CPF").text
                        elsif x == 2 
                            mdfe.condutor2_tracao_nome = condutor.css("xNome").text
                            mdfe.condutor2_tracao_cpf = condutor.css("CPF").text
                        else
                            raise "Migração abrotarda, nota contém mais de um condutor, favor verificar..."
                        end

                    end

                    mdfe.tipo_rodado = node.css("infModal/rodo/veicTracao/tpRod").text
                    mdfe.tipo_carroceria_tracao = node.css("infModal/rodo/veicTracao/tpCar").text
                    mdfe.veliculo_tracao_licenciado_uf = node.css("infModal/rodo/veicTracao/UF").text

                    if node.css("infModal/rodo/veicReboque").presence
                        mdfe.codigo_interno_veiculo_reboque = node.css("infModal/rodo/veicReboque/cInt").text
                        mdfe.placa_reboque = node.css("infModal/rodo/veicReboque/placa").text
                        mdfe.renavam_reboque = node.css("infModal/rodo/veicReboque/RENAVAM").text
                        mdfe.tara_reboque = node.css("infModal/rodo/veicReboque/tara").text
                        mdfe.capacidade_reboque_kg = node.css("infModal/rodo/veicReboque/capKG").text
                        mdfe.capacidade_reboque_m3 = node.css("infModal/rodo/veicReboque/capM3").text

                        if node.css("infModal/rodo/veicReboque/prop").presence
                            mdfe.proprietario_reboque_cpf = node.css("infModal/rodo/veicReboque/prop/CPF").text
                            mdfe.proprietario_reboque_cnpj = node.css("infModal/rodo/veicReboque/prop/CNPJ").text
                            mdfe.proprietatio_reboque_rntrc = node.css("infModal/rodo/veicReboque/prop/RNTRC").text
                            mdfe.proprietario_reboque_nome = node.css("infModal/rodo/veicReboque/prop/xNome").text
                            mdfe.proprietario_reboque_ie = node.css("infModal/rodo/veicReboque/prop/IE").text
                            mdfe.proprietario_reboque_uf = node.css("infModal/rodo/veicReboque/prop/UF").text
                            mdfe.tipo_proprietario_reboque = node.css("infModal/rodo/veicReboque/prop/tpProp").text
                        end

                        mdfe.tipo_carroceria_reboque = node.css("infModal/rodo/veicReboque/tpCar").text
                        mdfe.veliculo_reboque_licenciado_uf = node.css("infModal/rodo/veicReboque/UF").text
                    end
                            
                    mdfe.codigo_municipio_descarga = node.css("infDoc/infMunDescarga/cMunDescarga").text
                    mdfe.nome_municipio_descarga = node.css("infDoc/infMunDescarga/xMunDescarga").text
                        
                    # CTe's
                    # -------------------------------------------------------
                    node.css("infDoc/infMunDescarga/infCTe").each do |cte|
                        ctes = Hash.new
                        ctes[:chave_cte] = cte.css("chCTe").text
                        mdfe_ctes.push(ctes)
                    end
                    
                    mdfe.mdfe_ctes.build(mdfe_ctes)

                    mdfe.quantidade_total_cte = node.css("tot/qCTe").text
                    mdfe.quantidade_total_nfe = node.css("tot/qNFe").text
                    mdfe.valor_total_carga = node.css("tot/vCarga").text
                    mdfe.unidade_peso_bruto_carga = node.css("tot/cUnid").text
                    mdfe.peso_bruto_carga = node.css("tot/qCarga").text

                    mdfe.informacoes_adcionais_fisco = node.css("infAdic/infAdFisco").text.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ' '})
                    mdfe.informacoes_complementares = node.css("infAdic/infCpl").text.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ' '})

                    mdfe.save

                end
            end    
        rescue => e
            return e.message
        end    
    end

end