class V1::ItemsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :get_item,:only=>([:update,:show,:item_categories,:destroy,:item_topics,:get_all_tasks,:list_item_attendees])
  before_filter :add_pagination,:only=>[:index]
  before_filter :detect_missing_params, :only=>[:create]
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
        @item={:item=>@item.serializable_hash(:only=>[:_id,:name,:description,:item_date,:custom_page],:include=>{:location=>{:only=>[:_id,:name]}}),:current_category_id=>(@item.current_category_id.nil? ? "nil" : Category.find(@item.current_category_id)._id)}.to_success
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
    @template=Template.find(params[:item][:template_id]) if params[:item][:template_id]
    params[:item].merge!({:custom_page=>@template.custom_page}) if @template.has_custom_page?
    @item = @current_user.items.new(params[:item]) 
    #~ @item.custome
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
        @item={:item=>@item.serializable_hash(:only=>[:description,:current_category_id],:methods=>:item_date),:location=>@location.name}.to_success
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
    respond_to do |format|
      if @item
      @topics=@item.topics
        @topic={:item_topics=>@topics.serializable_hash(:only=>[:name,:_id,:status]),:count=>@item.topics.count}.to_success
        format.json {render :json=>@topic}
        format.xml {render :xml=>@topic.to_xml(ROOT)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  #finds categories of the item
  def item_categories
    respond_to do |format|
      if @item
        @categories={:item_categories=>@item.categories.serializable_hash(:only=>[:_id,:name,:parent_id]),:count=>@item.categories.count}.to_success
        format.json{render :json=>@categories}
        format.xml{render :xml=>@categories.to_xml(ROOT)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
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
        add_category={:item_category=>{:category_id=>@category._id,:item_id=>@item._id}}.to_success
        format.json{render :json=>add_category}
        format.xml{render :xml=>add_category.to_xml(ROOT)}
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
      if @attendee.save
        @attendee={:item_attendee=>@attendee.serializable_hash(:only=>[:_id,:first_name,:last_name])}.to_success
        format.json {render :json=>@attendee}
        format.xml {render :xml=>@attendee.to_xml(ROOT)}
      else
        format.json {render :json=>@attendee.all_errors}
        format.xml {render :xml=>failure.merge(@attendee.all_errors).to_xml(ROOT)}
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
        format.xml{render :xml=>success}
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
         @attendees={:item_attendees=>@attendees.serializable_hash(:only=>[:_id,:first_name,:last_name]),:count=>@item.attendees.count}.to_success
        format.json{render :json=>@attendees}
        format.xml{render :xml=>@attendees.to_xml(ROOT)}
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
        @item={:item_task=>@item.tasks.serializable_hash(:only=>[:description,:due_date,:_id,:is_completed],:include=>{:item=>{:only=>[:_id,:name]}})}
        format.json{ render :json=>@item}
        format.xml{ render :xml=>@item.to_xml(ROOT)}
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

  def detect_missing_params
    param_must = [:name, :template_id]
    if params.has_key?(:item) && params[:item].is_a?(Hash)
      missing_params = param_must.select { |param| !params[:item].has_key?(param.to_s) }
    else
      missing_params = param_must
    end
    render_missing_params(missing_params) unless missing_params.blank?
  end

end
