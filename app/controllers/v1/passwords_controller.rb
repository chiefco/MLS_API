class V1::PasswordsController < Devise::PasswordsController
  prepend_before_filter :require_no_authentication


  def create
    pa
    self.resource = resource_class.send_reset_password_instructions(params[:user])
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
    self.resource = User.where(reset_password_token: params[:user][:reset_password_token]).first

    respond_to do |format|
      if self.resource
        if password_updated?
          self.resource.update_attribute("reset_password_token",nil)
          format.xml{ render :xml=>success, :root => :result}
          format.json{render :json=>success.to_json}
        else
          format.xml { render :xml=> self.resource.all_errors.to_xml(:root=>'errors') }
          format.json { render :json=>failure.merge(:errors=>self.resource.all_errors).to_json }
        end
      else
          format.xml { render :xml=> self.resource.all_errors.to_xml(:root=>'errors') }
          format.json { render :json=>failure.merge(:errors=>[{:code=>3070, :message=>"password reset token - Invalid Parameter"}]).to_json }
      end
    end
  end

  private

  def password_updated?
    self.resource.set_password = true
    self.resource.password = params[:user][:password] if params[:user][:password]
    self.resource.password_confirmation = params[:user][:password_confirmation] if params[:user][:password_confirmation]
    self.resource.save
  end

end