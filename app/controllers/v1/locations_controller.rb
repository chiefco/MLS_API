class V1::LocationsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_location,:only=>[:show,:update,:destroy]
  LOCATION=[:id,:name,:latitude,:longitude]
  
  def index
    @locations = @current_user.locations
    respond_to do |format|
      format.xml  { render :xml => @locations,:root=>:result }
      format.json  { render :json => @locations }
    end
  end

  def show
    respond_to do |format|
      format.xml  { render :xml => single_response.to_xml(:root=>:result) }
      format.json  { render :json => single_response.to_json }
    end
  end

  def create
    @location = @current_user.locations.build(params[:location])
    respond_to do |format|
      if @location.save
        format.xml  { render :xml => single_response.to_xml(:root=>:result) }
        format.json  { render :json => single_response.to_json  }
      else
        format.xml  { render :xml => @location.all_errors, :status => :unprocessable_entity, :root=>:result }
        format.json  { render :json => @location.all_errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @location.update_attributes(params[:location])
        format.xml  { render :xml =>single_response.to_xml , :root=>:result}
        format.json  { render :json =>single_response.to_json}
      else
        format.xml  { render :xml => @location.all_errors, :status => :unprocessable_entity, :root=>:result }
        format.json  { render :xml => @location.all_errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @location.destroy
    respond_to do |format|
      format.xml  {render :xml=>success, :root=>:result }
      format.json  {render :json=>success }
    end
  end
  
  def find_location
    @location = @current_user.locations.find(params[:id])
  end
  
  def single_response
    {:response=>:success,:location=>@location}
  end
  
  def multi_result
    {:response=>:success,:location=>@locations}
  end
end
