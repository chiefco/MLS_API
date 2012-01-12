require 'net/http'
require 'net/https'
#~ require 'rest_client'
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
    @ipad_page_ids=[]
    @synched_pages={}
    @meets.each do |meet|
      @pages=meet[:page]
      @meets.delete(:page)
     created_meet= user.items.create(meet)
     unless @pages.nil?
       @pages.each do |page|
          unless page[:page_image].empty?
            @page=created_meet.pages.create(:page_order=>page[:page_order])
            @ipad_page_ids<<page[:page_id]
            @attachment=@page.create_attachment(:attachable_type=>"Page",:attachable_id=>@page.id,:file=>decode_image(@page._id,page[:page_image]))
            @synched_pages=@synched_pages.merge({page[:page_id]=>@attachment._id})
          end
        end
      end
     @synched_meets=@synched_meets.merge({created_meet.meet_id => created_meet._id.to_s})
     @ipad_ids<<created_meet.meet_id
   end
   get_communities(@user)
   respond_to do |format|
      format.json{render :json =>success.merge(:synced_ids=>@synched_meets,:ipad_ids=>@ipad_ids,:communities=>@communities,:synched_page_ids=>@ipad_page_ids,:synched_pages=>@synched_pages)}
    end
  end
  
  #Invalid user- do not perform synchronisation
  def stop_synchronisation
   respond_to do |format|
      format.json{render :json =>failure.merge(AUTH_FAILED)}
    end
  end
  
  #Retrieves the communities for the user
  def get_communities(user)
    @communities=Community.get_communities(user)
  end
  
  #Decodes the encoded image 
  def decode_image(name,encoded_image)
    File.open("#{Rails.root}/tmp/#{name}", 'wb') do|f|
      f.write(Base64.decode64("#{encoded_image}"))
    end 
    @file=File.new("#{Rails.root}/tmp/#{name}")
    return @file
  end
  
end
