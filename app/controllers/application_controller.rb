class ApplicationController < ActionController::Base
  after_filter :clear_session

  USER_COLUMN=[:status,:remember_token,:remember_created_at,:created_at,:updated_at]
  #~ protect_from_forgery
  def success
    @success={"response" => "success", "status" => "200"}
  end
  def clear_session
    session.clear
  end

end
