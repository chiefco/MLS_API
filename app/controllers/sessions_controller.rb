class SessionsController < Devise::SessionsController
  def create
    user=params[:user]
    params[:user]={}
    params[:user][:email],params[:user][:password]=user.decode_credentials if params[:user]
    resource = warden.authenticate!(:scope => resource_name)
    respond_to do |format|
      format.xml  { render :xml => resource.to_xml(:except=>USER_COLUMN) }
      format.json { render :json => resource.to_json(:except=>USER_COLUMN) }
    end
  end
end
