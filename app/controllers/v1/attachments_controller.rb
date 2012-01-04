class V1::AttachmentsController < ApplicationController

  before_filter :authenticate_request!
  before_filter :find_resource, :except=>[:create, :index]
  before_filter :detect_missing_file, :only=>[:create]
  before_filter :set_attachment_options, :only=>[:create]
  # GET /v1/attachments
  # GET /v1/attachments.xml
  def index
    paginate_options = {}
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    @attachments = Attachment.list(@current_user.attachments,params,paginate_options)

    respond_to do |format|
      format.json  { render :json => { :attachments=>@attachments.to_json(:only=>[:_id, :file_name, :file_type, :size, :content_type,:file,:created_at]).parse }.to_success }
      format.xml  { render :xml => @attachments.to_xml(:only=>[:_id, :file_type, :file_name, :size,  :content_type]).as_hash.to_success.to_xml(ROOT) }
    end
  end

  # GET /v1/attachments/1
  # GET /v1/attachments/1.xml
  def show
    respond_to do |format|
      format.json  { render :json => { :attachment=>@attachment.to_json(:only=>[:_id, :file_type, :file_name, :size,  :content_type, :file]).parse }.to_success }
      format.xml  { render :xml => @attachment.to_xml(:only=>[:_id, :file_type, :file_name, :size,  :content_type]).as_hash.to_success.to_xml(ROOT) }
    end
  end

  # POST /v1/attachments
  # POST /v1/attachments.xml
 def create
    File.open("#{Rails.root}/public/images/#{params[:attachment][:file_name]}", 'wb') do|f|
      f.write(Base64.decode64("#{params[:encoded]}"))
    end    
    params[:attachment][:file] = File.new("#{Rails.root}/public/images/#{params[:attachment][:file_name]}")
    @attachment = @current_user.attachments.new(params[:attachment])
    @attachment.save
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
    @attachment.destroy
    respond_to do |format|
      format.json { render :json=> success }
      format.xml { render :xml=> success.to_xml(ROOT) }
    end
  end

  private

  def find_resource
    @attachment = Attachment.find(params[:id])
  end

  def detect_missing_file
    file_missing = true
    file_missing = false if params.has_key?(:attachment) && params[:attachment].is_a?(Hash) && params[:attachment].has_key?("file")
    if file_missing
      respond_to do |format|
        format.json { render :json=> {:error=>{:code=>6001, :message=>"The file was not correctly uploaded"}}.to_failure }
        format.xml { render :xml=> {:error=>{:code=>6001, :message=>"The file was not correctly uploaded"}}.to_failure.to_xml(ROOT) }
      end
    end
  end

end
