class V1::RegistrationsController < Devise::RegistrationsController
  before_filter :authenticate_v1_user!,:except=>[:create]
  before_filter :change_params,:only=>[:update,:reset_password]
  
  def index 
    paginate_options = {} 
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    if params[:sort_by] && params[:order_by]
     @users = params[:q] ? User.any_of(get_criteria(params[:q])).order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)  : User.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)
    elsif params[:sort_by] 
      @users = params[:q] ? User.any_of(get_criteria(params[:q])).order_by([params[:sort_by],:desc]).paginate(paginate_options) : User.order_by([params[:sort_by],:desc]).paginate(paginate_options) 
    else
      @users = params[:q] ? User.any_of(get_criteria(params[:q])).order_by(['created_at', :desc]).paginate(paginate_options) : User.order_by(['created_at', :desc]).paginate(paginate_options)
    end 
    respond_to do |format|
      format.xml{ render_for_api :user_with_out_token, :xml => @users, :root => :users}
      format.json{render_for_api :user_with_out_token, :json => @users, :root => :users}
    end
  end 
    
  def create
    build_resource
    saved=resource.save
    if saved
     respond_to do |format|
        format.xml{ render :xml=> success}
        format.json{render :json => success}
      end
    else
      respond_to do |format|
        format.xml { render :xml=> resource.all_errors.to_xml(:root=>'errors') }
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
        format.xml { render :xml=> resource.all_errors.to_xml(:root=>'errors') }
        format.json { render :json=> resource.all_errors }
      end
    end
  end
  
  def change_params
    params[:user]=params[:user_data]
  end
  
 
  def get_criteria(query)
    [ {first_name: query} , { last_name: query }, { email: query }, { job_title: query }, { company: query}, { business_unit: query } ]
  end 

end

