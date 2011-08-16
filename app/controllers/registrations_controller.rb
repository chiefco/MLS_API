class RegistrationsController < Devise::RegistrationsController

  # POST /resource
  def create
    build_resource

    if resource.save
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        respond_to do |format|
					format.html
					format.xml { render :xml=> resource }
					format.json { render :json=>resource }
				end 
      else
        set_flash_message :notice, :inactive_signed_up, :reason => resource.inactive_message.to_s if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_to do |format|
					format.html
					format.xml { render :xml=> resource }
					format.json { render :json=>resource }
				end
      end
    else
      clean_up_passwords(resource)
      respond_with_navigational(resource) { render_with_scope :new }
    end
  end

  protected

    # Build a devise resource passing in the session. Useful to move
    # temporary session data to the newly created user.
    def build_resource(hash=nil)
			super
    end

end
