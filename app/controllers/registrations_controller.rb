class RegistrationsController < Devise::RegistrationsController

  # POST /resource
  def create
    build_resource
    if resource.save
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
