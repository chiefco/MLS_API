require 'net/http'
require 'net/https'
#~ require 'rest_client'
class V1::SessionsController < Devise::SessionsController
  before_filter :get_user,:only=>[:subcribe_user,:synchronisation,:community_synchronisation]

  def create
    user=params[:user]
    params[:user]={}
    params[:user][:email],params[:user][:password]=user.decode_credentials if user && user.is_a?(String)
    resource = warden.authenticate!(:scope => resource_name, :recall => "V1::Sessions#index")

    if params[:timezone] && resource.timezone != params[:timezone]
      resource.timezone = params[:timezone]
      resource.save
    end      
    
    respond_to do |format|
      format.xml{ render :xml=>find_user(resource) ,:root => :user}
      format.json{render :json=>find_user(resource)}
    end
  end

  def index
    warden.message == :unconfirmed ? status = USER_UNCONFIRMED : status = AUTH_FAILED
    respond_to do |format|
      format.json{render :json =>failure.merge(status)}
    end
  end
  
  def subcribe_user
    response_subscription= HTTParty.post(SANBOX_URL,{ :body=>{"receipt-data" =>params[:receipt],"password" => PASSWORD}.to_json}).parse
    @receipt_value=response_subscription["receipt"]
    status=response_subscription["status"].to_i
    save_subscription(response_subscription) if status.zero?
    response_values={:status=>SUBSCRIBE[status],:subscription_type=>@user.subscription_type,:expiry_date=>@user.expiry_date.nil? ?  nil : @user.expiry_date.utc.strftime("%d/%m/%Y %H:%M:%S")}
    respond_to do |format|
      format.json {render :json=> !@user.subscription.nil? && status.zero?  ? success.merge(response_values) : failure.merge(response_values)}
    end
  end

  def find_user(resource)
    {:user=>resource.serializable_hash(:only=>[:_id,:authentication_token,:email,:first_name,:last_name,:job_title,:company,:sign_in_count,:last_sign_in_at,:current_sign_in_at,:date_of_birth,:last_sign_in_ip,:subscription_type],:methods=>[:expiry_subscription])}.merge(success)
  end

  # Perform synchronisation for the particular user
  def synchronisation
    uri = URI.parse("http://localhost:3000")
		req = Net::HTTP::Get.new("#{request.path}?".concat(request.query_string))
    @user.nil?  ? stop_synchronisation: perform_synchronisation(@user)
  end
  
  def community_synchronisation
    initialize_values;
    create_delete_communities
    get_communities
    respond_to do |format|
      format.json{render :json =>success.merge(:new_community=>@result_hash,:communities=>@communities,:comments=>@community_comments)}
    end
  end
  
  def create_delete_communities
    param=[:new,:delete,:update,:remove,:comment,:removeother,:subscribe]
    values=[:create_communities,:delete_communties,:update_communities,:remove_member,:create_comment,:remove_from_community,:subscribe_community]
    param.each_with_index do |f,i|
      unless params[:communities][i][f].nil? 
          params[:communities][i][f].each do |value|
          eval("#{values[i]}(#{value})")
        end
      end
    end
  end
  
  def delete_communties(community)
    Community.where(:_id=>community["cloud_id"]).first.update_attributes(:status=>false)
  end
  
  def get_image
    respond_to do |format|
      image=open("http://mls-staging.s3.amazonaws.com/uploads/attachment/file/4f54c6da6c6622000100000f/123.jpg") { |io| io.read }
      format.json {render :json=>success.merge({:image=>image,:type=>"jpg"})}
    end
  end
  
  private
  #perform synchronisation for the user
  def perform_synchronisation(user)
    initialize_values
    @meets= params[:user][0][:meet].each do |meet|
      unless meet.values[0].empty?
        create_or_update_meets(meet)
      end
    end
    #~ get_communities
   respond_to do |format|
      format.json{render :json =>success.merge(:synced_ids=>@synched_meets,:comments=>@comments.flatten,:ipad_ids=>@ipad_ids.uniq,:synched_page_ids=>@ipad_page_ids.uniq,:synched_pages=>@synched_pages,:share_ids=>@share_ids,:shared_hashes=>@synched_hash,:task_ids=>@task_ids,:task_hashes=>@synched_tasks,:meets=>params[:user][0][:status]=="true" ? get_meets(true) : get_meets(nil),:other_users=>CommunityUser.other_users(@user._id),:locations=>@user.locations.serializable_hash(:only=>[:_id,:name],:methods=>[:latitude_val,:longitude_val] ))}
    end
  end

  def initialize_values
    @ipad_ids=[];@ipad_page_ids=[]; @share_ids=[];@task_ids=[];@synched_meets={};@synched_pages={};
    @synched_hash={};@synched_tasks={};@comments=[];@community_comments=[];
  end

  #Invalid user- do not perform synchronisation
  def stop_synchronisation
   respond_to do |format|
      format.json{render :json =>failure.merge(AUTH_FAILED)}
    end
  end

  #Retrieves the communities for the user
  def get_communities
    @communities=Community.get_communities(@user)
  end

  #Decodes the encoded image
  def decode_image(name,encoded_image)
    File.open("#{Rails.root}/tmp/#{name}", 'wb') do|f|
      f.write(Base64.decode64("#{encoded_image}"))
    end
    @file=File.new("#{Rails.root}/tmp/#{name}")
    return @file
  end

  def  create_or_update_meets(status)
    status.values.first.each do |meet|
      if status.keys[0]=="new"
        @pages=meet[:page][:new_page]
        @shares=meet[:share]
        location=meet[:location_name]
        meet.delete(:page)
        meet.delete(:share)
        begin
          unless location.nil?
            location_meet=@user.locations.find_or_create_by(:name=>location.downcase)
            meet[:location_id]=location_meet._id unless location_meet.nil?
          end
          @meet= @user.items.create(meet)
          puts @meet.errors.inspect
          unless @meet.nil?
            @id=@meet._id
             create_or_update_share
             create_or_update_pages(@pages)
            @synched_meets=@synched_meets.merge({meet[:meet_id] =>@id.to_s})
            @ipad_ids<<meet[:meet_id]
          end
        rescue Exception => e
          puts e
        end
      elsif status.keys[0]=="delete"
        @deleted_meet=Item.where(:_id=>meet[:cloud_id]).first
        @deleted_meet.update_attributes(:status=>false) unless @deleted_meet.nil?
      else
        @meet=Item.where(:_id=>meet[:cloud_id]).first
        begin
          unless @meet.nil?
            @pages=meet[:page][:new_page]
            @shares=meet[:share]
            location=meet[:location_name]
            @updated_pages=meet[:updated_page]
            meet.delete(:updated_page)
            meet.delete(:page)
            meet.delete(:share)
            unless location.nil?
              location_meet=@user.locations.find_or_create_by(:name=>location.downcase)
              meet[:location_id]=location_meet._id unless location_meet.nil?
            end
            @meet.update_attributes(meet)
            @id=meet[:cloud_id]
            create_or_update_share
            create_or_update_pages(@pages)
            create_or_update_pages(@updated_pages,:update)
            @synched_meets=@synched_meets.merge({meet[:meet_id] =>@id.to_s})
            @ipad_ids<<meet[:meet_id]
          end
        rescue Exception=> e
          puts e
          logger.info e
        end
      end
    end
  end

  def get_meets(value)
    Item.get_meets(@user,value)
  end

