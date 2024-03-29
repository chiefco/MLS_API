class V2::SharesController < ApplicationController
  before_filter :authenticate_request!
  # before_filter :find_share,:only=>([:show])
  # GET /v1/shares
  # GET /v1/shares.xml
  def index

  end

  # GET /v1/shares/1
  # GET /v1/shares/1.xml
  def show
    entity = Folder.where(:_id => params[:id]).first
    if entity
      entity_name = entity.name
      entity_type = "Folder"
    else
      entity = Attachment.where(:_id => params[:id]).first
      entity_name = entity.file_name
      entity_type = "File"
    end

    communities = entity.shares.map(&:community).uniq
    respond_to do |format|
      format.json {render :json =>  {:communities => communities.to_json(:methods => [:users_count, :shares_count]).parse, :shared_name => entity_name, :shared_type => entity_type}} # index.html.erb
    end    
  end

  # POST /v1/shares
  # POST /v1/shares.xml
  def create
    shr_files, shr_folders, shr_comm, shr_notes, shr_notes_id = [], [], [], [], []
    params[:share].each do |key, value|
      attachment_id, item_id, folder_id = nil
      shr_comm << value['item']['community_id']
      if value['item']['shared_type'] == "Attachment" 
        attachment = Attachment.find(value['item']['shared_id'])
        attachment_id = value['item']['shared_id']
        shr_files << (attachment).file_name
        #~ attachment.create(value['item']['community_id'], nil, @current_user)
      elsif value['item']['shared_type'] == "Folder" 
        folder_id = value['item']['shared_id']
        folder = Folder.find(folder_id)
        shr_folders << (folder).name
        #~ folder.make_clone(value['item']['community_id'], @current_user) if folder
      else
        item_id = value['item']['shared_id']
        note = Item.find(item_id)
        shr_notes_id << (note)._id
        shr_notes << (note).name
      end
      @v1_share = @current_user.shares.create(:user_id=>@current_user._id,:shared_id=> value['item']['shared_id'], :community_id=> value['item']['community_id'], :shared_type=> value['item']['shared_type'], :attachment_id => attachment_id, :item_id => item_id, :folder_id => folder_id)
    end

    params[:share].each do |key, value|
      @v1_share.create_activity("SHARE_"+value['item']['shared_type'].upcase,value['item']['community_id'],value['item']['shared_id'])
    end
    # To send the emails
    @v1_share.delay.share_files(shr_comm.uniq, shr_files.uniq, shr_folders.uniq,shr_notes.uniq, shr_notes_id, @current_user)

    respond_to do |format|
      format.xml  { render :xml => success.merge(:share=>@v1_share).to_xml(ROOT,:only=>[:name,:_id])}
      format.json  { render :json =>{:share=>@v1_share.to_json(:only=>[:_id]).parse}.to_success }
    end
  end

  # PUT /v1/shares/1
  # PUT /v1/shares/1.xml
  def update

  end

  # DELETE /v1/shares/1
  # DELETE /v1/shares/1.xml
  def destroy
    share = Folder.where(:_id => params[:id]).first
    share = Attachment.where(:_id => params[:id]).first if share.nil?
    item_name = share.name rescue share.file_name
    Share.delay.shared_delete(share.community.id, 0, item_name, @current_user)
    share.destroy

    respond_to do |format|
      format.json {render :json=>success }
    end
  end

  # Public: Delete multiple shares
  def shares_multiple_delete
    folders = Folder.any_in(_id: params[:share_list])
    unless folders.blank?
      folders.community_folders.update_all(:is_deleted => true) 
      Folder.delay.delete(folders.map(&:_id),false)
    end
    attachments = Attachment.any_in(_id: params[:share_list]).map(&:id)
    Share.delay.shared_delete(params[:community_id], params[:share_list].count, "", @current_user)
    Attachment.delay.delete(attachments,false) unless attachments.blank?
    Share.any_in(:shared_id => params[:share_list]).where(:community_id => params[:community_id]).destroy_all
    respond_to do |format|
      format.json {render :json=>success}
    end
  end
  
  # Public: Send notifications while upload file via teams
  def file_notifications
    community_name = Community.find(params[:community_id]).name
    emails = CommunityUser.where(:community_id => params[:community_id], :subscribe_email => true).map(&:user).map(&:email) - [@current_user.email]
    Attachment.delay.upload_share(@current_user.email, @current_user.first_name, params[:community_id], community_name, emails, params[:file_name], params[:file_count]) unless emails.blank?    
     respond_to do |format|
      format.json {render :json=>success }
     end
  end

  private
  
  # Private: To find share
  def find_share
    @share= @current_user.shares.find(params[:id])
  end

  # def create_attachment(attachment_id, community_id, folder_id=nil)
  #   attachment = Attachment.find(attachment_id)

  #   File.open("#{Rails.root}/tmp/#{attachment.file_name}", 'wb') do |fo|
  #     fo.print open("#{attachment.file.to_s}").read
  #   end     
  #   attached_file = File.new("#{Rails.root}/tmp/#{attachment.file_name}")
  #   new_attachment = Attachment.new(:attachable_id => @current_user._id, :file => attached_file, :size => attached_file.size, :community_id => community_id, :attachable_type => 'User', :attachment_type => 'COMMUNITY_ATTACHMENT', :user_id => attachment.user_id, :content_type => attachment.content_type, :file_name => attachment.file_name, :file_type => attachment.file_type, :folder_id => folder_id)
  #   new_attachment.save!
  #   File.delete(attached_file)
  # end
end
