class ApplicationController < ActionController::Base
  after_filter :clear_session

  USER_COLUMN=[:status,:remember_token,:remember_created_at,:created_at,:updated_at]
  #~ protect_from_forgery


  def clear_session
    session.clear
  end

end
