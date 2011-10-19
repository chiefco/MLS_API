class V1::SessionsController < Devise::SessionsController
  def create
    user=params[:user]
    params[:user]={}
    params[:user][:email],params[:user][:password]=user.decode_credentials if user && user.is_a?(String)
    p controller_name
    resource = warden.authenticate!(:scope => resource_name, :recall => "V1::Sessions#index")
    respond_to do |format|
      format.xml{ render_for_api :user_with_token, :xml => resource, :root => :user}
      format.json{render :json=>{:user=>resource.serializable_hash(:only=>[:_id,:authentication_token,:email,:first_name,:last_name,:job_title,:company,:sign_in_count,:last_sign_in_at,:current_sign_in_at,:date_of_birth,:last_sign_in_ip])}.merge(success)}
    end
  end
  def index
    respond_to do |format|
      format.json{render :json =>failure.merge(AUTH_FAILED)}
    end
  end
end
