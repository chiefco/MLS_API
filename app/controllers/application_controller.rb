class ApplicationController < ActionController::Base
  USER_COLUMN=[:status,:remember_token,:remember_created_at,:created_at,:updated_at]
  protect_from_forgery
end
