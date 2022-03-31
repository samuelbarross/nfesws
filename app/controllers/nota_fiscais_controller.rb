class NotaFiscaisController < ApplicationController
  before_action :set_nota_fiscal, only: [:show, :edit, :update, :destroy ]
  before_action :authenticate_user!

  # GET /nota_fiscais
  # GET /nota_fiscais.json
  def index
    # Cnpjs que usuário tem a acesso
    @cnpjs = Empresa.joins(:usuario_empresas).where(usuario_empresas: { user: current_user })

    @search = NotaFiscal.where(cpfCnpjDestinatario: @cnpjs.pluck(:cnpj)).search(params[:q])

    if params[:q].nil?
      @nota_fiscais = NotaFiscal.where(cpfCnpjDestinatario: @cnpjs.pluck(:cnpj)).where('datediff(Now(), dtEmissaoNfe) <= 60').order('cpfCnpjDestinatario, dtEmissaoNfe desc')
     else
      @nota_fiscais = @search.result
    end

    @search.build_condition if @search.conditions.empty?
    @search.build_sort if @search.sorts.empty?
    authorize @nota_fiscais
  end

  def citacoes
    # Cnpjs que usuário tem a acesso
    @cnpjs = Empresa.joins(:usuario_empresas).where(usuario_empresas: { user: current_user })

    @search = NotaFiscal.where(cnpj_transportador: @cnpjs.pluck(:cnpj), empresa_id: nil).search(params[:q])

    if params[:q].nil?
      @nota_fiscais = NotaFiscal.select(:id, :nrChaveNfe, :nomeEmitente, :cnpj_transportador, :valorTotalNfe, :dtEmissaoNfe, :created_at).where(cnpj_transportador: @cnpjs.pluck(:cnpj), empresa_id: nil).where('datediff(Now(), dtEmissaoNfe) <= 60').order('cnpj_transportador, created_at desc')
     else
      @nota_fiscais = @search.result
    end

    @search.build_condition if @search.conditions.empty?
    @search.build_sort if @search.sorts.empty?
    authorize @nota_fiscais
  end

  def download_nfe_terceiro
    _size = 44
    _string = params[:chave_nfe].delete(' ')
    _arr = (0..(_string.length-1)/_size).map{|i|_string[i*_size,_size]}
    _done = :error
    _msg = []

    _arr.each do |chave|
      _msg = Nfe.nfe_download_nf_terceiro(chave, params[:emp_id], current_user.id)
      _done = _msg[1].eql?('138') ? :success : :error
      break if _done == :error
    end

    respond_to do |format|
      if _done == :success
          format.html { redirect_to citacoes_nota_fiscais_path, notice: _msg[0] }
      else
          format.html { redirect_to citacoes_nota_fiscais_path, flash: { error: "#{_msg[0]}, chave: #{_msg.last}" } }
      end
    end
  end

  def importar_nfe_xml
    nota_fiscal, msg, salvo = Nfe.importar_xml(params[:nfe_xml].tempfile, current_user.id)

    respond_to do |format|
      if salvo == :success
        format.html { redirect_to nota_fiscais_path(chave_nfe: nota_fiscal.nrChaveNfe), notice: msg }
      else
        format.html { redirect_to nota_fiscais_path(chave_nfe: nota_fiscal.try(:nrChaveNfe)), flash: { error: msg } }
      end
    end
  end

  def manifestacao_destinatario
    @nota_fiscal = NotaFiscal.find(params[:id])
    @mensagem = Nfe.recepcao_evento(@nota_fiscal.id, params[:tpEvento], current_user.id, nil)
    @nota_fiscal.reload
    respond_to do |format|
      format.js
    end
  end

  def download_xml_nfe_sefaz
    @danfe = params[:danfe] == "true"
    @nfe = NotaFiscal.find(params[:id])
     if @nfe.danfe.blank?
      msg = Nfe.nfe_download_nf(@nfe.id, current_user.id)
      @mensagem = msg[0]
      if msg[1] == "138"
        @download = true
        @tipo_mensagem = "success"
      else
        @download = false
        @tipo_mensagem = "error"
      end
    else
      @download = true
     end

    respond_to do |format|
      format.js
    end
  end

  def download_xml_nfe
    nfe = NotaFiscal.find(params[:id])
    send_data nfe.danfe, disposition: 'attachment', filename: "#{nfe.nrChaveNfe}.xml"
  end

  def download_danfe_nfe
    nfe = NotaFiscal.find(params[:id])
    danfe = RubyDanfe.generatePDF("#{nfe.danfe}")
    send_data danfe.render, filename: "#{nfe.nrChaveNfe}.pdf", type: "application/pdf", disposition: 'inline'
  end

  # Realiza a manifestação como desconhecida ou operação não realizada.
  def negar_nfe
    flash[:success] = Nfe.recepcao_evento(params[:id], params[:tpEvento], current_user.id, params[:justificativa])
    respond_to do |format|
      format.html { redirect_to nota_fiscal_path(id: params[:id]) }
    end
  end

  # def consultarNfe
  #   raise params[:id].inspect
  # end

  def report_notas_fiscais
    cnpjs = Empresa.where(id: UsuarioEmpresa.includes(:empresa).where(user_id: current_user.id).map{|f| "#{f.empresa_id}"}).map{|f| "#{f.cnpj}"}

    # Trazendo somente no periodo de 60 dias
    nota_fiscais = NotaFiscal.where(cpfCnpjDestinatario: cnpjs).where("datediff(Now(), dtEmissaoNfe) <= 60").order("cpfCnpjDestinatario, dtEmissaoNfe DESC")

    # No search tem que pesquisar em todos
    busca_nota_fiscais = NotaFiscal.where(cpfCnpjDestinatario: cnpjs).order("cpfCnpjDestinatario, dtEmissaoNfe DESC") if params[:q]

    @search = params[:q].presence ? busca_nota_fiscais.search(params[:q]) : nota_fiscais.search(params[:q])

    if params[:q].nil?
      @nota_fiscais = nota_fiscais
     else
      @nota_fiscais = @search.result
    end

    respond_to do |format|
      format.pdf {
        render pdf: "Relatório de Notas Fiscais",
        :show_as_html => false,
        :page_size => "A4",
        :orientation => "Landscape",
        :disposition => "inline", #{}"attachmentinline",
        :template => "reports/notas_fiscais.pdf.erb",
        :margin => {:top => 30, :bottom => 30},
        header: { html: { template: 'reports/templates/header.pdf.erb'}, :spacing => 5},
        footer: { html: { template: 'reports/templates/footer.pdf.erb'}}
      }
    end
  end

  # GET /nota_fiscais/1
  # GET /nota_fiscais/1.jsond
  def show
    @nota_produtos = NotaProduto.where("notaFiscal_id = " + params[:id].to_s)
    @nota_duplicatas = NotaDuplicata.where("notaFiscal_id = " + params[:id].to_s)
    @logs = Log.where("nota_fiscal_id = " + params[:id].to_s)
  end

  # GET /nota_fiscais/new
  def new
    @nota_fiscal = NotaFiscal.new
  end

  # GET /nota_fiscais/1/edit
  def edit
  end

  # POST /nota_fiscais
  # POST /nota_fiscais.json
  def create
    @nota_fiscal = NotaFiscal.new(nota_fiscal_params)

    respond_to do |format|
      if @nota_fiscal.save
        format.html { redirect_to @nota_fiscal, notice: 'Nota fiscal was successfully created.' }
        format.json { render action: 'show', status: :created, location: @nota_fiscal }
      else
        format.html { render action: 'new' }
        format.json { render json: @nota_fiscal.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /nota_fiscais/1
  # PATCH/PUT /nota_fiscais/1.json
  def update
    respond_to do |format|
      if @nota_fiscal.update(nota_fiscal_params)
        format.html { redirect_to @nota_fiscal, notice: 'Nota fiscal was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @nota_fiscal.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /nota_fiscais/1
  # DELETE /nota_fiscais/1.json
  def destroy
    @nota_fiscal.destroy
    respond_to do |format|
      format.html { redirect_to nota_fiscais_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_nota_fiscal
      @nota_fiscal = NotaFiscal.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def nota_fiscal_params
      params.require(:nota_fiscal).permit(:nrChaveNfe, :nrNfe, :codModeloNfe, :serieNfe, :dtEmissaoNfe, :dtSaidaEntradaNfe, :valorTotalNfe, :nomeEmitente, :nomeFantasiaEmitente, :cpfCnpjEmitente, :logradouroEmitente, :nrEnderecoEmitente, :complementoEnderecoEmitente, :bairroEmitente, :cepEmitente, :codMunicipioEmitente, :telefoneEmitente, :ufEmitente, :codPaisEmitente, :inscricaoEstadualEmitente, :inscricaoEstadualSubsTribEmitente, :inscricaoMunicipalEmitente, :codMunicipioFatorGeradorICMSEmitente,
                                          :cnaeFiscalEmitente, :crtEmitente, :nomeDestinatario, :cpfCnpjDestinatario, :logradouroDestinatario, :nrEnderecoDestinatario, :bairroDestinatario, :cepDestinatario, :codMunicipioDestinatario, :telefoneDestinatario, :ufDestinatario, :codPaisDestinatario, :indicadorIEDestinatario, :inscricaoEstadualDestinatario, :inscricaoSuframa, :inscricaoMunicipalTomadorServico, :emailDestinatario, :codDestinoOperacaoDestinatario, :codConsumidorFinal, :codPresencaComprador, :codProcessoEmissao, :versaoProcesso, :tipoEmissao, :codFinalidadeEmissao, :naturezaOperacao,
                                          :tipOperacao, :codFormaPagamento, :nrProtocoloNfe, :dtRecebimentoNfe, :valorBaseCalculoICMS, :valorICMS, :valorICMSDesonerado, :valorBaseCalculoICMSST, :valorICMSSubstituicao, :valorTotalProduto, :valorFrete, :valorSeguro, :valorOutrasDespesasAcessorias, :valorTotalIPI, :valorTotalDesconto, :valorTotalII, :valorPIS, :valorCOFINS, :valorAproximadoTributos, :modalidadeFrete, :informacoesComplementaresNfe)
    end
end
