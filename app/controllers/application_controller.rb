class ApplicationController < ActionController::Base
  after_filter :clear_session
  RESET_TOKEN_SENT={:reset_token_sent=>true}
  RESET_TOKEN_ERROR={:reset_token_sent=>false}
  USER_COLUMN=[:status,:remember_token,:remember_created_at,:created_at,:updated_at]
  #~ protect_from_forgery
  def success
    @success={"response" => "success"}
  end

  def failure
    @failure={"response" => "failure"}
  end
  
  def clear_session
    session.clear
  end
end
