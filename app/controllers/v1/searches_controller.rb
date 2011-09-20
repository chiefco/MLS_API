class V1::SearchesController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_search,:only=>[:show,:update,:destroy]
  before_filter :paginate_params,:only=>:search
  SEARCH_FIELDS=[:response,:searches,:name,:description,:_type,:_id]
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
    @searches=Sunspot.search(Item, Category, Location, Bookmark) do |search|
      search.keywords params[:q]
      search.with(:user_id,@current_user.id)
      search.paginate :page =>params[:page], :per_page=>params[:page_size]
    end
    results=@searches.results
    #~ @searches=@current_user.items.solr_search do |search|
      #~ search.keywords params[:q]
    #~ end
    respond_to do |format|
      format.xml  { render :xml => {:response=>:success,:searches=>results}.to_xml(:root=>:result,:only=>SEARCH_FIELDS) }
      format.json  { render :json => {:response=>:success,:searches=>results}.to_json(:only=>SEARCH_FIELDS) }
    end
  end

  private

  def find_search
    @search = @current_user.searches.find(params[:id])
  end

  def multi_success
    {:response=>:success,:searches=>@searches}
  end

  def render_success
    {:response=>:success,:search=>@search.serializable_hash(:except=>[:created_at,:updated_at,:user_id])}
  end
end
