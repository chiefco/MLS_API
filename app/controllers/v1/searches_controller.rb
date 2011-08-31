class V1::SearchesController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_search,:only=>[:show,:update,:destroy]
  def index
    @searches = @current_user.searches.all
    respond_to do |format|
      format.xml  { render :xml => multi_success.to_xml(:root=>:result) }
      format.json  { render :json => multi_success.to_json }
    end
  end

  def show
    respond_to do |format|
      format.xml  { render :xml => render_success.to_xml(:root=>:result) }
      format.json  { render :json => render_success }
    end
  end

  def create
    @search = @current_user.searches.build(params[:search])
    respond_to do |format|
      if @search.save
        format.xml  { render :xml => render_success.to_xml(:root=>:result)}
        format.json  { render :json => render_success.to_json}
      else
        format.xml  { render :xml => @search.all_errors.to_xml(:root=>:result), :status => :unprocessable_entity }
        format.json  { render :json => @search.all_errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @search.update_attributes(params[:search])
        format.xml  { render :xml => render_success.to_xml(:root=>:result) }
        format.json  { render :json => render_success.to_json }
      else
        format.xml  { render :xml => @search.all_errors.to_xml(:root=>:result), :status => :unprocessable_entity }
        format.json  { render :json => @search.all_errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @search.destroy
    respond_to do |format|
      format.xml  { render :xml => success }
      format.json  { render :json => success }
    end
  end

  def search

  end

  private

  def find_search
    @search = @current_user.searches.find(params[:id])
  end
  
  def multi_success
    {:response=>:success,:searches=>@searches}
  end
  
  def render_success
    {:response=>:success,:search=>@search}
  end    
end
