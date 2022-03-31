class CronsController < ApplicationController
    before_action :set_Cron, only: [:show, :edit, :update, :destroy]
    respond_to :html, :xml, :js
    before_action :authenticate_user!

    def index

        cnpjs = Empresa.where(id: UsuarioEmpresa.includes(:empresa).where(user_id: current_user.id).map{|f| "#{f.empresa_id}"}).map{|f| "#{f.cnpj}"}
        crons = Cron.where(cnpj: cnpjs).order("cnpj, data DESC")    

        @search = crons.search(params[:q])

        if params[:q].nil?
            @crons = crons
        else
            @crons = @search.result
        end

        @search.build_condition if @search.conditions.empty?
        @search.build_sort if @search.sorts.empty?


        # if not params[:Filtro].nil?
        #     if not params[:Filtro][:id].nil? and params[:Filtro][:id] != ""
        #         q = SystemControllerQuery.find(params[:Filtro][:id])
        #         @crons = @crons.where(q.query)
        #     end
        # end

        # respond_to do |format|
        #     format.html
        #     format.pdf {render pdf: "Relatório de Cron",
        #         orientation: "Portrait",
        #         :disposition => "inline",
        #         :template => "crons/index.pdf.erb",
        #         :margin => { :top => 15, :bottom => 15},
        #         header: {:spacing => 3, html: {template: 'crons/header.pdf.erb'}, :margin => { top: 0, :bottom => 3}},
        #         footer: {:spacing => 1,html: {template: 'crons/footer.pdf.erb'},:margin => {:top => 3,:bottom => 1}}
        #     }
        # end
    end

    def download_xml_retorno
        xml = Cron.find(params[:id])
        send_data xml.xml_retorno, disposition: 'attachment', filename: "#{xml.data.strftime("%d/%m/%Y")}_#{xml.nome_completo_empresa}.xml"
    end

    def show
        @cron = Cron.find(params[:id])
        respond_with  @cron
    end

    def new
        if params[:id]
            @cron =  Cron.find(params[:id]).dup
        else
            @cron =  Cron.new
        end
    end

    def edit
        @cron = Cron.find(params[:id])
    end

    def create
        @Cron = Cron.new(Cron_params)
        respond_to do |format|
            if @Cron.save
                format.html { redirect_to @Cron, notice: 'Cron foi criado(a) com sucesso.' }
                format.json { render action: 'show', status: :created, location: @Cron }
            else
                format.html { render action: 'new' }
                format.json { render json: @Cron.errors, status: :unprocessable_entity }
            end
        end
    end

    def update
        respond_to do |format|
            if @Cron.update(Cron_params)
                format.html { redirect_to @Cron, notice: 'Cron foi atualizado(a) com sucesso.' }
                format.json { head :no_content }
            else
                format.html { render action: 'edit' }
                format.json { render json: @Cron.errors, status: :unprocessable_entity }
            end
        end
    end

    def destroy
        @Cron.destroy
        redirect_to crons_url, notice: 'Cron foi apagado(a) com sucesso.'
    end

    private
    def set_Cron
        @Cron = Cron.find(params[:id])
    end

    def Cron_params
        params.require(:Cron).permit(:data, :cnpj, :xml_retorno, :mensagem)
    end
end
