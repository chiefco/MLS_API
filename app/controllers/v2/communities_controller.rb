class V2::CommunitiesController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_community,:only=>[:update,:show,:destroy,:members,:invite_member,:validate_folder,:validate_file, :subscribe_status]
  before_filter :find_community_members,:only=>[:members]
  before_filter :add_pagination,:only=>[:index]
  before_filter :detect_missing_params, :only=>[:create]
  before_filter :check_authorised_mem, :only=>[:show]
  before_filter :check_subscribed_user, :only=>[:create]

    
  # Public: Lists all the communities, shared communities, list the community users and invited users
  #
  # params - community params are passed
  #
  # Returns the json result with current user community list, shared comunity with shares count and members count
   def index
    communities = @current_user.communities.undeleted
    @current_user.subscription_type == "free" ? subscribed_user = false : subscribed_user = true
    shared_communities = CommunityUser.shared_communities(@current_user)
    invited_members =  (@current_user.contacts.map(&:email) - [@current_user.email]).uniq
    mls_users = User.invited_members_with_field(invited_members)
    users_email = User.invited_members_email(invited_members).map(&:email)
    other_members    = invited_members - users_email

    respond_to do |format|
      format.json {render :json =>  {:communities => communities.to_json(:methods => [:users_count, :shares_count, :unread_notifications]).parse, :invited_members => invited_members.to_json.parse, :mls_users => mls_users.to_json(:methods => [:user_info]).parse, :other_members => other_members.to_json.parse, :shared_communities => shared_communities.to_json(:methods => [:users_count, :shares_count]).parse, :subscribed_user => subscribed_user}} # index.html.erb
    end 
  end
  
  # Public: Displays community information
  # Returns the json result with community info
  def show
    if @authoriesd_mem
      notification = @community.notifications.where(:user_id => @current_user._id).first
      notification ? notification.update_attributes(:last_viewed => Time.now) : @community.notifications.create(:user_id => @current_user._id, :last_viewed => Time.now)
      @attachments, @items = [], []
      shares = @community.shares.order_by(:created_at.desc)
      items = shares.select{|i| i.shared_type == 'Meet'}.map(&:item).uniq.reject{|v| v.status==false}
      folders = @community.folders.comm_folders
      attachments_count = @community.attachments.total_attachments.count
      community_owner = @community.community_users.select{|i| i.user_id == @community.user_id && i.status == true}.map(&:user)
      users = (@community.community_users.undeleted.map(&:user) - community_owner).uniq
      invitees = ((@community.invitations.unused.map(&:email) + @community.community_invitees.map(&:email)) - @community.community_users.undeleted.map(&:user).map(&:email)).uniq 
      invited_mls_users = User.invited_members_with_field(invitees)
      users_email = User.invited_members_email(invitees).map(&:email)
      invited_other_members  = invitees - users_email
    
      @community_user = @community.community_users.where(:user_id => @current_user._id).first

      respond_to do |format|
        if @community.status!=false
          format.json  {render :json => {:community => @community.serializable_hash(:only=>[:_id,:name,:description]), :invitees => invitees.to_json.parse, :items => items.to_json(:only=>[:name,:_id,:description], :methods=>[:location_name,:item_date,:end_time,:created_time,:updated_time, :template_id, :audio_count]).parse, :community_attachments => @community.attachments.current_version.to_json(:only=>[:_id, :file_name, :file_type, :size, :user_id, :folder_id, :content_type,:file,:created_at], :methods => [:user_name, :has_revision]).parse, :attachments_count => attachments_count, :folder_share => folders.to_json(:methods => [:user_name]).parse,  :users => users.to_json(:only=>[:_id, :first_name, :last_name, :email, :company, :job_titile, :industry_id], :methods => [:user_info]).parse, :community_owner => community_owner.to_json(:only=>[:_id, :first_name, :last_name, :email]).parse, :subscribe_email =>@community_user.to_json(:only => [:subscribe_email]).parse, :invited_mls_users => invited_mls_users.to_json(:only=>[:_id, :first_name, :last_name, :email, :company, :job_titile, :industry_id], :methods => [:user_info]).parse, :invited_other_members => invited_other_members.to_json.parse}.to_success}
        else
          format.json  {render :json=> failure.merge(INVALID_PARAMETER_ID)}
        end
      end
    else
       respond_to do |format|
          format.json{render :json=>{:message=>'Your are not a authorised person to view team'}.to_failure}
       end
    end
  end 
  
  # Public: Creates a new community
  # params[:community] - community params are passed
  # Returns json of communtiy
  def create  
    if @subscribed_user    
        @community = @current_user.communities.new(params[:community])    
        respond_to do |format|
          if @community.save
            if !params[:invite_email].nil?
              @community.invite(params[:invite_email][:users], @current_user) unless params[:invite_email][:users].blank? unless params[:invite_email][:users].blank?
            end
            CommunityUser.create(:user_id=>@current_user._id,:community_id=>@community._id,:subscribe_email => params[:subscribe_email], :role_id=>1)
            find_parameters
            format.json {render :json => @community}
          else
            format.json {render :json => @community.all_errors}
          end
        end
    else
       respond_to do |format|
          format.json{render :json=>{:message=>'Your are not a subscribed user to create new team'}.to_failure}
       end
    end
  end
  
  # Public: Updates the community information
  # params[:user]  - Updated community params should be passed
  # Returns the boolean result
  def update
    respond_to do |format|
      if @community.status!=false
        if @community.update_attributes(params[:community])
          find_parameters
          format.json {render :json => @community}
        else
          format.json  { render :json =>@community.all_errors}
        end
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  # Public: Delete communtiy
  # Returns the json result(communtiy status sets to false)
  def destroy
    @community.update_attributes(:status=>false)
    respond_to do |format|
      format.json {render :json=>success }
    end
  end
  
  # Public: Delete multiple communtiy
  # Returns the json result(communtiy status sets to false)
  def multiple_delete
    params[:community].each do |com_id|
      @community = Community.by_id(com_id).first
      @community.update_attributes(:status=>false)
    end
    @community_user = CommunityUser.by_user_id(@current_user._id)
    @communities=[]
    @community_user.each do |com_user|
      com = Community.active_community_by_id(com_user.community_id).first
      @communities<< {:id =>com.id, :name=>com.name,:members=>com.community_users.count,:shares=>com.shares.count, :status => com.status} if com
    end
    respond_to do |format|
      format.json {render :json => {:community =>@communities}.to_success} # index.html.erb
    end
  end

  # Public: Invitation is sent to the member
  # Returns the json result
  def invite_member
    @invitation=@community.invitations.new(params[:invite_member])
    respond_to do |format|
      if @invitation.save
        Invite.community_invite(@current_user.first_name,@invitation,@community.name).deliver
        format.json {render :json=>@invitation}
      else
        format.json  { render :json =>@invitation.all_errors}
      end
    end
  end

  #Public: Retrieves members of the given community
  def members
    respond_to do |format|
      format.json{render :json=>{:members=>@community.members}.to_success}
      format.xml{render :xml=>{:members=>@community.members}.to_success.to_xml(:root=>:result)}
    end
  end

  #Remove single member
  def remove_member
    respond_to do |format|
      @community_user=CommunityUser.by_user_id_and_community_id(params[:remove_member][:user_id], params[:remove_member][:community_id] ).first
      unless @community_user.nil?
        @community_user.update_attributes(:status=>false)
        format.json {render :json=>success}
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  # Public: Remove multiple member
  def multiple_member_delete
    community = Community.by_id(params[:community_id]).first

    #To remove community members
    if params[:user_id]
      community_users = community.community_users.by_user_ids(params[:user_id]).destroy_all
      invitations = community.invitations.by_user_ids(params[:user_id]).update_all(:invitation_token => nil)
      Community.delay.send_notifications(params[:user_id], params[:community_id], @current_user)    
    end

    #To remove invited members
    if params[:invited_ids]
      community_users = community.community_invitees.by_emails(params[:invited_ids]).destroy_all
      invitations = community.invitations.by_emails(params[:invited_ids]).update_all(:invitation_token => nil)
    end

    respond_to do |format|
      if community_users
        format.json {render :json=>success}
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  # Public: Remove multiple shared team
  def remove_shared_team
    respond_to do |format|
      @community_user = CommunityUser.by_community_ids(params[:community_id]).by_user_id(@current_user._id).delete_all
      Community.delay.shared_unsubscribe(params[:community_id], @current_user)
      unless @community_user.nil?
        format.json {render :json=>success}
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: Change the role of the CommunityUser
  def change_role
    respond_to do |format|
      @community_user=CommunityUser.by_user_id_and_community_id(params[:change_role][:user_id], params[:change_role][:community_id]).first
      if @community_user
        if @community_user.community.user_id==@current_user._id
          @community_user.update_attributes(:role_id=>params[:change_role][:role_id].nil? ? '0' : params[:change_role][:role_id])
          format.json  { render :json=> success}
        else
          format.json  { render :json=> failure.merge(ADMIN_PREVILEGE)}
        end
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: Invitation accepted logic
  def accept_invitation
    respond_to do |format|
      @invitation = Invitation.where(:invitation_token=>params[:accept_invitation]).first
      unless @invitation.nil?
        if @invitation.user.nil?
          format.json {render :json => failure.merge({:message => 'Something went wrong'})}
        elsif @invitation.user_id != @current_user.id
          format.json {render :json => failure.merge({:message => 'Please login with the invited user to join the community'})}
        else
            exist_user = @invitation.community.community_users.by_user_id(@invitation.user_id).first
           if exist_user.nil? || exist_user.blank?
              @invitation.community.community_users.create(:user_id=>@invitation.user_id, :subscribe_email => true)
              @invitation.update_attributes(:invitation_token=>nil)
              @community = @invitation.community
              @community.save_Invitation_activity("COMMUNITY_JOINED", @community._id, @invitation._id, @current_user._id)
              @community.delay.confirm_notifications(@community._id, @community.name, @current_user)
              format.json {render :json => {:community => @invitation.community.to_json(:only => [:_id, :name]).parse}.to_success}
            else
              @invitation.update_attributes(:invitation_token=>nil)
              format.json {render :json => failure.merge({:message => 'Already you have joined this team'})}
            end
        end
      else
        format.json {render :json => failure.merge({:message => 'Invitation already used'})}
      end
    end
  end

  # Public: validated the community params
  def detect_missing_params
    param_must = [:name]
    if params.has_key?(:community) && params[:community].is_a?(Hash)
      missing_params = param_must.select { |param| !params[:community].has_key?(param.to_s) }
    else
      missing_params = param_must
    end
    render_missing_params(missing_params) unless missing_params.blank?
  end

  # Public: Invitation logic when called from community
  def invite_from_community
    @community = Community.by_id(params[:invite_email]['community']).first
    @community.invite(params[:invite_email]['users'], @current_user, params[:invite_email]['message']) if params[:invite_email]['users'] != 'use comma separated emails'
    respond_to do |format|
      format.json {render :json => success }
    end
  end

  # Public: Removing member from community
  def member_delete
    community_user = CommunityUser.by_user_id_and_community_id(params[:id], params[:community_id]).first
    respond_to do |format|
      if community_user.delete
        format.json  { render :json => success}
      else
        format.json  { render :json => failure}
      end
    end
  end

  # Public: Folder validation for unique name
  def validate_folder
    if @community
      folder = Folder.find(params[:folder_id])
      respond_to do |format|
        if @community.folders.include?(folder)
          format.json  { render :json => { :message=>"The folder already exist", :folder => folder.to_json(:only => [:_id, :name, :parent_id, :created_at, :updated_at],:methods => [:user_name]).parse}.to_failure }
          format.xml { render :xml=> failure.to_xml(ROOT) }
        else
          format.json { render :json=> {:success => {:message=>"The folder doesn't exist"}}.to_success }
          format.xml { render :xml=> {:message => "The folder doesn't exist"}.to_success.to_xml(ROOT) }
        end
      end
    else
      respond_to do |format|
        format.json  { render :json => { :message=>"Community doesn't exist"}.to_failure }
        format.xml { render :xml=> failure.to_xml(ROOT) }
      end      
    end
  end

  # Public: File validation for unique name
  def validate_file
    if @community
      attachment = Attachment.where(:file_name => "#{params[:file_name]}", :folder_id => params[:folder_id], :is_current_version => true).first
      respond_to do |format|
        if @community.attachments.include?(attachment)
          format.json  { render :json => { :message=>"The file already exist", :attachment => attachment.to_json(:only=>[:_id, :file_name, :file_type, :size, :user_id, :content_type,:file,:created_at], :methods => [:user_name, :has_revision]).parse}.to_failure }
          format.xml { render :xml=> failure.to_xml(ROOT) }
        else
          format.json { render :json=> {:success => {:message=>"The folder doesn't exist"}}.to_success }
          format.xml { render :xml=> {:message => "The folder doesn't exist"}.to_success.to_xml(ROOT) }
        end
      end
    else
      respond_to do |format|
        format.json  { render :json => { :message=>"Community doesn't exist"}.to_failure }
        format.xml { render :xml=> failure.to_xml(ROOT) }
      end      
    end    
  end
  
  #Public: Checks the subscription status for users
  def subscribe_status
      @community_user = @community.community_users.by_user_id(@current_user._id).first
      respond_to do |format|
      if @community_user.status!=false
        if @community_user.update_attributes(:subscribe_email => params[:subscribe_email])
          find_parameters
          format.json {render :json => { :community_user => @community_user}.to_success }
        else
          format.json  { render :json =>@community_user.all_errors}
        end
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  #Public: Search user own communities
  def search_own_team
    communities = Community.search_own(params,@current_user)
      respond_to do |format|
        format.json {render :json =>{:communities=>communities.to_json(:methods => [:users_count, :shares_count]).parse}.to_success}
      end
  end
    
  #Public: Search user shared communities
  def search_shared_team
     communities = Community.search_shared(params,@current_user)
      respond_to do |format|
        format.json {render :json =>{:communities=>communities.to_json(:only=>[:_id,:name], :methods => [:users_count, :shares_count]).parse}.to_success}
      end
  end


  private

  #Private: To find the category for CRUD methods
  #Called on before filter
  def find_community
    @community = Community.find(params[:id])
  end

  #Private: To find the community members
  #Called on before filter
  def find_community_members
    @community=Community.find(params[:id]) if @current_user.community_membership_ids.include?(params[:id])
  end

  #find parameters needed for the contacts
  def find_parameters
    @community={:community=>@community.serializable_hash(:only=>[:_id,:name,:description])}.to_success
  end

  #Private: Authorized member check
  def check_authorised_mem
    @authoriesd_mem = CommunityUser.by_user_id_and_community_id(@current_user._id, params[:id]).first
  end
  
  #Private: Subscribed member check
  def check_subscribed_user
    @subscribed_user = @current_user.subscription_type == "free" ? false :  true
  end
    
end
