class V1::CategoriesController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_category, :except=>[:index, :create]

  def index
    paginate_options = {}
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    @categories = Category.list(@current_user.categories,params,paginate_options)
    
    respond_to do |format|
      format.xml  { render :xml =>  @categories.to_xml(:only=>[:_id, :name]).as_hash.merge( :count=> @categories.count).to_success.to_xml(ROOT) }
      format.json  { render :json => { :categories=>@categories.to_json(:only=>[:_id, :name]).parse, :count=>@categories.count }.to_success } 
    end 
  end

  def show
    respond_to do |format|
      format.xml  { render :xml => @category.to_xml(:only=>[:_id,:name,:parent_id,:show_in_quick_links]).as_hash.to_success.to_xml(ROOT)}
      format.json  { render :json => @category.to_json(:only=>[:_id,:name,:parent_id,:show_in_quick_links]).parse.to_success }
    end
  end

  def create
    @category = @current_user.categories.build(params[:category])
    
    respond_to do |format|
      if @category.save
        format.xml  { render :xml => @category.to_xml(:only=>[:_id,:name,:parent_id,:show_in_quick_links]).as_hash.to_success.to_xml(ROOT)}
        format.json  { render :json => {:category=>@category.to_json(:only=>[:_id,:name,:parent_id,:show_in_quick_links]).parse }.to_success }
      else
        format.xml  { render :xml => @category.all_errors.to_xml(ROOT) }
        format.json  { render :json => @category.all_errors}
      end
    end
  end

  def update
    respond_to do |format|
      if @category.update_attributes(params[:category])
        format.xml  { render :xml => @category.to_xml(:only=>[:_id,:name,:parent_id,:show_in_quick_links]).as_hash.to_success.to_xml(ROOT)}
        format.json  { render :json => {:category=>@category.to_json(:only=>[:_id,:name,:parent_id,:show_in_quick_links]).parse }.to_success }
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
      format.json  { render :json => { :sub_categories=>@sub_categories.to_a.to_json(:only=>[:_id, :name]).parse, :count=>@sub_categories.count, :id=>@category.id}.to_success } 
      format.xml  { render :xml =>  @sub_categories.to_xml(:only=>[:_id, :name]).as_hash.merge( :count=> @sub_categories.count, :id=>@category.id).to_success.to_xml(ROOT) }
    end
  end

  def items
    @items = @category.items
    
    respond_to do |format|
      format.json  { render :json => { :items=>@items.to_a.to_json(:only=>[:_id, :name]).parse, :count=>@items.count, :id=>@category.id}.to_success } 
      format.xml  { render :xml =>  @items.to_xml(:only=>[:_id, :name]).as_hash.merge( :count=> @items.count, :id=>@category.id).to_success.to_xml(ROOT) }
    end
  end

  private

  def find_category
    @category= @current_user.categories.find(params[:id])
  end

end
