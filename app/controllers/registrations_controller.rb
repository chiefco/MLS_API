class RegistrationsController < Devise::RegistrationsController

  # POST /resource
  def create
    build_resource
    if resource.save
      if resource.active_for_authentication?
        sign_in(resource_name, resource)
        respond_to do |format|
					format.html
					format.xml { render :xml=> resource }
					format.json { render :json=> resource }
				end 
      else
        expire_session_data_after_sign_in!
        respond_to do |format|
					format.html
					format.xml { render :xml=> resource }
					format.json { render :json=> { "response" => "success", "status" => 200, "user" => { "email" => resource.email, "first_name" => resource.first_name, "last_name" => resource.last_name }} }
				end
      end
    else
      clean_up_passwords(resource)
      respond_with_navigational(resource) { render_with_scope :new }
    end
  end
 end
