class V1::AttachmentsController < ApplicationController

  before_filter :authenticate_request!
  before_filter :find_resource, :except=>[:create, :index]
  before_filter :detect_missing_params, :set_attachment_options, :only=>[:create]
  # GET /v1/attachments
  # GET /v1/attachments.xml
  def index
    paginate_options = {}
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    @attachments = Attachment.list(@current_user.attachments,params,paginate_options)

    respond_to do |format|
      format.json  { render :json => success.merge(:attachments=>JSON.parse(@attachments.to_json(:only=>[:id, :file_name, :file_type, :size, :content_type, :file_link])))}
      format.xml  { render :xml => @attachments.to_xml(:root=>'attachments', :only=>[:_id, :file_type, :file_name, :size,  :content_type, :file_link]) }
    end
  end

  # GET /v1/attachments/1
  # GET /v1/attachments/1.xml
  def show

    respond_to do |format|
      if @attachment
        format.json  { render :json => success.merge(:attachment=>JSON.parse(@attachment.to_json(:only=>[:_id, :file_type, :file_name, :size,  :content_type, :file_link]))) }
        format.xml  { render :xml => @attachment.to_xml(:only=>[:_id, :file_type, :file_name, :size,  :content_type, :file_link]) }
      else
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
        format.xml { render :xml=>  failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>"error") }
      end
    end
  end

  # POST /v1/attachments
  # POST /v1/attachments.xml
  def create
    if params[:attachment][:attachable_id] || params[:attachment][:attachable_type]
      @attachment = Attachment.new(params[:attachment])
    else
      @attachment = @current_user.attachments.new(params[:attachment])
    end

    respond_to do |format|
      if @attachment.save
        format.json  { render :json=> { :attachment=>@attachment.to_json(:only=>[:_id,:attachable_type,:attachable_id, :file_type, :file_name, :height, :width, :size, :created_at]).parse}.to_success }
        format.xml  { render :xml => @attachment.to_xml(:only=>[:_id,:attachable_type,:attachable_id, :file_type, :file_name, :height, :width, :size, :created_at]).as_hash.to_success.to_xml(ROOT) }
      else
        format.json  { render :json => failure.merge(:errors=> @attachment.all_errors)}
        format.xml  { render :xml => @attachment.all_errors, :root=>"errors" }
      end
    end
  end

  # DELETE /v1/attachments/1
  # DELETE /v1/attachments/1.xml
  def destroy

    respond_to do |format|
      if @attachment
        @attachment.destroy
        format.json { render :json=> success }
        format.xml { render :xml=> success.to_xml(:root=>"result") }
      else
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
        format.xml { render :xml=> failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'error') }
      end
    end
  end

  private

  def find_resource
    @attachment = Attachment.find(params[:id])
  end
  
  def detect_missing_params
    if params.has_key?(:attachment) && !params[:attachment].blank? && !['nil', 'NULL', 'null'].include?(params[:attachment])
      missing_params = [:file]  unless params[:attachment].has_key?("file") 
    else
      missing_params = [:file] 
    end 
    render_missing_params(missing_params) unless missing_params.blank?
  end

end
