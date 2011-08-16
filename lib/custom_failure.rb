class CustomFailure < Devise::FailureApp
  def http_auth_body
    return i18n_message unless request_format
    method = "to_#{request_format}"
    if method == "to_xml"
      { :error => i18n_message }.to_xml(:root => "errors")
    elsif {}.respond_to?(method)
      { :errors => i18n_message }.send(method)
    else
      i18n_message
    end
  end
  
  protected
  def i18n_message(default = nil)
    message = warden.message || warden_options[:message] || default || :unauthenticated
    if message.is_a?(Symbol)
      I18n.t(:"#{scope}.#{message}", :resource_name => scope,:scope => "devise.failure", :default => [message, message.to_s])
    else
      message.to_s
    end
  end
end