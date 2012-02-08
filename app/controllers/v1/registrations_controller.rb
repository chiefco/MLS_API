class V1::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :authenticate_scope!
  before_filter :authenticate_request!,:except=>[:create,:options_for_the_field]
  before_filter :add_pagination,:only=>[:index,:activities]
  before_filter :detect_missing_params, :only=>[:create]

  def index
    @users = User.list(params,@paginate_options)

    respond_to do |format|
      format.xml{ render_for_api :user_with_out_token, :xml => @users, :root => :users}
      format.json{render_for_api :user_with_out_token, :json => @users, :root => :users}
    end
  end

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
  
  #Retrieves the Activities of the User
  def activities
    @item=[]
    params[:community_id] ? find_communtiy_activities(params[:community_id]) : find_activities
    @paginate_options
    @item
    respond_to do |format|
      format.json {render :json=>{:activities=>@item,:count=>@activities_count}.to_success}
    end
  end

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
            format.json {render :json =>failure}               
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

  def show
    meet_count = Item.upcoming_meetings_counts(@current_user)
    respond_to do |format|
      user = { :user => current_user.serializable_hash(:only=>[:_id, :email, :first_name, :last_name, :job_title, :company, :business_unit, :sign_in_count,:date_of_birth, :industry_id], :root=>:user), :meet_count => meet_count.to_json }
      format.json { render :json=> user.to_success }
      format.xml { render :xml=> user.to_success.to_xml(ROOT) }
    end
  end

    #~ #Retrieves the Activities of the User
  #~ def get_activities
    #~ @activities = Activity.list(params,@paginate_options,@current_user)

    #~ respond_to do |format|
      #~ format.json{ render :json=>{:activities=>@activities.to_json(:only=>[:_id,:description,:activity_type],:include=>{:activity=>{:only=>[:_id,:name,:description,:item_date,:is_completed,:due_date,:show_in_quick_links,:status]}})}.to_success}
    #~ end
  #~ end

  def close_account
    respond_to do |format|
      @current_user.update_attribute(:authentication_token,nil)
      @current_user.update_attribute(:status,false)
      format.json {render :json=>success}
      format.xml {render :xml=>success}
    end
  end
  
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
  def detect_missing_params
    param_must = [:email, :password, :password_confirmation, :first_name, :last_name]
    if params.has_key?(:user) && params[:user].is_a?(Hash)
      missing_params = param_must.select { |param| !params[:user].has_key?(param.to_s) }
    else
      missing_params = param_must
    end
    render_missing_params(missing_params) unless missing_params.blank?
  end
  
  def find_activities
    @first_name=@current_user.first_name
    activities = @current_user.activities_users
    @activities_count = activities.count
    activities.reverse.paginate(@paginate_options).each do |activity|
      if activity.entity_type=="Item" 
        @item_name=activity.entity.name
        activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
        @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>"meeting",:item_name=>@item_name}})
        @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
      end
      if activity.entity_type=="Category" 
        @category_name=activity.entity.name
        activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
        @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>@category_name,:item_name=>'nil'}})
        @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
      end
      if activity.entity_type=="Folder" 
        @folder_name=activity.entity.name
        activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
        @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>"folder",:item_name=>@folder_name}})
        @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
      end
      if activity.entity_type=="Bookmark" 
        @bookmark_name=activity.entity.name
        activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
        @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>@bookmark_name,:item_name=>'nil'}})
        @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
      end
      if activity.entity_type=="Attachment" 
        @attachment_name=activity.entity.file_name
        activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
        @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>@attachment_name,:item_name=>'nil'}})
        @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
      end
      if activity.entity_type=="Community" 
        @community_name=activity.entity.name
        if activity.shared_id.nil? 
        @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>@community_name,:item_name=>'nil'}})
         activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
        @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
        else 
          if activity.action == "SHARE_MEET"
            @item_name = Item.find "#{activity.shared_id}"
            activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
            @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>@community_name,:item_name=>@item_name.name}})
            @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
          elsif activity.action == "SHARE_ATTACHMENT"
              
                @attachment_name = Attachment.find (activity.shared_id)
                activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
                @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>@community_name,:item_name=>@attachment_name.file_name}})
                @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
          elsif activity.action =="COMMUNITY_JOINED" 
              @invitation=Invitation.find(activity.shared_id)
              @username = User.where(:email => @invitation.email).first.first_name rescue ''
              activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
              @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@username ,:item=>'Community',:item_name=>@community_name}})
               @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
          end
        end   
      end
    end
    #find_category_ids;insert_items;
  end
  
  def find_communtiy_activities(community_id)
    @community = Community.find(community_id)
    activities = @community.activities
    @activities_count = activities.count
    @community_name=@community.name
    activities.reverse.paginate(@paginate_options).each do |activity|
     @first_name= User.find(activity['user_id']).first_name
      if activity.entity_type=="Community"             
        if activity.shared_id.nil? 
        @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>@community_name,:item_name=>'nil'}})
        activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
        @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}",  :date=> activity_date }
        else 
            if activity.action == "SHARE_MEET"
              @item_name = Item.find "#{activity.shared_id}"
              activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
              @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>@community_name,:item_name=>@item_name.name}})
              @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
            elsif activity.action == "SHARE_ATTACHMENT"
                @attachment_name = Attachment.find (activity.shared_id)
                activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
                @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>@community_name,:item_name=>@attachment_name.file_name}})
                @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }             
            elsif activity.action =="COMMUNITY_JOINED" 
              @invitation=Invitation.find(activity.shared_id)
              @username = User.where(:email => @invitation.email).first.first_name rescue ''
              activity_date = (activity.updated_at).to_time.strftime("%d/%m/%Y") rescue ''
              @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@username ,:item=>'Community',:item_name=>@community_name}})
               @item<<{:id=>activity.entity._id,:type=>activity.entity_type,:message=>"#{@activities[activity.action]}", :date=>activity_date }
            end
        end     
      end      
    end
  end
  
  #~ def find_category_ids
    #~ @categories=[]
    #~ @current_user.activities_users.where(:action=>CATEGORY_ADDED_ITEM).each do |category|
      #~ @categories<<category.entity if !@categories.include?(category.entity)
    #~ end
  #~ end
  #~ def insert_items
    #~ @categories.each do |category|
     #~ category.item_ids.uniq.each do |item|
        #~ @activities=Yamler.load("#{Rails.root.to_s}/config/activities.yml", {:locals => {:username =>@first_name ,:item=>find_the_item(item),:item_name=>category.name}})
        #~ @item<<{:id=>category._id,:type=>"Category",:message=>"#{@activities[CATEGORY_ADDED_ITEM]}" }
      #~ end
    #~ end
  #~ end
  
  def find_the_item(item)
    @activity_item=Item.where(:_id=>item).first
    @activity_item=@activity_item.nil? ? "nil" : @activity_item.name
  end
end

