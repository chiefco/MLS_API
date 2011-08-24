class V1::SearchesController < ApplicationController
  # GET /v1/searches
  # GET /v1/searches.xml
  def index
    @v1_searches = V1::Search.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @v1_searches }
    end
  end

  # GET /v1/searches/1
  # GET /v1/searches/1.xml
  def show
    @v1_search = V1::Search.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @v1_search }
    end
  end

  # GET /v1/searches/new
  # GET /v1/searches/new.xml
  def new
    @v1_search = V1::Search.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @v1_search }
    end
  end

  # GET /v1/searches/1/edit
  def edit
    @v1_search = V1::Search.find(params[:id])
  end

  # POST /v1/searches
  # POST /v1/searches.xml
  def create
    @v1_search = V1::Search.new(params[:v1_search])

    respond_to do |format|
      if @v1_search.save
        format.html { redirect_to(@v1_search, :notice => 'Search was successfully created.') }
        format.xml  { render :xml => @v1_search, :status => :created, :location => @v1_search }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @v1_search.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /v1/searches/1
  # PUT /v1/searches/1.xml
  def update
    @v1_search = V1::Search.find(params[:id])

    respond_to do |format|
      if @v1_search.update_attributes(params[:v1_search])
        format.html { redirect_to(@v1_search, :notice => 'Search was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @v1_search.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /v1/searches/1
  # DELETE /v1/searches/1.xml
  def destroy
    @v1_search = V1::Search.find(params[:id])
    @v1_search.destroy

    respond_to do |format|
      format.html { redirect_to(v1_searches_url) }
      format.xml  { head :ok }
    end
  end
end
