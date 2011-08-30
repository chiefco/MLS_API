class V1::SearchesController < ApplicationController
  before_filter :authenticate_request!
  def index
    @v1_searches = Search.all

    respond_to do |format|
      format.xml  { render :xml => @v1_searches }
    end
  end

  def show
    @v1_search = Search.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @v1_search }
    end
  end

  def create
    @v1_search = Search.new(params[:v1_search])
    respond_to do |format|
      if @v1_search.save
        format.xml  { render :xml => @v1_search, :status => :created, :location => @v1_search }
      else
        format.xml  { render :xml => @v1_search.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @v1_search = Search.find(params[:id])

    respond_to do |format|
      if @v1_search.update_attributes(params[:v1_search])
        format.xml  { head :ok }
      else
        format.xml  { render :xml => @v1_search.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @v1_search = Search.find(params[:id])
    @v1_search.destroy

    respond_to do |format|
      format.xml  { head :ok }
    end
  end

  def search

  end
end
