require 'net/http'
require 'net/https'
require 'rest_client'
class V1::SessionsController < Devise::SessionsController
  
  def create
    user=params[:user]
    params[:user]={}
    params[:user][:email],params[:user][:password]=user.decode_credentials if user && user.is_a?(String)
    p controller_name
    resource = warden.authenticate!(:scope => resource_name, :recall => "V1::Sessions#index")
    respond_to do |format|
      format.xml{ render :xml=>find_user(resource) ,:root => :user}
      format.json{render :json=>find_user(resource)}
    end
  end
  
  def index
    respond_to do |format|
      format.json{render :json =>failure.merge(AUTH_FAILED)}
    end
  end
  
  def find_user(resource)
    {:user=>resource.serializable_hash(:only=>[:_id,:authentication_token,:email,:first_name,:last_name,:job_title,:company,:sign_in_count,:last_sign_in_at,:current_sign_in_at,:date_of_birth,:last_sign_in_ip])}.merge(success)
  end
  
  # Perform synchronisation for the particular user
  def synchronisation
    uri = URI.parse("http://localhost:3000")
		req = Net::HTTP::Get.new("#{request.path}?".concat(request.query_string))
    @user=User.where(:authentication_token=>params[:access_token]).first
    @user.nil?  ? stop_synchronisation: perform_synchronisation(@user) 
  end
  
  private
  #perform synchronisation for the user
  def perform_synchronisation(user)
    @meets=params[:meet].first[:new]  
    @synched_meets={}
    @ipad_ids=[]
    @meets.each do |meet|
     created_meet= user.items.create(meet)
     @synched_meets=@synched_meets.merge({created_meet.meet_id => created_meet._id.to_s})
     @ipad_ids<<created_meet.meet_id
   end
   respond_to do |format|
      format.json{render :json =>success.merge(:synced_ids=>[@synched_meets],:ipad_ids=>@ipad_ids)}
    end
  end
  
  #Invalid user- do not perform synchronisation
  def stop_synchronisation
   respond_to do |format|
      format.json{render :json =>failure.merge(AUTH_FAILED)}
    end
  end
end
