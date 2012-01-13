class V1::SearchesController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_search,:only=>[:show,:update,:destroy]
  before_filter :paginate_params,:only=>:search
  SEARCH_FIELDS=[:response,:searches,:name,:description,:_type,:_id]
  def index
    @searches = @current_user.searches.all
    respond_to do |format|
      format.xml  { render :xml => multi_success.to_xml(:root=>:result) }
      format.json  { render :json => multi_success.to_json(:except=>[:created_at,:updated_at,:user_id]) }
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
         p @search.all_errors
        format.json  { render :json => @search.all_errors }
        format.xml  { render :xml => @search.all_errors.to_xml(:root=>:result), :status => :unprocessable_entity }
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
    items = Sunspot.search(Item) do |search|
      search.keywords params[:q].downcase, :boost=>4.0
      search.with(:user_id,@current_user.id)
    end
    
    attachments = @current_user.attachments.solr_search do |search|
      search.with(:file_name).starting_with(params[:q].downcase)
    end    
    
    if params[:sort] == 'modified'
      items.results.map(&:name)
      items.results.sort_by{ |k| k.updated_at }.map(&:name)
      items = items.results.sort_by{ |k| k.updated_at }.reverse
      attachments = attachments.results.sort_by{ |k| k.updated_at }.reverse
    else
      items = items.results.sort_by{ |k| k.name }
      attachments = attachments.results.sort_by{ |k| k.file_name }
    end
    
    unless params[:limit]
      respond_to do |format|
        format.xml  { render :xml => {:response=>:success,:searches=>results}.to_xml(:root=>:result,:only=>SEARCH_FIELDS) }
        format.json {render :json =>{:items=>items.to_json(:only=>[:name,:_id],:methods=>[:location_name,:item_date,:end_time,:created_time,:updated_time, :template_id, :item_date_local]).parse, :attachments=>attachments.to_json(:only=>[:_id, :file_name, :file_type, :size, :content_type,:file,:created_at]).parse}.to_success}
      end
    else
      items << attachments
      respond_to do |format|
        format.xml  { render :xml => {:response=>:success,:searches=>items}.to_xml(:root=>:result,:only=>SEARCH_FIELDS) }
        format.json {render :json =>{:items=>items.flatten.to_json(:only=>[:name,:_type,:file_name]).parse}.to_success}
      end      
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
