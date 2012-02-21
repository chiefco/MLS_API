class V1::AttachmentsController < ApplicationController

  before_filter :authenticate_request!
  before_filter :find_resource, :except=>[:create, :index, :attachments_multiple_delete]
  before_filter :detect_missing_file, :only=>[:create]

  # GET /v1/attachments
  # GET /v1/attachments.xml
  def index
    paginate_options = {}
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    @attachments = Attachment.list(@current_user.attachments,params,paginate_options)
    if params[:user_attachments]
      @attachments = @attachments.reject{|attachment| attachment.shares.count > 0}
      @count = @current_user.attachments.where(:folder_id => nil).reject{|attachment| attachment.shares.count > 0}.count
    else
      @count = @current_user.attachments.where(:folder_id => nil).count
    end
    respond_to do |format|
      format.json  { render :json => { :attachments=>@attachments.to_json(:only=>[:_id, :file_name, :file_type, :size, :user_id, :content_type,:file,:created_at], :methods => [:user_name]).parse ,:total=>@count}.to_success }
      format.xml  { render :xml => @attachments.to_xml(:only=>[:_id, :file_type, :file_name, :size, :user_id,  :content_type],:methods => [:user_name]).as_hash.to_success.to_xml(ROOT) }
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
    File.open("#{Rails.root}/tmp/#{params[:attachment][:file_name]}", 'wb') do|f|
      f.write(Base64.decode64("#{params[:encoded]}"))
    end
    params[:attachment][:attachable_id] =@current_user._id if params[:attachment][:attachable_type] == "User"
    params[:attachment][:file] = File.new("#{Rails.root}/tmp/#{params[:attachment][:file_name]}")
    params[:attachment][:size] = params[:attachment][:file].size
    @attachment = @current_user.attachments.new(params[:attachment])
    @attachment.save
    File.delete(params[:attachment][:file])
    respond_to do |format|
      if @attachment.save
         if params[:community]!='' && params.has_key?(:community)
          @v1_share = @current_user.shares.create(:user_id => @current_user._id, :shared_id => @attachment._id, :community_id => params[:community], :shared_type=> "Attachment", :attachment_id => @attachment._id, :item_id => nil)
          @v1_share.save
          @v1_share.create_activity("SHARE_ATTACHMENT", params[:community], @attachment._id)
        end
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
    @activity = Activity.where(:shared_id => params[:id]).first
    @activity.destroy if @activity
    respond_to do |format|
      format.json { render :json=> success }
      format.xml { render :xml=> success.to_xml(ROOT) }
    end
  end

 # DELETE  MULTIPLE/v1/attachments/1
  # DELETE MULTIPLE /v1/attachments/1.xml
 def attachments_multiple_delete
    Attachment.any_in(_id: params[:attachment]).update_all(:is_deleted => true)
    attachments = Attachment.list(@current_user.attachments.undeleted, params, {:page =>1, :per_page => 10})
    count = @current_user.attachments.where(:folder_id => nil).count
    Attachment.delay.delete(params[:attachment])

    respond_to do |format|
      format.json  { render :json => { :attachments => attachments.to_json(:only=>[:_id, :file_name, :file_type, :size, :content_type,:file,:created_at, :user_id]).parse ,:total => count}.to_success }
      format.xml  { render :xml => @attachments.to_xml(:only=>[:_id, :file_type, :file_name, :size,  :content_type]).as_hash.to_success.to_xml(ROOT) }
    end
  end

  def attachments_download
    @attachment.activities.create(:action=>"ATTACHMENT_DOWNLOADED", :user_id=> @current_user._id)
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
    file_missing = false if params.has_key?(:encoded) && params[:attachment].is_a?(Hash)
    if file_missing
      respond_to do |format|
        format.json { render :json=> {:error=>{:code=>6001, :message=>"The file was not correctly uploaded"}}.to_failure }
        format.xml { render :xml=> {:error=>{:code=>6001, :message=>"The file was not correctly uploaded"}}.to_failure.to_xml(ROOT) }
      end
    end
  end

end