def create_or_update_pages(pages,value=nil)
    @pages=pages
    unless @pages.nil?
      @pages.each do |page|
        unless page[:page_image].empty?
          if value.nil?
            @page = @meet.pages.create(:page_order => page[:page_order])
            Page.create_page_texts(page[:page_text],@page._id)
            @ipad_page_ids << page[:page_id]
            @attachment = @page.create_attachment(:attachable_type => "Page", :attachable_id => @page._id, :file => decode_image(@page._id,page[:page_image]), :size => @file.size, :attachment_type => "MEET_ATTACHMENT", :user_id => @user._id)
            comments = Comment.create_comments(@user,page[:comments],@attachment._id)
            File.delete(@file)
          else
            @attachment = Attachment.where(:_id=>page[:cloud_id]).first
            comments = Comment.create_comments(@user,page[:comments],@attachment._id)
            Page.create_page_texts(page[:page_text],@attachment.attachable._id)
            @ipad_page_ids << page[:page_id]
            @attachment.update_attributes(:file=>decode_image(ActiveSupport::SecureRandom.hex(16),page[:page_image]), :size => @file.size)
             File.delete(@file)
          end
          @comments << comments unless comments.empty? 
          @synched_pages = @synched_pages.merge({page[:page_id]=>@attachment._id,:page_texts=>@page_texts})
        end
      end
    end
  end

  def create_or_update_share
    p "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS"
   shr_files, shr_folders, shr_comm, shr_notes = [], [], [], []
    @meet.shares.where(:ipad_share=>true).map(&:community_id).map(&:to_s).uniq 
    created_shares=@shares[0][:communities].uniq-@meet.shares.where(:ipad_share=>true).map(&:community_id).map(&:to_s).uniq 
    deleted_shares=@meet.shares.where(:ipad_share=>true).map(&:community_id).map(&:to_s).uniq - @shares[0][:communities].uniq
    deleted_shares.each {|f| @meet.shares.where(:community_id=>f).first.destroy} unless deleted_shares.empty?
    created_shares.each_with_index do |f,i|
      @share=@meet.shares.create(:user_id=>@user._id,:community_id=>f,:shared_type=>"Meet",:shared_id=>@meet._id,:ipad_share=>true)
      Share.last.create_activity("SHARE_MEET",f,@meet._id)
      shr_comm << f
      shr_notes << @meet.name
      @share_ids<<@shares[1][:share_ids][i]
      @synched_hash=@synched_hash.merge({@shares[1][:share_ids][i]=>@share._id.to_s})
    end
    p "========================="
    p @share.share_files(shr_comm.uniq, shr_files.uniq, shr_folders.uniq,shr_notes.uniq, @current_user)
  end

  def create_or_update_tasks(task)
    if task.has_key?("new")
      task[:new].each do |f|
        @task=@user.tasks.create(f)
        @task_ids<<f[:task_id]
        @synched_tasks=@synched_tasks.merge(f[:task_id]=>@task._id)
      end
    else
      task[:update].each do |t|
        @task=Task.where(:_id=>t[:cloud_id]).first
        @task.update_attributes(t)
        @task_ids<<t[:task_id]
        @synched_tasks=@synched_tasks.merge(t[:task_id]=>@task._id)
      end
    end
  end
  
  def get_user
    @user=User.where(:authentication_token=>params[:access_token]).first
  end
  
  def create_communities(community)
    members="";@result_hash={};
    community["members"].each do |mem|
      members="#{members}"+",#{mem}"
    end
    community.delete("members")
    communities=@user.communities.create(:name => community["name"],:description => community["description"],:subscribe_email =>community["subscribe"])
    CommunityUser.create(:user_id=>@user._id,:community_id=>communities._id,:role_id=>1)
    @result_hash=@result_hash.merge(community["id"]=>communities._id)
    members.slice!(0)
    communities.invite(members.empty? ? "": members,@user)
  end  
  
  def update_communities(community)
    members="";
    community["members"].each do |mem|
      members="#{members}"+",#{mem}"
    end
    members.slice!(0)
    communities=get_community(community)
    communities.invite(members.empty? ? "": members,@user) unless communities.nil?
  end  
  
  def remove_member(community)
    community["members"].each do |mem|
      user=User.where(:email=>mem).first
      community=get_community(community)
      unless user.nil? || community.nil?
        community_user=CommunityUser.where(:community_id=>community._id,:user_id=>user._id).first
        value=community.shares.where(:user_id=>user._id)
        value.each {|a| a.destroy} unless value.empty?
        community_user.destroy unless community_user.nil?
      end     
      community.remove_invites(mem) if community
    end     
  end
      
  def get_community(community)
    unless community.nil?
      Community.where(:_id=>community["cloud_id"]).first
    end
  end
  
  def remove_from_community(community)
    invitations=@user.community_users.where(:user_id=>@user._id,:community_id=>community["cloud_id"]).first
     community=get_community(community)
      unless invitations.nil?
        community.activities.create(:action=>"COMMUNITY_REMOVED",:user_id=>@user._id) 
        value=community.shares.where(:user_id=>@user._id)
        value.each {|a| a.destroy} unless value.empty?
        invitations.destroy 
      end
    community.remove_invites(@user.email) if community
  end
  
  def create_comment(member)
    attachment=Attachment.where(:_id=>member["cloud_id"]).first
    comment=@user.comments.create(:commentable_type=>"Attachment",:commentable_id=>attachment._id,:message=>member["message"]) unless attachment.nil?
    @community_comments << {member["id"] => comment._id} unless comment.nil?
  end
  
  def subscribe_community(community)
    subscribe=get_community(community)
    community_user=subscribe.community_users.where(:user_id => @user._id).first
    community_user.update_attributes(:subscribe_email=>community["status"]) if subscribe
  end
  
  def save_subscription(receipt_response)
    if @user && @receipt_value
      expiry_date=Time.at(@receipt_value["purchase_date_ms"].to_i/1000) 
      @receipt_value["product_id"]=="meetlinkshareMonthly" ? @user.update_attributes(:expiry_date=>expiry_date+30.days,:subscription_type=>"monthly") : @user.update_attributes(:expiry_date=>expiry_date+365.days,:subscription_type=>"yearly")
      response_values={:product_id=>@receipt_value["product_id"],:transaction_id=>@receipt_value["transaction_id"],:receipt_details=>receipt_response}
      @user.subscription.nil? ? @user.create_subscription(response_values) :  @user.subscription.update_attributes(response_values)
    end
  end  
end
