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
      value['item']['shared_type'] == "Attachment" ? attachment_id = value['item']['shared_id'] : item_id = value['item']['shared_id']
     @v1_share = @current_user.shares.create(:user_id=>@current_user._id,:shared_id=> attachment_id, :community_id=> value['item']['community_id'], :shared_type=> value['item']['shared_type'], :attachment_id => attachment_id, :item_id => item_id)
     @v1_share.save
     @v1_share.create_activity("SHARE_CREATED_"+value['item']['shared_type'].upcase,value['item']['community_id'])
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
     
  end

  private

  def find_share
    @share= @current_user.shares.find(params[:id])
  end
end
