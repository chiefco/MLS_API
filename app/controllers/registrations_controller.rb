class RegistrationsController < Devise::RegistrationsController
  self.responder = ActsAsApi::Responder
  respond_to :json, :xml
  def create
    build_resource
    if resource.save
<<<<<<< HEAD:app/controllers/registrations_controller.rb
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
=======
			expire_session_data_after_sign_in!
			respond_to do |format|
				format.xml { render :xml=> resource.build_user_create_success_xml}
				format.json { render :json=> resource.build_user_create_success_json }
			end
    else
      clean_up_passwords(resource)
      respond_to do |format|
					format.xml { render :xml=> resource.all_errors.to_xml(:root=>'errors') }
					format.json { render :json=> resource.all_errors }
				end 
    end
  end
	
 end
>>>>>>> 265356fa5b51583018af6eedb880a00117dcf49d:app/controllers/registrations_controller.rb
