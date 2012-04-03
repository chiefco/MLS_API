class V1::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :authenticate_scope!
  before_filter :authenticate_request!,:except=>[:create,:options_for_the_field]
  before_filter :add_pagination,:only=>[:index,:activities]
  before_filter :detect_missing_params, :only=>[:create]

  # Public: Lists all the users in the application
  #
  # params - user params are passed
  # @paginate_options - accepts page size and page no
  #
  # Returns all the users
  def index
    @users = User.list(params,@paginate_options)

    respond_to do |format|
      format.xml{ render_for_api :user_with_out_token, :xml => @users, :root => :users}
      format.json{render_for_api :user_with_out_token, :json => @users, :root => :users}
    end
  end

  # Public: Creates a new user
  # params[:user] - user params are passed
  # Returns boolean result
  def create
    resource=User.new(params[:user])
    if resource.save
        CommunityUser.create(:user_id=>resource._id,:community_id=>params[:community][:id],:role_id=>1) if params[:community] && params[:community][:email] == params[:user][:email]
     respond_to do |format|
        format.xml{ render :xml=> success}
        format.json{render :json => success}
      end
    else
      respond_to do |format|
        format.xml { render :xml=> resource.all_errors.to_xml(:root=>:result) }
        format.json { render :json=> resource.all_errors }
      end
    end
  end

  # Public: Lists all the user and community activities
  # params[:community_id]  - Returns community activity if passed
  # Returns the user & community activities
  def activities
    @item=[]
    params[:community_id] ? find_communtiy_activities(params[:community_id]) : find_activities
    respond_to do |format|
      format.json {render :json=>{:activities => @item, :count => @activities_count, :todays_activities => @current_user.activities_users.todays_activities.count}.to_success}
    end
  end

  # Public: Updates the user information
  # params[:user]  - Updated user params should be passed
  # Returns the boolean result
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    if params.has_key?(:user) && params[:user]
      if params[:user][:password] || params[:user][:password_confirmation] || params[:user][:current_password]
        resource.set_password = true
        updated = resource.update_with_password(params[resource_name])
        respond_to do |format|
          if updated
              format.json{render :json=>success  }
              format.xml{render :xml=>success.to_xml(ROOT) }
          else
            format.xml  { render :xml => failure.to_xml(ROOT)}
            format.json {render :json => resource.all_errors}
          end
        end
      else
        updated = resource.update_without_password(params[resource_name])
        respond_to do |format|
          if updated
            format.json{render :json=>success  }
            format.xml{render :xml=>success.to_xml(ROOT) }
          end
        end
      end

    else
      render_results(true,resource)
    end
  end

  # Public: Displays current user information
  # Returns the json result with current user info
  def show
    meet_count = Item.upcoming_meetings_counts(@current_user)
    respond_to do |format|
      user = { :user => current_user.serializable_hash(:only=>[:_id, :email, :first_name, :last_name, :job_title, :company, :business_unit, :sign_in_count,:date_of_birth, :industry_id], :root=>:user), :meet_count => meet_count.to_json }
      format.json { render :json=> user.to_success }
      format.xml { render :xml=> user.to_success.to_xml(ROOT) }
    end
  end

  # Public: Deletes current user from app
  # Returns the json result(currnt user status sets to false)
  def close_account
    respond_to do |format|
      @current_user.update_attribute(:authentication_token,nil)
      @current_user.update_attribute(:status,false)
      format.json {render :json=>success}
      format.xml {render :xml=>success}
    end
  end

  # Public: Returns industries present in app
  # Returns the json result
   def options_for_the_field
    @industry=Industry.all
      respond_to do |format|
      format.json { render :json=>{:industry=>@industry.to_json(:only=>[:_id,:name]).parse}.merge(success)}
    end
  end

  private

  def render_results(valid,resource)
    if valid
     respond_to do |format|
        format.html
        format.xml{ render_for_api :user_with_token, :xml => resource, :root => :user}
        format.json{render_for_api :user_with_token, :json => resource, :root => :user}
      end
    else
      respond_to do |format|
        format.xml { render :xml=> resource.all_errors.to_xml(:root=>:result) }
        format.json { render :json=> resource.all_errors }
      end
    end
  end

  #detects missing parameters in users create
  #Called on 'before_filter' for create(only)
  def detect_missing_params
    param_must = [:email, :password, :password_confirmation, :first_name, :last_name]
    if params.has_key?(:user) && params[:user].is_a?(Hash)
      missing_params = param_must.select { |param| !params[:user].has_key?(param.to_s) }
    else
      missing_params = param_must
    end
    render_missing_params(missing_params) unless missing_params.blank?
  end

  # Public: Logic to return all user activities  
  # Called from method 'activities' 
  # Returns the user activities
  def find_activities
    @first_name=@current_user.first_name
    user_communities = @current_user.communities.map(&:id)
    activities = (@current_user.activities_users + Activity.any_in(:entity_id => user_communities)).sort{|a, b| a.created_at <=> b.created_at}
    @activities_count = activities.count

    activities.reverse.paginate(@paginate_options).each do |activity|
      get_activities(activity)
    end
  end

  # Public: Logic to return all community activities 
  # Called from method 'activities' 
  # Returns the community activities
  def find_communtiy_activities(community_id)
    @community = Community.find(community_id)
    activities = @community.activities
    @activities_count = activities.count
    @community_name = @community.name
    activities.reverse.paginate(@paginate_options).each do |activity|
     @first_name= User.find(activity['user_id']).first_name
      if activity.entity_type=="Community"
        if activity.shared_id.nil?
          get_activity(activity, @community_name, 'nil')
        else
          case activity.action
          when "SHARE_MEET"
            @item_name = Item.find "#{activity.shared_id}"
            get_activity(activity, @community_name, @item_name.name)
          when "SHARE_ATTACHMENT"
            @attachment = Attachment.where(:_id => activity.shared_id).first
            @attachment_name = @attachment.file_name rescue ''
            get_activity(activity, @community_name, @attachment_name) 
          when "COMMUNITY_JOINED"           
            @invitation=Invitation.where(:_id=>activity.shared_id).first
            @username = User.where(:email => @invitation.email).first.first_name rescue ''
            get_activity(activity, 'community', @community_name)            
          end
        end
      end
    end
  end  

  # Public: Fetches user activities(activities fetch logic) 
  # Called from methods 'find_activities'
  # Returns the user activities
  def get_activities(activity)
    case activity.entity_type
    when "Item"
      @item_name=activity.entity.name
      get_activity(activity, "note", @item_name)
    when "Category"
      @category_name=activity.entity.name
      get_activity(activity, @category_name, 'nil') 
    when "Comment"
      comment=Comment.where(:_id=>activity.entity_id).first
      username = comment.user.first_name rescue '' 
      values=comment.commentable.attachable unless comment.nil?
      get_activity(activity, values.page_order, values.item.name) if values.class==Page
    when "Folder"
      @folder_name=activity.entity.name
      get_activity(activity, "folder", @folder_name)          
    when "Bookmark"
      @bookmark_name=activity.entity.name
      get_activity(activity, @bookmark_name, 'nil')                    
    when "Attachment"
      begin
        @attachment_name=activity.entity.file_name
        get_activity(activity, @attachment_name, 'nil')                                
      rescue
     end
    when "Community"
      @community = activity.entity
      @first_name = User.find(activity['user_id']).first_name
      get_community_activities(activity)     
    end
  end

  # Public: Fetches community activities(activities fetch logic) 
  # Called from methods 'find_community_activities'
  # Returns the community activities
  def get_community_activities(activity)  
    if activity.shared_id.nil?
      get_activity(activity, @community.name, 'nil')                                
    else
      case activity.action
        when "COMMUNITY_REMOVED"
        get_activity(activity, community.user.first_name , 'nil')  
        when "SHARE_MEET"
        @item_name = Item.find "#{activity.shared_id}"              
        get_activity(activity, @community.name, @item_name.name)                       
        when "SHARE_ATTACHMENT"
        @attachment = Attachment.where(:_id => activity.shared_id).first
        @attachment_name = @attachment.file_name rescue ''
        get_activity(activity, @community.name, @attachment_name)               
        when "COMMUNITY_JOINED"
        @invitation=Invitation.where(:_id=>activity.shared_id).first
        @first_name = User.where(:email => @invitation.email).first.first_name rescue ''
        get_activity(activity, 'community', @community.name) if !@first_name.blank?
      end
    end 
  end

  # Public: Fetches single activity 
  # Called fron methods 'find_activities', 'find_community_activities'
  # Returns the community activities
  def get_activity(activity, item, item_name)
    activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
    @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name, :item=>item, :item_name=>item_name}})
    @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:type_id=>activity.entity_id,:message=>"#{@activities[activity.action]}", :date=>activity_date }    
  end   

  #returns the item if provided
  def find_the_item(item)
    @activity_item=Item.where(:_id=>item).first
    @activity_item=@activity_item.nil? ? "nil" : @activity_item.name
  end
end