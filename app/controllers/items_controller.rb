class ItemsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html, :xml, :json
  # GET /items
  # GET /items.xml
  def index
    @items = current_user.items
    respond_with(@items)
  end

  # GET /items/1
  # GET /items/1.xml
  def show
    @item = current_user.items.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @item }
    end
  end

  def create
    @item = Item.new(params[:item])
    respond_to do |format|
      if @item.save
        current_user.items<<@item
        format.xml { render_for_api :item_detail, :xml => @item, :root => :item}
        format.json { render_for_api :item_detail,:json => @item, :status => :created }
      else
        format.xml { render :xml=> @item.all_errors.to_xml(:root=>'errors') }
        format.json { render :json=> @item.all_errors }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.xml
  def update
    @item = Item.find(params[:id])
    respond_to do |format|
      if @item.update_attributes(params[:item])
        format.html { redirect_to(@item, :notice => 'Item was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    @item = Item.find(params[:id])
    @item.destroy
    respond_to do |format|
      format.html { redirect_to(items_url) }
      format.xml  { head :ok }
    end
  end
end
