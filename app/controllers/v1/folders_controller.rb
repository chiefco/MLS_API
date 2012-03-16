class V1::FoldersController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_folder,:only=>[:update,:show,:destroy, :move_folders]
  #~ before_filter :add_pagination,:only=>[:index]
  def index
    if params[:community_id]
      community = Community.where(:_id => params[:community_id]).first
      respond_to do |format|
        if community
          format.json {render :json =>  {:folders => community.folders.to_json(:only => [:_id, :name, :parent_id, :created_at, :updated_at],:methods => [:user_name]).parse}}
        else
          format.json {render :json => failure.merge({:message => "Community doesn't exist"})}        
        end        
      end      
    else
      folder = @current_user.folders.undeleted
      respond_to do |format|
        format.json {render :json =>  {:folders => folder.to_json(:only => [:_id, :name, :parent_id, :created_at, :updated_at],:methods => [:user_name]).parse}}
      end
    end
  end

  def show
   sub_folders
   @folder_attachments = @folder.attachments.where(:is_deleted => false, :is_current_version => true).order_by(:created_at.desc).entries
    respond_to do |format|
      format.json  { render :json => { :sub_folders=>@sub_folders.to_json(:only=>[:_id, :name, :parent_id, :created_at, :updated_at], :methods => [:children_count, :user_name]).parse,:parent_folder => @folder.to_json(:only=>[:name,:_id, :parent_id]).parse, :folder_attachments => @folder_attachments.to_json(:only =>[:_id, :file_name, :file_type, :size, :content_type,:file,:created_at,:user_id], :methods =>[:user_name,  :has_revision?]).parse}.to_success }
      format.xml  { render :xml =>  @sub_folders.to_xml(:only=>[:_id, :name, :parent_id]).as_hash.merge( :count=> @sub_folders.count).to_success.to_xml(ROOT) }
    end
  end

  def create
    check_folder_uniqueness
    if @folder.nil?
       @folder = @current_user.folders.new(params[:folder])
      respond_to do |format|
        if @folder.save          
          create_share if params[:community] !='' && params.has_key?(:community) && params[:folder][:parent_id] == ''
          format.json  { render :json =>{:folder=>@folder.serializable_hash(:only=>[:_id, :name, :parent_id, :created_at, :updated_at]), :shared_id => (@v1_share.nil? ? 'nil' : @v1_share._id)}.to_success }
        else
          format.json {render :json => @folder.all_errors}
        end
       end
    else
      respond_to do |format|
        format.json {render :json => failure.merge({:message => 'Folder name already exists'})}
      end
    end
  end


  def update
    respond_to do |format|
      unless @folder.status==false
        if @folder
          if @folder.update_attributes(params[:folder])
            @folder={:folder=>@folder.serializable_hash(:only=>[:name,:status,:_id]) }.to_success
            format.xml  { render :xml => @folder.to_xml(ROOT)}
            format.json  { render :json => @folder}
          else
            format.xml  { render :xml => failure.merge(@folder.all_errors).to_xml(ROOT)}
            format.json  { render :json => @folder.all_errors }
          end
        else
          format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
          format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  def destroy
    @activity = Activity.where(:shared_id => params[:id])
    @activity.destroy_all if @activity
    @folder = @folder.destroy
    respond_to do |format|
      if  @folder 
        format.json { render :json=> success }
        format.xml { render :xml=> success.to_xml(ROOT) }
      else
         format.xml  { render :xml => failure.merge(@folder.all_errors).to_xml(ROOT)}
         format.json  { render :json => @folder.all_errors }
      end
    end
  end

  def folder_tree
   @folder = @current_user.folders.select{|f| f['parent_id']==nil && f[:is_deleted]== false && f[:status] == true}
    respond_to do |format|
      format.json {render :json =>  {:folders => @folder.to_json(:only => [:_id, :name, :parent_id, :created_at, :updated_at], :methods => [:children_count]).parse}}
   end
  end

  def move_attachments
   params[:id] = nil if params[:id] == ''
   @attachment = Attachment.find(params[:attachment_id])
   @attachment.update_attributes(:folder_id=>params[:id]) if @attachment
    respond_to do |format|
        if  @attachment
          format.json  { render :json => success }
        else
          format.json {render :json => failure  }
        end
    end
  end

  def move_multiple_attachments
    params[:id] = nil if params[:id] == ''
    files_move_to_folder if  params[:move_files]
    folders_move_to_folder if  params[:move_folders]
    respond_to do |format|
        if  @attachment ||  @folder
          format.json  { render :json => success }
        else
          format.json {render :json => failure  }
        end
    end
  end

  def move_folders
   params[:folder_id] = nil if params[:folder_id] == ''
  @folder.update_attributes(:parent_id=>params[:folder_id])
    respond_to do |format|
        if  @folder
          format.json  { render :json => success }
        else
          format.json {render :json => failure  }
        end
    end
  end
  

  private

  def find_folder
    @folder = Folder.find(params[:id])
  end

  def sub_folders
    @sub_folders = @folder.children.select{|f| f[:is_deleted]== false}
  end
  
   def files_move_to_folder
      params[:move_files].each do |v|
        attachment = Attachment.find(v)
        @attachment = attachment.update_attributes(:folder_id=>params[:id]) if attachment
      end
  end
  
  def folders_move_to_folder
      params[:move_folders].each do |v|
        unless params[:id] == v
          folder = Folder.find(v)
          @folder = folder.update_attributes(:parent_id=>params[:id]) if folder
        end
      end
  end

  def check_folder_uniqueness
    params[:folder][:parent_id].blank? ? @folder = @current_user.folders.where(:name =>params[:folder][:name], :parent_id => nil).first : @folder = @current_user.folders.where(:name =>params[:folder][:name], :parent_id => params[:folder][:parent_id]).first
  end
  
  def create_share
      @v1_share = @current_user.shares.create(:user_id => @current_user._id, :shared_id => @folder._id, :community_id => params[:community], :shared_type=> "Folder", :attachment_id =>nil, :item_id => nil, :folder_id => @folder._id)
      @v1_share.save
      @v1_share.create_activity("SHARE_FOLDER", params[:community], @folder._id)
  end
end
