class V1::LocationsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_location,:only=>[:show,:update,:delete]
  
  def index
    @locations = @current_user.locations
    respond_to do |format|
      format.xml  { render :xml => @locations }
    end
  end

  def show
    respond_to do |format|
      format.xml  { render :xml => @location }
    end
  end

  def create
    @location = @current_user.locations.build(params[:location])
    respond_to do |format|
      if @location.save
        format.xml  { render :xml => @location, :status => :created, :location => @location }
      else
        format.xml  { render :xml => @location.all_errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @location.update_attributes(params[:location])
        format.xml  { head :ok }
      else
        format.xml  { render :xml => @location.all_errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @location.destroy
    respond_to do |format|
      format.xml  { head :ok }
    end
  end
  
  def find_location
    @location = @current_user.locations.find(params[:id])
  end
end
