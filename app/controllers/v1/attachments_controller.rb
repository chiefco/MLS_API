class V1::AttachmentsController < ApplicationController
  
  before_filter :authenticate_request!
  before_filter :find_resource, :except=>[:create, :index]
  # GET /v1/attachments
  # GET /v1/attachments.xml
    def index
    @attachments = @current_user.attachments

    respond_to do |format|
      format.json  { render :json => @attachments }
      format.xml  { render :xml => @attachments }
    end
  end

  # GET /v1/attachments/1
  # GET /v1/attachments/1.xml
  def show

    respond_to do |format|
      if @attachment 
        fields = [:_id, :file_type, :file_name, :size,  :content_type, :file_link]
        rename_options = {:_id=>:id}
        format.json  { render :json => success.merge(:attachment=>object_to_hash(@attachment,fields,rename_options)) }
        format.xml  { render :xml => @attachment.to_xml(:only=>fields) }
      else
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
        format.xml { render :xml=>  failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>"error") } 
      end 
    end
  end

  # POST /v1/attachments
  # POST /v1/attachments.xml
  def create
    file_name,file_type = set_file_name,set_file_type

    if params[:attachable_id] || params[:attachable_type]
      @attachment = Attachment.new(:file=>params[:file], :file_name=>file_name, :file_type=>file_type, :size=>params[:file].size, :attachable_id=>params[:attachable_id], :attachable_type=> params[:attachable_type].camelcase, :content_type=>params[:file].content_type)
    else
      @attachment = @current_user.attachments.new(:file=>params[:file], :file_name=>file_name, :file_type=>file_type, :size=>params[:file].size, :content_type=>params[:file].content_type )
    end 
    
    respond_to do |format|
      if @attachment.save
        fields = [:_id,:attachable_type,:attachable_id, :file_type, :file_name, :height, :width, :size, :created_at]
        rename_options = {:_id=>:id}
        format.json  { render :json=> success.merge(:attachment=>object_to_hash(@attachment,fields,rename_options)) }
        format.xml  { render :xml => @attachment.to_xml(:only=>fields) }
      else
        format.json  { render :json => { "errors"=> @attachment.all_errors}}
        format.xml  { render :xml => @attachment.all_errors, :root=>"errors" }
      end
    end
  end
  

  # PUT /v1/attachments/1
  # PUT /v1/attachments/1.xml
  def update
    @attachment = Attachment.find(params[:id])

    respond_to do |format|
      if @attachment.update_attributes(params[:attachment])
        format.html { redirect_to(@attachment, :notice => 'Attachment was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @attachment.errors, :status => :unprocessable_entity }
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
    @attachment = Attachment.where(:_id=>params[:id]).first
  end 
  
  def set_file_name
    params[:file_name].blank? ? params[:file].original_filename : params[:file_name]
  end 
  
  def set_file_type
     params[:file_type].blank? ? params[:file].content_type.split('/').last : params[:file_type]
  end 
  
end
