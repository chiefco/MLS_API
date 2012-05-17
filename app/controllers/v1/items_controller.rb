class V1::ItemsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :get_item,:only=>([:update,:item_categories,:destroy,:item_topics,:get_all_tasks,:list_item_attendees,:comments])
  before_filter :add_pagination,:only=>[:index, :multiple_note_delete]
  before_filter :detect_missing_params, :only=>[:create]

  # GET /items
  # GET /items.xml
  def index
    @items = Item.list(params,@paginate_options,@current_user)
    @item_count = Item.list(params.merge({:item_count => true}), {}, @current_user)
    respond_to do |format|
      format.xml  { render :xml => @items}
      if params[:group_by]
        format.json {render :json =>@items.merge({:response=>:success, :count=>@item_count}).to_json}
      else
        format.json {render :json =>{:count=>@item_count, :items=>@items.to_json(:only=>[:name,:_id,:description], :methods=>[:location_name,:item_date,:end_time,:created_time,:updated_time, :template_id, :shared_teams]).parse}.merge(success)}
      end
    end
  end

  # GET /items/1
  # GET /items/1.xml
  def show
    @item = Item.find(params[:id])

    respond_to do |format|
      unless @item.status==false
        if @item
          shared_to = (@item.shares.map(&:community)).uniq
          @item = {:item => @item.serializable_hash(:only => [:_id, :name, :description, :item_date, :custom_page], :methods => [:created_time, :updated_time, :end_time, :location_name, :location_state, :location_country, :item_date, :item_date_local, :created_by, :page_count, :latitude, :longitude]),:current_category_id=>(@item.current_category_id.nil? ? "nil" : Category.find(@item.current_category_id)._id), :shared_to => shared_to.to_json(:methods => [:users_count, :shares_count]).parse}.to_success
          format.xml  { render :xml => @item.to_xml(ROOT) }
          format.json  { render :json => @item}
        else
          format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
          format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
        end
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
    respond_to do |format|
      if @template
          if @item.save
            @item={:item=>@item.serializable_hash(:only=>[:_id,:name],:methods=>[:created_time,:updated_time])}.to_success
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
      unless @item.status==false
        begin
          @item.categories.find(params[:item][:current_category_id]) if params[:item][:current_category_id]
          if params[:item][:location_name]
            @location=@current_user.locations.find_or_create_by(:name=>params[:item][:location_name].downcase)
            params[:item][:location_id]=@location._id
          end
          get_item
        if @item.update_attributes(params[:item])
          get_item
          @item={:item=>@item.to_json(:only=>[:description,:current_category_id,:end_time],:methods=>[:created_time,:updated_time,:item_date,:location_name,:item_date_local]).parse}.to_success
          format.xml  {render :xml=>@item.to_xml(ROOT)}
          format.json {render :json =>@item}
        else
          format.xml  { render :xml => @item.all_errors.to_xml(ROOT)}
          format.json {render :json =>@item.all_errors}
        end
        rescue Exception => e
          if e.message.to_s=="argument out of range" || e.message.start_with?("no")
            format.xml  { render :xml => failure.merge(INVALID_DATE).to_xml(ROOT) }
            format.json  { render :json=> failure.merge(INVALID_DATE)}
          else
            format.xml  { render :xml => failure.merge(INVALID_CATEGORY_ID).to_xml(ROOT) }
            format.json  { render :json=> failure.merge(INVALID_CATEGORY_ID)}
          end
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    respond_to do |format|
      if @item
      @item.update_attributes(:status=>false, :web_status => false)
        format.xml  { render :xml => success.to_xml(ROOT) }
        format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  # Public: Delete multiple notes
  # Returns the json result(notes status sets to false)
  def multiple_note_delete
    params[:item].each do |id|
      @item = Item.find(id)
      @item.update_attributes(:status=>false, :web_status => false)
    end
    @items = Item.list(params,@paginate_options,@current_user)
    @item_count = Item.list(params.merge({:item_count => true}), {}, @current_user)
     respond_to do |format|
      format.xml  { render :xml => @items}
      if params[:group_by]
        format.json {render :json =>@items.merge({:response=>:success, :count=>@item_count}).to_json}
      else
        format.json {render :json =>{:count=>@item_count, :items=>@items.to_json(:only=>[:name,:_id,:description], :methods=>[:location_name,:item_date,:end_time,:created_time,:updated_time, :template_id]).parse}.merge(success)}
      end
    end
  end

  # Public:  Returns the item topics
  def  item_topics
    respond_to do |format|
      if @item
      @topics=@item.topics.undeleted
        @topic={:item_topics=>@topics.to_json(:only=>[:name,:_id,:status]).parse,:count=>@topics.count}.to_success
        format.json {render :json=>@topic}
        format.xml {render :xml=>@topic.to_xml(ROOT)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: finds categories of the item
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

  # Public: Adds the category to the given item
  def item_add_category
    @item=@current_user.items.find(params[:item_category][:item_id])
    @category=@current_user.categories.find(params[:item_category][:category_id])
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

  # Public: Adds the attendee to the given item
  def item_add_attendees
    @item=@current_user.items.find(params[:item_attendee][:item_id])
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

  # Public: Removes the attendee of the item
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

  # Public: Item tasks
  def tasks
    @tasks =Task.where(:item_id=>params[:item_id]).all
    respond_to do |format|
      format.json {render :json=>{:tasks=>@tasks.as_json(:only=>[:_id,:title,:due_date,:is_completed,:description, :item_id],:include=>{:reminders => {:only => [:time]}, :item=>{:only=>[:_id,:name]}})}.to_success}
      format.xml
    end
  end

  # Public: Lists all attendees of the given item
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

  # Public: Get all tasks of the desired Item
  def get_all_tasks
    respond_to do |format|
      if @item
        @item={:item_task=>@item.tasks.serializable_hash(:only=>[:description,:due_date,:_id,:is_completed],:include=>{:item=>{:only=>[:_id,:name]}})}.to_success
        format.json{ render :json=>@item}
        format.xml{ render :xml=>@item.to_xml(ROOT)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: Lists all pages for the meet
  # params - meet id is passed
  # Returns all the pages for the meet
  def get_page
    @item = Item.find(params[:id])
    respond_to do |format|
      if @item
        params[:page] ? page = params[:page].to_i : page = 0
        pages = @item.pages
        shared_to = @item.shares.map(&:community).first
        shared_to.nil? ? share_status = false : share_status = true
        attachment = @item.share_attachments(page) rescue nil
        audio = @item.attachments.last rescue []
        comments = attachment.comments if attachment
        page_texts = pages[page].page_texts rescue []
        page_count = pages.count

        if attachment
          format.json {render :json =>  { :page => attachment.to_json(:only => [:_id, :file]).parse, :page_texts => page_texts.as_json, :comments => comments.serializable_hash(:only => [:message, :created_at, :updated_at], :methods => [:user_name]), :page_count => page_count, :share_status => share_status,:meet => @item.to_json(:only=>[:name,:_id,:description]).parse,  :audio =>audio.as_json}} 
        else
          format.json {render :json =>  {  :page_count => page_count, :meet => @item.to_json(:only=>[:name,:_id,:description]).parse}} 
        end
        # index.html.erb
        format.xml{ render :xml => attachments.to_xml(ROOT)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end  
  end

  # Public: Adds comment to the item pages
  # params - page attachment id is passed
  # Returns json result
  def add_page_comment 
    attachment = Attachment.where(:_id => params[:attachment_id]).first
    comment = attachment.comments.new(:message => params[:message], :user_id => @current_user._id, :commentable_type => "Attachment", :created_at => Time.now, :updated_at => Time.now, :community_id => params[:community_id])
    Item.delay.comment_notifications(params[:attachment_id], params[:community_id],  params[:message], @current_user)
    respond_to do |format|
      if comment.save
        format.json {render :json =>  { :comment => comment.to_a.to_json(:only => [:message, :created_at, :updated_at], :methods => [:user_name]).parse}.to_success} 
        format.xml{ render :xml=>success.to_xml(ROOT)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end    
  end

  def get_criteria(query)
    [ {name: query} , { description: query } ]
  end

  # Public: Find missing params
  def detect_missing_params
    param_must = [:name, :template_id]
    if params.has_key?(:item) && params[:item].is_a?(Hash)
      missing_params = param_must.select { |param| !params[:item].has_key?(param.to_s) }
    else
      missing_params = param_must
    end
    render_missing_params(missing_params) unless missing_params.blank?
  end

  # Public: Retrieves the Statistics of the Item
  def get_statistics
    @item=@current_user.items.find(params[:item_id])
    respond_to do |format|
      if @item
        @items = Item.stats(params,@current_user,@item)
        format.json{ render :json=>success.merge(@items).merge(item_count)}
        format.xml{ render :xml=>success.merge(@items).merge(item_count).to_xml(ROOT)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: Retrieves the Item comments
  def comments
    respond_to do |format|
      format.json {render :json=>{:comments=>@item.comments.to_a.to_json(:only=>[:_id,:message,:commentable_type,:commentable_id]).parse}.to_success}
    end
  end
  
  # Public: Find item by id and current user
  # params -  id is passed
  # Returns item
  def get_item
    @item = @current_user.items.find(params[:id])
  end

  # Public:  Returns the item_count
  def item_count
    {:count=>@items.count}
  end
  
  # Public: Failure save
  # Retruns error message
  def  failure_save
    respond_to do |format|
      format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
      format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
    end
  end
  
end
