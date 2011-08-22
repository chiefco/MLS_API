class V1::CategoriesController < ApplicationController
  #before_filter :authenticate_user!
  # GET /v1/categories
  # GET /v1/categories.xml
  def index
    @categories = Category.all

    respond_to do |format|
      format.xml  { render :xml => @categories }
      format.json  { render :json => @categories }
    end
  end

  # GET /v1/categories/1
  # GET /v1/categories/1.xml
  def show
    @category = Category.where(:_id=>params[:id]).first
    if @category
      respond_to do |format|
        format.xml  { render :xml => @category }
        format.json  { render :json => success.merge(@category.success_json(["_id","name","parent_id","show_in_quick_links"])) }
      end
    else
      respond_to do |format|
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
      end
    end 
  end

  # POST /v1/categories
  # POST /v1/categories.xml
  def create
    @category = Category.new(params[:category])

    respond_to do |format|
      if @category.save
        format.xml  { render :xml => @category, :status => :created }
        format.json  { render :json => success.merge(@category.success_json(["name","parent_id", "show_in_quick_links"]))  }
      else
        format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
        format.json  { render :json => { "errors"=> @category.all_errors}}
      end
    end
  end

  # PUT /v1/categories/1
  # PUT /v1/categories/1.xml
  def update
    @category = Category.where(:_id=>params[:id]).first
    if @category
      respond_to do |format|
        if @category.update_attributes(params[:category])
          format.xml  { render :xml => @category, :status => :created}
          format.json  { render :json => success.merge(@category.success_json(["_id","name","parent_id", "show_in_quick_links"]))}
        else
          format.xml  { render :xml => @category.errors, :status => :unprocessable_entity }
          format.json  { render :json => { "errors"=> @category.all_errors}}
        end
      end
    else
      respond_to do |format|
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
      end
    end 
  end

  # DELETE /v1/categories/1
  # DELETE /v1/categories/1.xml
  def destroy
    @category = Category.where(:_id=>params[:id]).first
    if @category
      @category.destroy
      respond_to do |format|
        format.json { render :json=> success }
      end
    else
      respond_to do |format|
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
      end
    end
  end
end
