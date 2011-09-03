class V1::RegistrationsController < Devise::RegistrationsController
  before_filter :authenticate_request!,:except=>[:create]
  before_filter :change_params,:only=>[:update,:reset_password]
  before_filter :add_pagination,:only=>[:index,:get_activities]
  before_filter :detect_missing_params, :only=>[:create]
  PARAM_MUST = { :create=> [:email, :password, :password_confirmation, :first_name, :last_name] }
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
    if params.has_key?(:user) && params[:user]
      update_password=params[:user][:password] || params[:user][:password_confirmation] || params[:user][:current_password] 
      updated= update_password ? resource.update_with_password(params[resource_name]) : resource.update_without_password(params[resource_name])
      render_results(updated,resource)
    else
      render_results(true,resource)
    end 
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
    @activities = Activity.list(params,@paginate_options,@current_user)
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
  
  #detects missing parameters in users CRUD
  def detect_missing_params
    if params.has_key?(:user) && !params[:user].blank? && !['nil', 'NULL', 'null'].include?(params[:user])
      missing_params = PARAM_MUST[:create].select { |param| !params[:user].has_key?(param.to_s) }
    else
      missing_params = PARAM_MUST[:create] 
    end 
    render_missing_params(missing_params) unless missing_params.blank?
  end

end

