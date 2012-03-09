class V1::AttachmentsController < ApplicationController

  before_filter :authenticate_request!
  before_filter :find_resource, :except=>[:create, :index, :attachments_multiple_delete, :get_revisions]
  before_filter :detect_missing_file, :only=>[:create]

  # GET /v1/attachments
  # GET /v1/attachments.xml
  def index
    paginate_options = {}
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    @attachments = Attachment.list(@current_user.attachments,params,paginate_options)
    size = @current_user.attachments.where(:is_deleted => false).sum(:size)
    percentage = (((@current_user.attachments.where(:is_deleted => false).sum(:size).to_i) * 100)/1073741824).round(1) rescue nil
    params[:user_attachments] ? @count = @current_user.attachments.where(:folder_id => nil, :is_deleted => false).reject{|attachment| attachment.shares.count > 0}.count : @count = @current_user.attachments.where(:folder_id => nil, :is_deleted => false).count


    respond_to do |format|
      format.json  { render :json => { :attachments=>@attachments.to_json(:only=>[:_id, :file_name, :file_type, :size, :user_id, :content_type,:file,:created_at], :methods => [:user_name, :has_revision?]).parse ,:total=>@count, :size => size, :percentage => percentage}.to_success }
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
    !params[:community].blank? ? community_id = params[:community] : community_id = nil
    attachments_present = Attachment.where(:file_name => "#{params[:attachment][:file_name]}", :attachable_id => @current_user.id, :folder_id => params[:attachment][:folder_id], :community_id => community_id)
    attachment_present = attachments_present.where(:file_name => "#{params[:attachment][:file_name]}", :attachable_id => @current_user.id, :is_current_version => true, :is_deleted => false).first
    parent_file = attachments_present.where(:parent_id => nil).first
    attachment_present.update_attributes(:is_current_version => false) if attachment_present
    File.open("#{Rails.root}/tmp/#{params[:attachment][:file_name]}", 'wb') do|f|
      f.write(Base64.decode64("#{params[:encoded]}"))
    end

    params[:attachment][:attachable_id] =@current_user._id if params[:attachment][:attachable_type] == "User"
    params[:attachment][:file] = File.new("#{Rails.root}/tmp/#{params[:attachment][:file_name]}")
    params[:attachment][:size] = params[:attachment][:file].size
    params[:attachment][:changed_by] = @current_user._id
    params[:attachment][:parent_id] = parent_file._id if attachments_present.size > 0
    attachments_present.size > 0 ? event = "Updated" : event = "Added"

    folder = Folder.find(params[:attachment][:folder_id]) if params[:attachment][:folder_id]
    params[:attachment][:folder_id] = folder._id if folder
    @attachment = @current_user.attachments.new(params[:attachment])
    @attachment.save
    File.delete(params[:attachment][:file])
    Share.update(attachment_present._id, @attachment._id, @current_user._id) if attachment_present

    respond_to do |format|
      if @attachment.save
        @attachment.update_activity if event == "Updated"
        parent_file ? parent_file.revisions.create(:version => attachments_present.size + 1, :event => event, :changed_by => @current_user._id, :size => @attachment.size, :versioned_attachment => @attachment._id) : @attachment.revisions.create(:version => attachments_present.size + 1, :event => event, :changed_by => @current_user._id, :size => @attachment.size, :versioned_attachment => @attachment._id)
        @attachment.update_attributes(:attachment_type => "COMMUNITY_ATTACHMENT", :community_id => params[:community]) if params[:community]!='' && params.has_key?(:community)
        format.json  { render :json=> { :attachment=>@attachment.to_json(:only=>[:_id,:attachable_type,:attachable_id, :file_type, :file_name, :height, :width, :size, :created_at]).parse}.to_success }
        format.xml  { render :xml => @attachment.to_xml(:only=>[:_id,:attachable_type,:attachable_id, :file_type, :file_name, :height, :width, :size, :created_at]).as_hash.to_success.to_xml(ROOT) }
      else
        format.json  { render :json => failure.merge(:errors=> @attachment.all_errors)}
        format.xml  { render :xml => @attachment.all_errors, :root=>"errors" }
      end
    end
  end

  def update
    if @attachment
      if params[:encoded]
        File.open("#{Rails.root}/tmp/#{@attachment.file_name}", 'wb') do|f|
          f.write(Base64.decode64("#{params[:encoded]}"))
        end    
        params[:attachment] && params[:attachment][:file_name] ? file_name = params[:attachment][:file_name] : file_name = @attachment.file_name
        params[:attachment] && params[:attachment][:file_type] ? file_type = params[:attachment][:file_type] : file_type = @attachment.file_type
        params[:attachment] && params[:attachment][:content_type] ? content_type = params[:attachment][:content_type] : content_type = @attachment.content_type
        @attachment.parent ? parent = @attachment.parent : parent = @attachment
        version = parent.children.size + 2            
        folder = Folder.find(params[:attachment][:folder_id]) if params[:attachment] && params[:attachment][:folder_id]
        folder ? folder_id = folder._id : folder_id = @attachment.folder_id   
        file = File.new("#{Rails.root}/tmp/#{@attachment.file_name}")

        @new_attachment = @current_user.attachments.new(:attachable_id => @current_user._id, :attachable_type => @attachment.attachable_type, :file_name => file_name, :file_type => file_type, :content_type => content_type, :folder_id => folder_id, :file => file, :size => file.size, :changed_by => @current_user._id, :parent_id => parent._id)

        respond_to do |format|
          if @new_attachment.save
            File.delete(file)
            @attachment.update_attributes(:is_current_version => false)
            Share.update(@attachment._id, @new_attachment._id, @current_user._id)      
            parent.revisions.create(:version => version, :event => "Updated", :changed_by => @current_user._id, :size => @new_attachment.size, :versioned_attachment => @new_attachment._id)
            @attachment.update_activity            
            format.json  { render :json=> { :attachment => @new_attachment.to_json(:only=>[:_id,:attachable_type,:attachable_id, :file_type, :file_name, :height, :width, :size, :created_at]).parse}.to_success }
            format.xml  { render :xml => @new_attachment.to_xml(:only=>[:_id,:attachable_type,:attachable_id, :file_type, :file_name, :height, :width, :size, :created_at]).as_hash.to_success.to_xml(ROOT) }
          else
            format.json  { render :json => failure.merge(:errors=> @new_attachment.all_errors)}
            format.xml  { render :xml => @new_attachment.all_errors, :root=>"errors" }
          end
        end
      else
        respond_to do |format|
          format.json { render :json=> {:error=>{:message => 'File content(encoded) - Blank Parameter'}}.to_failure }
        end   
      end
    else
      respond_to do |format|
        format.json { render :json=> {:error=>{:message=>"File not found"}}.to_failure }
      end 
    end
  end

  # DELETE /v1/attachments/1
  # DELETE /v1/attachments/1.xml
  def destroy
    @activity = Activity.where(:shared_id => params[:id])
    @activity.destroy_all if @activity
    @attachment.destroy

    respond_to do |format|
      format.json { render :json=> success }
      format.xml { render :xml=> success.to_xml(ROOT) }
    end
  end

  def get_revisions
    attachment = Attachment.where(:_id => params[:id]).first
    attachment.parent ? parent_attachment = attachment.parent : parent_attachment = attachment
    attachment_revisions = parent_attachment.revisions

    if !attachment_revisions.blank?
      respond_to do |format|
        format.json  { render :json => { :file_name => attachment.file_name, :attachment_revisions => attachment_revisions.reverse.to_json(:only=>[:_id, :size, :version, :created_at, :event, :attachment_id]).parse}.to_success }
        format.xml  { render :xml => attachment_revisions.to_xml(:only=>[:_id, :file_type, :file_name, :size,  :content_type]).as_hash.to_success.to_xml(ROOT) }
      end      
    end
  end

  def validate_attachment
    attachment = Attachment.where(:file_name => "#{params[:file_name]}", :attachable_id => @current_user.id, :folder_id => params[:folder_id], :is_current_version => true).first

    respond_to do |format|
      if attachment
        format.json  { render :json => { :message=>"The file already exist", :attachment => attachment.to_json(:only=>[:_id, :file_name, :file_type, :size, :user_id, :content_type,:file,:created_at], :methods => [:user_name, :has_revision?]).parse}.to_failure }
        format.xml { render :xml=> failure.to_xml(ROOT) }
      else
        format.json { render :json=> {:success => {:message=>"The file doesn't exist"}}.to_success }
        format.xml { render :xml=> {:message => "The file doesn't exist"}.to_success.to_xml(ROOT) }
      end
    end      
  end  

  def restore_file
    attachment = Attachment.where(:_id => params[:id]).first
    attachment.parent ? parent = attachment.parent : parent = attachment
    children = parent.children
    parent.update_attributes(:is_current_version => false)
    versioned = parent.revisions.where(:version => params[:version]).last
    children.each{|a| a.update_attributes(:is_current_version => false)}
    if params[:version] == 1 
      parent.update_attributes(:is_current_version => true)
      parent.restore_activity 
    else 
      file = Attachment.where(:_id => versioned.versioned_attachment).last
      file.update_attributes(:is_current_version => true)
      file.restore_activity      
    end
    parent.revisions.create(:version => params[:version], :event => "Restored", :changed_by => @current_user._id, :size => versioned.size, :versioned_attachment => versioned.versioned_attachment)    

    respond_to do |format|
      format.json { render :json=> success }
      format.xml { render :xml=> success.to_xml(ROOT) }
    end    
  end

 # DELETE  MULTIPLE/v1/attachments/1
  # DELETE MULTIPLE /v1/attachments/1.xml
 def attachments_multiple_delete
    Attachment.any_in(_id: params[:attachment]).update_all(:is_deleted => true)
    attachments = Attachment.list(@current_user.attachments, params, {:page =>1, :per_page => 10})
    count = @current_user.attachments.where(:folder_id => nil, :is_deleted => false).count
    Folder.any_in(_id: params[:folder]).update_all(:is_deleted => true) if params[:folder] 
    folders = @current_user.folders.where(:parent_id => nil, :is_deleted => false)
    Attachment.delay.delete(params[:attachment])
    Folder.delay.delete(params[:folder]) if params[:folder] 

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
    @attachment = Attachment.find(params[:id]) rescue nil
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
