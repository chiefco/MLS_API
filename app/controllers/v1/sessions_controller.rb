class V1::SessionsController < Devise::SessionsController
  def create
    user=params[:user]
    params[:user]={}
    params[:user][:email],params[:user][:password]=user.decode_credentials if user && user.is_a?(String)
    resource = warden.authenticate!(:scope => resource_name)
    respond_to do |format|
      format.xml{ render_for_api :user_with_token, :xml => resource, :root => :user}
      format.json{render_for_api :user_with_token, :json => resource, :root => :user}
    end
  end
end
