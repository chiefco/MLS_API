class ApplicationController < ActionController::Base
  after_filter :clear_session
  RESET_TOKEN_SENT={:reset_token_sent=>true}
  RESET_TOKEN_ERROR={:code=>5003,:message=>"Email not found"}
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
  def set_page_size
    if params[:page_size]
      params[:page_size]
    else
      10
    end 
  end 

  def set_page
    if params[:page]
      params[:page]
    else
      1
    end 
  end 
  
   #invalid parameter
   def invalid_parameter_id
    {:code=>"3065",:message=>"id -Invalid Parameter"}
  end
end
