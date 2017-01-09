class Admin::Cycles::PluginRelations::PetitionsController < Admin::ApplicationController
  def index
    @petition = @plugin_relation.petition_detail
  end

  def new
    @petition = PetitionPlugin::Detail.new
  end

  def edit
    @petition = @plugin_relation.petition_detail
  end

  def update
    @petition = @plugin_relation.petition_detail
    @petition.update_attributes petition_params

    current_version = @petition.current_version
    if current_version.nil? || current_version.body != petition_versionable_params[:body]
      @petition.petition_detail_versions << PetitionPlugin::DetailVersion.new(petition_versionable_params)

    end

    if @petition.save
      enqueue_pdf_generation
      flash[:success] = "Petição salva com sucesso."
      redirect_to [:admin, @cycle, @plugin_relation, :petitions]
    else
      flash[:error] = "Ocorreu algum erro ao atualizar a petição."
      render :edit
    end
  end

  def create
    if @plugin_relation.petition_detail
      flash[:error] = "Esta petição já foi salva por outra pessoa, tente novamente clicando em Editar Petição"
      return redirect_to [:admin, @cycle, @plugin_relation, :petitions]
    end

    @petition = PetitionPlugin::Detail.new(plugin_relation_id: @plugin_relation.id)
    @petition.update_attributes petition_params

    @petition.petition_detail_versions << PetitionPlugin::DetailVersion.new(petition_versionable_params)

    if @petition.save
      enqueue_pdf_generation
      flash[:success] = "Petição salva com sucesso."
      redirect_to [:admin, @cycle, @plugin_relation, :petitions]
    else
      flash[:error] = "Ocorreu algum erro ao criar a petição."
      render :new
    end
  end

  private

  def petition_params
    params.require(:petition_plugin_detail)
      .permit(:call_to_action, :signatures_required, :presentation)
  end

  def petition_versionable_params
    params.require(:petition_plugin_detail).require(:current_version)
      .permit(:document_url, :body)
  end

  def enqueue_pdf_generation
    version = @petition.petition_detail_versions.where(published: false).first
    PetitionPdfGenerationWorker.perform_async id: version.id
  end
end
