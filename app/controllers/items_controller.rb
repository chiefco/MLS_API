class ItemsController < ApplicationController
  #~ before_filter :authenticate_user!
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
<<<<<<< HEAD:app/controllers/items_controller.rb
    @template=Template.find(params[:item][:template_id]) if params[:item][:template_id]
    respond_to do |format|
      if @item.save
        format.html { redirect_to(@item, :notice => 'Item was successfully created.') }
        format.xml  { render :xml => @item, :status => :created, :location => @item }
        format.json  { render :json => {"item"=>{:item_id=>@item.id,:name=>@template.name}} }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
        format.json  { render :json => {"errors"=>@item.all_errors } }
=======
    respond_to do |format|
      if @item.save
        current_user.items<<@item
        format.xml { render_for_api :item_detail, :xml => @item, :root => :item}
        format.json { render_for_api :item_detail,:json => @item, :status => :created }
      else
        format.xml { render :xml=> @item.all_errors.to_xml(:root=>'errors') }
        format.json { render :json=> @item.all_errors }
>>>>>>> master:app/controllers/items_controller.rb
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.xml
  def update
    @item = Item.find(params[:id])
    respond_to do |format|
      if @item.update_attributes(params[:item])
        @location=Location.create(:name=>params[:item][:location])
        @item.update_attributes(:location_id=>@location.id)
        format.html { redirect_to(@item, :notice => 'Item was successfully updated.') }
        format.xml  { render :xml=>@item }
        format.json  { render :json =>{"item"=>{"description"=>@item.description,"item_date"=>@item.item_date,"location"=>@location.name}} }
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
