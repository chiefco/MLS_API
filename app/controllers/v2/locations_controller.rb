class V2::LocationsController < ApplicationController
  before_filter :authenticate_request!,:except=>[:get_altitude,:location_names]
  before_filter :find_location,:only=>[:show,:update,:destroy]
  LOCATION=[:id,:name,:latitude,:longitude]
  before_filter :paginate_params,:only=>[:index]
  
  # Public: Get user all locations
  def index
    @locations = @current_user.locations.paginate(:page=>params[:page],:per_page=>params[:page_size])
    respond_to do |format|
      format.xml  { render :xml => multi_result.to_xml(:root=>:result) }
      format.json  { render :json =>multi_result }
    end
  end

  # Public: show
  def show
    respond_to do |format|
      format.xml  { render :xml => single_response.to_xml(:root=>:result) }
      format.json  { render :json => single_response.to_json }
    end
  end

  # Public: Create user location
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

  # Public: Update user location
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

  # Public: Delete user location
  def destroy
    @location.destroy
    respond_to do |format|
      format.xml  {render :xml=>success, :root=>:result }
      format.json  {render :json=>success }
    end
  end

  # Public: To get altitude of location
  def get_altitude
    respond_to do |format|
      @altitude=Location.get_altitude(params[:location])
      if @altitude
        format.json  {render :json=>success.merge(:altitude=>@altitude)}
      else
        format.json  {render :json=>failure}
      end
    end
  end

  # Public: To get location name
  def location_names
    respond_to do |format|
      @latitude,@longitude=params[:latitude],params[:longitude]
      if (@latitude and @longitude)
        @values=Geocoder.search("#{@latitude},#{@longitude}").first.data["address_components"]
        format.xml  {render :xml=>success, :root=>:result }
                @country=@values[@values.count-1]["long_name"]
        @state=@values[@values.count-2]["long_name"]
        @city=@values[@values.count-3]["long_name"]
        format.xml  {render :xml=>success, :root=>:result }
        format.json  {render :json=>success.merge(:country=>@country,:state=>@state,:city=>@city)}
         else
        format.xml  {render :xml=>failure, :root=>:result }
        format.json  {render :json=>failure}
      end
    end
  end

  # Public: To find location
  def find_location
    @location = @current_user.locations.find(params[:id])
  end

  # Public: To get single location
  def single_response
    {:response=>:success,:location=>@location.serializable_hash(:except=>[:created_at,:updated_at,:user_id])}
  end

  # Public: To get multiple locations
  def multi_result
    {:response=>:success,:location=>@locations}
  end
end
