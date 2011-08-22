class V1::CategoriesController < ApplicationController
  # GET /v1/categories
  # GET /v1/categories.xml
  def index
    @categories = Category.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @categories }
      format.json  { render :json => @categories }
    end
  end

  # GET /v1/categories/1
  # GET /v1/categories/1.xml
  def show
    @category = Category.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @category }
      format.json  { render :json => @category }
    end
  end

  # GET /v1/categories/new
  # GET /v1/categories/new.xml
  def new
    @category = Category.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @category }
      format.json  { render :json => @category }
    end
  end

  # GET /v1/categories/1/edit
  def edit
    @category = Category.find(params[:id])
  end

  # POST /v1/categories
  # POST /v1/categories.xml
  def create
    @category = Category.new(params[:v1_category])

    respond_to do |format|
      if @category.save
        format.xml  { render :xml => @category, :status => :created, :location => @category }
        format.json  { render :json => {@category.success_json(["id","name"]).merge(success)}, :status => :created, :location => @category }
      else
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
        format.json  { render :json => { "errors"=> @category.all_errors}}
      end
    end
  end

  # PUT /v1/categories/1
  # PUT /v1/categories/1.xml
  def update
    @category = Category.find(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:v1_category])
        format.html { redirect_to(@category, :notice => 'Category was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /v1/categories/1
  # DELETE /v1/categories/1.xml
  def destroy
    @category = Category.find(params[:id])
    @category.destroy

    respond_to do |format|
      format.html { redirect_to(v1_categories_url) }
      format.xml  { head :ok }
    end
  end
end
