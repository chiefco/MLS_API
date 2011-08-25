class V1::AttachmentsController < ApplicationController
  
  before_filter :authenticate_request!
  # GET /v1/attachments
  # GET /v1/attachments.xml
    def index
    @attachments = Attachment.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @attachments }
    end
  end

  # GET /v1/attachments/1
  # GET /v1/attachments/1.xml
  def show
    @attachment = Attachment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @attachment }
    end
  end

  # POST /v1/attachments
  # POST /v1/attachments.xml
  def create
    if params[:attachable_id] || params[:attachable_type]
      @attachment = Attachment.new(:file=>params[:file], :file_name=>params[:file].original_filename, :file_type=>params[:file].content_type, :size=>params[:file].size, :attachable_id=>params[:attachable_id], :attachable_type=> params[:attachable_type].camelcase )
    else
      @attachment = @current_user.attachments.new(:file=>params[:file], :file_name=>params[:file].original_filename, :file_type=>params[:file].content_type, :size=>params[:file].size )
    end 
    fields = [:_id,:attachable_type,:attachable_id, :file_type, :file_name, :height, :width, :size, :created_at]
    rename_options = {:_id=>:id}
    
    respond_to do |format|
      if @attachment.save
        format.json  { render :json=> object_to_hash(@attachment,fields,rename_options)}
        format.xml  { render :xml => @attachment.to_xml(:except=>[:_type, :updated_at, :file]) }
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
    @attachment = Attachment.find(params[:id])
    @attachment.destroy

    respond_to do |format|
      format.html { redirect_to(attachments_url) }
      format.xml  { head :ok }
    end
  end
end
