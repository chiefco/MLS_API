class V1::ConfirmationsController < Devise::ConfirmationsController
  
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    if resource.errors.empty?
      resource.reset_authentication_token!  # Create the access_token after confirmation
      respond_to  do |format|
        format.json { render :json=> resource.build_confirm_success_json }
        format.xml { render :xml=> resource.build_confirm_success_xml }
      end 
    else
      respond_to  do |format|
        format.json { render :json=> resource.build_confirm_failure_json }
        format.xml { render :xml=> resource.build_confirm_failure_xml }
      end 
    end
  end
end
