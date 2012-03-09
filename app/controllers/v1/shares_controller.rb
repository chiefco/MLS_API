class V1::SharesController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_share,:only=>([:show, :destroy])
  # GET /v1/shares
  # GET /v1/shares.xml
  def index

  end

  # GET /v1/shares/1
  # GET /v1/shares/1.xml
  def show

  end

  # POST /v1/shares
  # POST /v1/shares.xml
  def create
    params[:share].each do |key, value|
      attachment_id = nil
      item_id = nil
      folder_id = nil
      if value['item']['shared_type'] == "Attachment" 
        attachment_id = value['item']['shared_id'] 
      elsif value['item']['shared_type'] == "Folder" 
        folder_id = value['item']['shared_id']
      else
        item_id = value['item']['shared_id']
      end
     @v1_share = @current_user.shares.create(:user_id=>@current_user._id,:shared_id=> value['item']['shared_id'], :community_id=> value['item']['community_id'], :shared_type=> value['item']['shared_type'], :attachment_id => attachment_id, :item_id => item_id, :folder_id => folder_id)
      @v1_share.save
    end
    params[:share].each do |key, value|
        @v1_share.create_activity("SHARE_"+value['item']['shared_type'].upcase,value['item']['community_id'],value['item']['shared_id'])
      end

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
    @share.update_attributes(:status=>false)
    respond_to do |format|
      format.json {render :json=>success }
    end
  end
  
  def shares_multiple_delete
    Share.any_in(_id: params[:share_list]).update_all(:status => false)
    attachments = Attachment.any_in(_id: params[:share_list]).map(&:id)
    Attachment.delay.delete(attachments) unless attachments.blank?
    
    respond_to do |format|
      format.json {render :json=>success }
    end
  end

  private

  def find_share
    @share= @current_user.shares.find(params[:id])
  end
end
