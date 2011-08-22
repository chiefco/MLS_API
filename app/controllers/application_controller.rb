class ApplicationController < ActionController::Base
  after_filter :clear_session
  RESET_TOKEN_SENT={:reset_token_sent=>true}
  RESET_TOKEN_ERROR={:code=>5003,:message=>"Email not found"}
  UNAUTHORIZED={:code=>1004,:message=>"Authentication/Authorization Failed"}
  USER_COLUMN=[:status,:remember_token,:remember_created_at,:created_at,:updated_at]
  #~ protect_from_forgery
  
  def authenticate_request!
    current_user=User.valid_user?(params[:access_token]) if params[:access_token]
    respond_to do |format|
      format.json{render :json=>UNAUTHORIZED}
      format.xml{render :xml=>UNAUTHORIZED,:root=>:error}
    end and return unless current_user
  end  
  
  def success
    @success={"response" => "success"}
  end

  def failure
    @failure={"response" => "failure"}
  end
  
  def suc
    {:response=>:success}
  end
  
  def fail
    {:response=>:failure}
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
  
<<<<<<< HEAD:app/controllers/application_controller.rb
  def current_user
    @current_user
=======
   #invalid parameter
   def invalid_parameter_id
    {:code=>"3065",:message=>"id -Invalid Parameter"}
>>>>>>> 137fe12bfcd2b28123798163fe2afa4bc44190df:app/controllers/application_controller.rb
  end
end
