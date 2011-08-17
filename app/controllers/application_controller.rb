class ApplicationController < ActionController::Base
  after_filter :clear_session

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

#~ format.xml { render :x ml => @posts }