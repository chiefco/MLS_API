class PasswordsController < Devise::PasswordsController
  prepend_before_filter :require_no_authentication


  def create
    self.resource = resource_class.send_reset_password_instructions(params[resource_name])
    if successful_and_sane?(resource)    
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
  
  def update
    self.resource = resource_class.reset_password_by_token(params[resource_name])
    if resource.errors.empty?
      respond_to do |format|
        format.xml { render :xml => self.resource.reset_password_success_xml }
        format.json{ render :json=> self.resource.reset_password_success_json }
      end
    else
      respond_to do |format|
        format.xml { render :xml=> resource.all_errors.to_xml(:root=>'errors') }
        format.json { render :json=> resource.all_errors }
      end
    end
  end 
end