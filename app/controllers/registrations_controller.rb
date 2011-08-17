class RegistrationsController < Devise::RegistrationsController
  self.responder = ActsAsApi::Responder
  respond_to :json, :xml
  def create
    build_resource
    if resource.save
      expire_session_data_after_sign_in!
      respond_to do |format|
        format.html
        format.xml{ render_for_api :user_with_token, :xml => resource, :root => :user}
        format.json{render_for_api :user_with_token, :json => resource, :root => :user}
      end
    else
      clean_up_passwords(resource)
      respond_to do |format|
        format.html
        format.xml { render :xml=> resource.all_errors.to_xml(:root=>'errors') }
        format.json { render :json=> resource.all_errors }
      end 
    end
  end
end

