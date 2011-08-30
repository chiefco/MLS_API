class V1::RegistrationsController < Devise::RegistrationsController
  before_filter :authenticate_request!,:except=>[:create]
  before_filter :change_params,:only=>[:update,:reset_password]
  
  def index 
    paginate_options = {} 
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    @users = User.list(params,paginate_options) 
    respond_to do |format|
      format.xml{ render_for_api :user_with_out_token, :xml => @users, :root => :users}
      format.json{render_for_api :user_with_out_token, :json => @users, :root => :users}
    end
  end 
    
  def create
    resource=User.new(params[:user])
    if resource.save
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
  
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    update_password=params[:user][:password] || params[:user][:password_confirmation] || params[:user][:current_password]
    updated= update_password ? resource.update_with_password(params[resource_name]) : resource.update_without_password(params[resource_name])
    render_results(updated,resource)
  end
  
  def update_user
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    updated= resource.update_with_password(params[resource_name])
    render_results(updated,resource)
  end
  
  def show
    respond_to do |format|
      format.xml{ render_for_api :user_with_token, :xml => current_user, :root => :user}
      format.json{render_for_api :user_with_token, :json => current_user, :root => :user}
    end
  end 
  
    #Retrieves the Activities of the User
  def get_activities
    paginate_options = {} 
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    @activities = Activity.list(params,paginate_options,@current_user) 
    p @activities.count
    respond_to do |format|
      format.json{ render :json=>{:activities=>@activities.to_json(:only=>[:_id,:description,:activity_type],:include=>{:activity=>{:only=>[:_id,:name,:description,:item_date,:is_completed,:due_date,:show_in_quick_links,:status]}})}.to_success}
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
        format.html
        format.xml { render :xml=> resource.all_errors.to_xml(:root=>:result) }
        format.json { render :json=> resource.all_errors }
      end
    end
  end
  
  def change_params
    params[:user]=params[:user_data]
  end
  
  def v1_params
    
  end

end

