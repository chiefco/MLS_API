class V1::SearchesController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_search,:only=>[:show,:update,:destroy]
  def index
    @searches = Search.all
    respond_to do |format|
      format.xml  { render :xml => @searches }
    end
  end

  def show
    respond_to do |format|
      format.xml  { render :xml => @search }
    end
  end

  def create
    @search = Search.new(params[:search])
    respond_to do |format|
      if @search.save
        format.xml  { render :xml => @search, :status => :created, :location => @search }
      else
        format.xml  { render :xml => @search.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @search.update_attributes(params[:search])
        format.xml  { head :ok }
      else
        format.xml  { render :xml => @search.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @search.destroy
    respond_to do |format|
      format.xml  { head :ok }
    end
  end

  def search

  end

  private

  def find_search
    @search = Search.find(params[:id])
  end
end
