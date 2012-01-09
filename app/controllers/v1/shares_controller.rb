class V1::SharesController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_bookmark,:only=>([:update,:show,:destroy,:add_bookmark,:remove_bookmark])
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
     @v1_share = @current_user.shares.new(value['item'])
     @v1_share.save
    end
    respond_to do |format|
	format.xml  { render :xml => success.merge(:share=>@v1_share).to_xml(ROOT,:only=>[:name,:_id])}
	format.json  { render :json =>{:share=>@v1_share.to_json(:only=>[:_id]).parse}.to_success }
     # if @v1_share.save
      #  format.xml  { render :xml => success.merge(:share=>@v1_share).to_xml(ROOT,:only=>[:name,:_id])}
      #  format.json  { render :json =>{:bookmark=>@v1_share.to_json(:only=>[:name,:_id]).parse}.to_success }
      #else
       # format.xml  { render :xml => failure.merge(@v1_share.all_errors).to_xml(ROOT)}
      #  format.json  { render :json => @v1_share.all_errors }
     # end
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
