class V1::ItemsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :get_item,:only=>([:update,:show,:item_categories,:destroy,:item_topics,:item_add_category])
  respond_to :html, :xml, :json
  # GET /items
  # GET /items.xml
  def index
    paginate_options = {} 
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    if params[:sort_by] && params[:order_by]
     @items = params[:q] ? Item.any_of(get_criteria(params[:q])).order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)  : Item.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)
    elsif params[:sort_by] 
      @items = params[:q] ? Item.any_of(get_criteria(params[:q])).order_by([params[:sort_by],:desc]).paginate(paginate_options) : Item.order_by([params[:sort_by],:desc]).paginate(paginate_options) 
    else
      @items = params[:q] ? Item.any_of(get_criteria(params[:q])).order_by(['created_at', :desc]).paginate(paginate_options) : Item.order_by(['created_at', :desc]).paginate(paginate_options)
      end
    #~ @items = Item.paginate(conditions: {page: params[:page], per_page:params[:size]})
    respond_to do |format|
      format.xml  { render :xml => @items}
      format.json {render :json =>{:items=>@items.to_json(:only=>[:name,:_id],:methods=>:location_name),:count=>@items.size}.merge(success)}
    end
  end

  # GET /items/1
  # GET /items/1.xml
  def show
    respond_to do |format|
      format.xml  { render :xml => @item }
      format.json  { render :json =>{"item"=>{:item_id=>@item.id,:item_name=>@item.name,:location=>(@item.location.nil? ? "nil" : @item.location.name),:description=>@item.description,:current_category_name=>(@item.current_category_id.nil? ? "nil" : Category.find(@item.current_category_id).name),:created_at=>@item.created_at,:updated_at=>@item.updated_at}}.merge(success) }
    end
  end

  # POST /items
  # POST /items.xml

  def create
    @item = Item.new(params[:item])
    @template=Template.find(params[:item][:template_id]) if params[:item][:template_id]
    respond_to do |format|
      if @template
          if @item.save
            format.xml  { render :xml => @item, :status => :created, :location => @item }
            format.json  { render :json => {"item"=>{:item_id=>@item.id,:name=>@template.name}}.merge(success) }
          else
            format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
            format.json  { render :json => {"errors"=>@item.all_errors } }
          end
      else
          format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
          format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.xml
  def update
    respond_to do |format|
      if @item.update_attributes(params[:item])
        if params[:item][:location]
          @location=Location.create(:name=>params[:item][:location]) 
          @item.update_attributes(:location_id=>@location.id)
        end
        format.xml  { render :xml=>@item }
        format.json  { render :json =>{"item"=>{:description=>@item.description,:item_date=>@item.item_date,:location=>@location.nil? ?  "nil" :@location.name}}.merge(success) }
      else
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    @item.destroy
    respond_to do |format|
      format.xml  { head :ok }
      format.xml  { render :xml => success.to_xml(:root=>'xml') }
      format.json  { render :json=> success}
    end
  end
  
  def  item_topics
    @topics=@item.topics(:fields=>[:name,:_id])
    respond_to do |format| 
      format.json {render :json=>{:item=>@topics.to_a.to_json(:only=>[:name,:_id,:status]),:count=>@item.topics.count}.merge(success)}
 #~ format.json {render :json =>{:items=>@items.to_json(:only=>[:name,:_id],:methods=>:location_name),:count=>@items.size}.merge(success)}
    end
  end
  
  #finds categories of the item
  def item_categories
    categories=[]
    respond_to do |format|
      if @item
        @item.categories.each do |category|
          categories<<{:name=>category.name,:id=>category._id,:parent_id=>category.parent_id}
        end
        format.json{render :json=>{:item_categories=>categories}.merge(success)}
      end
    end
  end
  
  #Adds the category to the given item
  def item_add_category
    @item=Item.find(params[:item_category][:item_id])
    @category=Category.where(:_id=>params[:item_category][:category_id]).first
    respond_to do  |format| 
      if @item && @category
        @item.categories<<@category
        format.json{render :json=>{:item_category=>{:category_id=>@category._id,:item_id=>@item._id}}}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  #Adds the attendee to the given item
  def item_add_attendees
    @item=Item.where(:_id =>params[:item_attendee][:item_id]).first
    respond_to do |format|
      if @item
        @attendee=@item.attendees.new(params[:item_attendee])
        if @attendee.save
          format.json {render :json=>{:item_attendee=>@attendee.to_json(:only=>[:_id,:first_name,:last_name])}.merge(success)}
          #~ format.xml {render :json=>success.merge({:item_attendee=>@attendee.to_xml(:only=>[:_id,:first_name,:last_name])})}
        else
          format.json {render :json=>{:errors=>@attendee.all_errors}.merge(failure)}
          format.xml {render :xml=>failure.merge(@attendee.errors)}
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  #Removes the attendee of the item
  def item_remove_attendees
    @attendee=Attendee.where(:id=>params[:attendee_id])
    respond_to do |format|
      if @attendee
        @attendee.destroy
        format.json{render :json=>success}
        format.xml{render :json=>failure}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  #Lists all attendees of the given item
  def list_item_attendees 
    @item=Item.find(params[:id])
    respond_to do |format|
      if @item
         @attendees=@item.attendees
        format.json{render :json=>{:item_attendees=>@attendees.to_a.to_json(:only=>[:_id,:first_name,:last_name])}}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
    
  def get_criteria(query)
    [ {name: query} , { description: query } ]
  end 
  
  def get_item
    @item=Item.find(params[:id])
  end
end
