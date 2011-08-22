class V1::PasswordsController < Devise::PasswordsController
  prepend_before_filter :require_no_authentication


  def create
    self.resource = resource_class.send_reset_password_instructions(params[resource_name])
    if successful_and_sane?(resource)    
      success_message=success.merge(RESET_TOKEN_SENT)
      respond_to do |format|
        format.xml{ render :xml=>success_message, :root => :result}
        format.json{render :json=>success_message.to_json}
      end
    else
      failure_message=failure.merge(RESET_TOKEN_ERROR)
      respond_to do |format|
        format.xml{ render :xml=>failure_message, :root => :errors}
        format.json{render :json=>failure_message.to_json,:root => :errors}
      end
    end    
  end
  
  def update
    self.resource = resource_class.reset_password_by_token(params[resource_name])
    if self.resource.errors.empty?
      respond_to do |format|
        format.xml{ render :xml=>success, :root => :result}
        format.json{render :json=>success.to_json}
      end
    else
      respond_to do |format|
        format.xml { render :xml=> self.resource.all_errors.to_xml(:root=>'errors') }
        format.json { render :json=> self.resource.all_errors }
      end
    end
  end

end