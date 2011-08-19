class ItemsController < ApplicationController
  #~ before_filter :authenticate_user!
  respond_to :html, :xml, :json
  # GET /items
  # GET /items.xml
  def index
    @items = Item.all
    respond_to do |format|
      format.xml  { render :xml => @item }
      format.json  { render :json =>{:count=>@items.size,:items=>@items }.merge(success)}
    end
  end

  # GET /items/1
  # GET /items/1.xml
  def show
    @item = Item.find(params[:id])
    respond_to do |format|
      format.xml  { render :xml => @item }
      format.json  { render :json =>{"item"=>{:item_id=>@item.id,:item_name=>@item.name,:location=>@item.location.name,:description=>@item.description,:current_category_name=>(@item.current_category_id.nil? ? "nil" : Category.find(@item.current_category_id).name),:created_at=>@item.created_at,:updated_at=>@item.updated_at}}.merge(success) }
    end
  end
  # GET /items/new
  # GET /items/new.xml
  def new
    @item = Item.new
    respond_to do |format|
      format.xml  { render :xml => @item }
    end
  end

  # GET /items/1/edit
  def edit
    @item = Item.find(params[:id])
  end

  # POST /items
  # POST /items.xml

  def create
    @item = Item.new(params[:item])
    @template=Template.find(params[:item][:template_id]) if params[:item][:template_id]
    respond_to do |format|
      if @item.save
        format.xml  { render :xml => @item, :status => :created, :location => @item }
        format.json  { render :json => {"item"=>{:item_id=>@item.id,:name=>@template.name}}.merge(success) }
      else
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
        format.json  { render :json => {"errors"=>@item.all_errors } }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.xml
  def update
    @item = Item.find(params[:id])
    respond_to do |format|
      if @item.update_attributes(params[:item])
        if params[:item][:location]
          @location=Location.create(:name=>params[:item][:location]) 
          @item.update_attributes(:location_id=>@location.id)
        end
        format.xml  { render :xml=>@item }
        format.json  { render :json =>{"item"=>{"description"=>@item.description,"item_date"=>@item.item_date,"location"=>@location.name}}.merge(success) }
      else
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
      format.xml  { head :ok }
      format.xml  { render :xml => success.to_xml(:root=>'xml') }
      format.json  { render :json=> success}
    end
  end
end
