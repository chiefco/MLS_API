class V1::CategoriesController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_category, :except=>[:index, :create]
  before_filter :find_parent_category,:only=>[:create,:update]

  def index
    @categories = @current_user.categories
    respond_to do |format|
      format.xml  { render :xml => @categories }
      format.json  { render :json => @categories.to_json }
    end
  end

  def show
    respond_to do |format|
      format.xml  { render :xml => @category }
      format.json  { render :json => success.merge(object_to_hash(@category ,[:_id,:name,:parent_id,:show_in_quick_links])) }
    end
  end

  def create
    @category = @current_user.categories.build(params[:category])
    respond_to do |format|
      if @category.save
        format.xml  { render :xml => @category }
        format.json  { render :json => success.merge(object_to_hash(@category,[:name,:parent_id, :show_in_quick_links]))  }
      else
        format.xml  { render :xml => @category.all_errors.to_xml(ROOT) }
        format.json  { render :json => @category.all_errors}
      end
    end
  end

  def update
    respond_to do |format|
      if @category.update_attributes(params[:category])
        format.xml  { render :xml => @category }
        format.json  { render :json => success.merge(object_to_hash(@category,[:_id,:name,:parent_id, :show_in_quick_links]))}
      else
        format.xml  { render :xml => @category.all_errors.to_xml(ROOT)}
        format.json  { render :json =>@category.all_errors}
      end
    end
  end

  def destroy
    @category.destroy
    respond_to do |format|
      format.json { render :json=> success }
      format.xml { render :xml=> success.to_xml(ROOT) }
    end
  end

  def subcategories
    @sub_categories = @category.children
    respond_to do |format|
      format.json { render :json=> success.merge(subcategories_success) }
      format.xml { render :xml=> success.merge(subcategories_success).to_xml(ROOT) }
    end
  end

  def items
    @items = @category.items
    respond_to do |format|
      format.json { render :json=> success.merge(items_success) }
      format.xml { render :xml=> success.merge(items_success).to_xml(ROOT) }
    end
  end

  private

  def subcategories_success
    {:id => params[:id] , :count=>@sub_categories.count, :sub_categories => all_objects_to_hash(@sub_categories,[:_id,:name],{:_id=>:category_id}) }
  end

  def items_success
    {:id => params[:id] , :count=>@items.count, :items => all_objects_to_hash(@items,[:_id,:name],{:_id=>:item_id}) }
  end

  def find_category
    @category= @current_user.categories.find(params[:id])
  end

  def find_parent_category
    @parent_category=@current_user.categories.find(params[:category][:parent_id]) if params[:category] && params[:category][:parent_id]
  end

end
