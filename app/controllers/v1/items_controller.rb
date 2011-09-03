class V1::ItemsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :get_item,:only=>([:update,:show,:item_categories,:destroy,:item_topics,:get_all_tasks,:list_item_attendees])
  before_filter :add_pagination,:only=>[:index]

  # GET /items
  # GET /items.xml
  def index
    @items = Item.list(params,@paginate_options,@current_user)
    respond_to do |format|
      format.xml  { render :xml => @items}
      format.json {render :json =>{:items=>@items.to_json(:only=>[:name,:_id],:methods=>:location_name).parse,:count=>@items.size}.merge(success)}
  end
  end

  # GET /items/1
  # GET /items/1.xml
  def show
    respond_to do |format|
      if @item 
        @item={"item"=>{:item_id=>@item.id,:item_name=>@item.name,:location=>(@item.location.nil? ? "nil" : @item.location.name),:description=>@item.description,:current_category_name=>(@item.current_category_id.nil? ? "nil" : Category.find(@item.current_category_id).name),:created_at=>@item.created_at,:updated_at=>@item.updated_at}}.to_success
        format.xml  { render :xml => @item.to_xml(ROOT) }
        format.json  { render :json => @item}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # POST /items
  # POST /items.xml

  def create
    @item = @current_user.items.new(params[:item])
    @template=Template.find(params[:item][:template_id]) if params[:item][:template_id]
    respond_to do |format|
      if @template
          if @item.save
            @item={:item=>@item.serializable_hash(:only=>[:_id,:name])}.to_success
            format.xml  {render :xml => @item.to_xml(ROOT)}
            format.json  {render :json =>@item}
          else
            format.xml  { render :xml => failure.merge(@item.all_errors).to_xml(ROOT)}
            format.json  { render :json => @item.all_errors }
          end
      else
          format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
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
        @item={:item=>@item.serializable_hash(:only=>[:item_date,:description,:current_category_id]),:location=>@location.name}.to_success 
        format.xml  {render :xml=>@item.to_xml(ROOT)}
        format.json {render :json =>@item}
      else
        format.xml  { render :xml => @item.all_errors.to_xml(ROOT)}
        format.json {render :json =>@item.all_errors}
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    respond_to do |format|
      if @item
      @item.destroy
        format.xml  { render :xml => success.to_xml(ROOT) }
        format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
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
        format.json{render :json=>{:item_categories=>categories,:count=>categories.count}.merge(success)}
      end
    end
  end

  #Adds the category to the given item
  def item_add_category
    @item=Item.find(params[:item_category][:item_id])
    @category=Category.find(params[:item_category][:category_id])
    respond_to do  |format|
      if @item && @category
        @item.categories<<@category
        format.json{render :json=>{:item_category=>{:category_id=>@category._id,:item_id=>@item._id}}}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  #Adds the attendee to the given item
  def item_add_attendees
    @item=Item.find(params[:item_attendee][:item_id])
    respond_to do |format|
      @attendee=@item.attendees.build(params[:item_attendee])
      puts @attendee.valid?
      puts @attendee.errors.inspect
      if @attendee.save
        format.json {render :json=>{:response=>:success,:item_attendee=>@attendee}.to_json}
        format.xml {render :xml=>{:response=>:success,:item_attendee=>@attendee}.to_xml}
      else
        format.json {render :json=>@attendee.all_errors}
        format.xml {render :xml=>@attendee.all_errors}
      end
    end
  end

  #Removes the attendee of the item
  def item_remove_attendees
    @attendee=Attendee.find(params[:attendee_id])
    respond_to do |format|
      if @attendee
        @attendee.destroy
        format.json{render :json=>success}
        format.xml{render :json=>failure}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  #Lists all attendees of the given item
  def list_item_attendees
    respond_to do |format|
      if @item
         @attendees=@item.attendees
        format.json{render :json=>{:item_attendees=>@attendees.to_a.to_json(:only=>[:_id,:first_name,:last_name])}}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  #Get all tasks of the desired Item
  def get_all_tasks
    respond_to do |format|
      if @item
        format.json{ render :json=>{:item_task=>@item.tasks.to_a.to_json(:only=>[:description,:due_date,:_id,:is_completed],:include=>{:item=>{:only=>[:_id,:name]}})}}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
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
