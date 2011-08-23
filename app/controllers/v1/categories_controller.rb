class V1::CategoriesController < ApplicationController
  
  before_filter :authenticate_request!
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
        format.json  { render :json => success.merge(object_to_hash(@category ,[:_id,:name,:parent_id,:show_in_quick_links])) }
      end
    else
      respond_to do |format|
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
        format.xml { render :xml=>  failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>"error") } 
      end
    end 
  end

  # POST /v1/categories
  # POST /v1/categories.xml
  def create
    @category = Category.new(params[:category])

    respond_to do |format|
      if @category.save
        format.xml  { render :xml => @category }
        format.json  { render :json => success.merge(object_to_hash(@category,[:name,:parent_id, :show_in_quick_links]))  }
      else
        format.xml  { render :xml => @category.all_errors, :root=>"errors" }
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
          format.xml  { render :xml => @category }
          format.json  { render :json => success.merge(object_to_hash(@category,[:_id,:name,:parent_id, :show_in_quick_links]))}
        else
          format.xml  { render :xml => @category.all_errors , :root=>"errors"}
          format.json  { render :json => { "errors"=> @category.all_errors}}
        end
      end
    else
      respond_to do |format|
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
        format.xml { render :xml=> failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>"errors") }
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
        format.xml { render :xml=> success.to_xml(:root=>"result") }
      end
    else
      respond_to do |format|
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
        format.xml { render :xml=> failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'error') }
      end
    end
  end
  
  #List sub categories /category_subcategories/:id
  def subcategories
    @category= Category.where(:_id =>params[:id])
    if @category.first
      @sub_categories = @category.first.children
      respond_to do |format| 
        format.json { render :json=> success.merge(subcategories_success) }
        format.xml { render :xml=> success.merge(subcategories_success).to_xml(:root=>'result') }
      end 
    else
      respond_to do |format|
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
        format.xml { render :xml=> failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'error') }
      end
    end 
  end 
  
  def items
    @category= Category.where(:_id =>params[:id])
    if @category.first
      @items = @category.first.items
      respond_to do |format| 
        format.json { render :json=> success.merge(items_success) }
        format.xml { render :xml=> success.merge(items_success).to_xml(:root=>'result') }
      end 
    else
      respond_to do |format|
        format.json { render :json=> failure.merge(INVALID_PARAMETER_ID) }
        format.xml { render :xml=> failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'error') }
      end
    end 
  end 
  
  private 
  
  def subcategories_success
    {:id => params[:id] , :count=>@sub_categories.count, "sub-categories" => all_objects_to_hash(@sub_categories,[:_id,:name],{:_id=>:category_id}) }
  end 
  
  def items_success
    {:id => params[:id] , :count=>@items.count, "items" => all_objects_to_hash(@items,[:_id,:name],{:_id=>:item_id}) }
  end 
  
end
