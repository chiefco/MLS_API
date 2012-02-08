class V1::FoldersController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_folder,:only=>[:update,:show,:destroy, :move_folders]
  #~ before_filter :add_pagination,:only=>[:index]
  def index
    @folder = @current_user.folders.undeleted
    respond_to do |format|
      format.json {render :json =>  {:folders => @folder.to_json(:only => [:_id, :name, :parent_id, :created_at, :updated_at]).parse}} 
    end
  end

  def show
    sub_folders
    @folder_attachments = @folder.attachments.entries
    respond_to do |format|
      format.json  { render :json => { :sub_folders=>@sub_folders.to_json(:only=>[:_id, :name, :parent_id], :methods => [:children_count]).parse,:parent_folder => @folder.to_json(:only=>[:name,:_id, :parent_id]).parse, :folder_attachments => @folder_attachments.to_json(:only =>[:_id, :file_name, :file_type, :size, :content_type,:file,:created_at,:user_id]).parse}.to_success }
      format.xml  { render :xml =>  @sub_folders.to_xml(:only=>[:_id, :name, :parent_id]).as_hash.merge( :count=> @sub_folders.count).to_success.to_xml(ROOT) }
    end
  end

  def create
      @folder = @current_user.folders.new(params[:folder])
      respond_to do |format|
        if @folder.save
          format.json  { render :json =>{:folder=>@folder.to_json(:only=>[:_id]).parse}.to_success }
        else
          format.json {render :json => @folder.all_errors}
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
     respond_to do |format|
      if @folder
         @folder.update_attributes(:status=>false)
         format.xml  { render :xml => success.to_xml(ROOT) }
         format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
   def folder_tree
     @folder = @current_user.folders.select{|f| f['parent_id']==nil && f['status']== true}
      respond_to do |format|
        format.json {render :json =>  {:folders => @folder.to_json(:only => [:_id, :name, :parent_id, :created_at, :updated_at], :methods => [:children_count]).parse}} 
      end
    end
    
  def move_attachments
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
    params[:move_file].each do |key, value|
      @attachment = Attachment.find(value[:item][:attachment_id])
      @attachment.update_attributes(:folder_id=>params[:id]) if @attachment
    end
    respond_to do |format|
        if  @attachment
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
    @sub_folders = @folder.children
  end

end
