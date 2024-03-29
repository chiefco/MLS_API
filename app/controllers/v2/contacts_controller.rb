class V2::ContactsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_contact,:only=>[:update,:show,:destroy]
  before_filter :add_pagination,:only=>[:index]
  # GET /contacts
  # GET /contacts.xml
  def index
    @contacts = Contact.list(params,@paginate_options,@current_user)
    respond_to do |format|
      format.json  { render :json =>{:contacts=>@contacts.to_json(:except=>[:status]).parse}}
    end
  end

  # GET /contacts/1
  # GET /contacts/1.xml
  def show
    respond_to do |format|
      if @contact.status!=false
        find_parameters
        format.json  {render :json =>@contact}
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end


  # POST /contacts
  # POST /contacts.xml
  def create
    @contact_id=User.where(:email=>params[:contact][:email]).first
    params[:contact][:contact_id]=@contact_id._id if @contact_id
    @contact = @current_user.contacts.new(params[:contact])
    respond_to do |format|
      if @contact.save
       find_parameters
       format.json  {render :json =>@contact}
      else
        format.json  { render :json => @contact.all_errors}
      end
    end
  end

  # PUT /contacts/1
  # PUT /contacts/1.xml
  def update
    respond_to do |format|
      if @contact.status!=false
        if @contact.update_attributes(params[:contact])
          find_parameters
          format.json  {render :json =>@contact}
        else
          format.json  { render :json => @contact.all_errors}
        end
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # DELETE /contacts/1
  # DELETE /contacts/1.xml
  def destroy
    @contact.update_attributes(:status=>false)
    respond_to do |format|
      format.json  { render :json=> success}
    end
  end


  # POST /contacts
  # POST /contacts.xml
  def add_import_contacts
    params[:all_contact].each_value do |contacts|
      #~ p params[:first_name]=contacts['contact']['first_name']
      #~ p params[:email]=contacts['contact']['email']
      #params[:contact]=>{:first_name=>params[:first_name],:email=>params[:email])}
      end
  end

  # Public: Send the invitaions for the users
  def invite_member
    Invite.send_invitations(@current_user,params[:invite_member][:email]).deliver
    respond_to do |format|
      format.json  { render :json=> success}
    end
  end

  # Public: Share's the Item to Community Members and Contacts
  def share
    find_item
    @community=Community.where(:_id=>params[:share][:community_id]).first
    share_to_members if @community
    send_shares_emails if !params[:share][:emails].empty?
    respond_to do |format|
      format.json {render :json=>success}
    end
  end

  # Public: To remove the shares for the users
  def remove_share
    respond_to do |format|
      @share=Share.where(:_id=>params[:id]).first
      unless @share.nil?
        @share.update_attributes(:status=>false)
        format.json {render :json=>success}
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  # Public: Sharing to members 
  def share_to_members
    @community.members.each do |member|
      @share=@item.shares.create(:user_id=>member[:id])
      @share.create_permission(params[:share][:permission_id])
      Invite.share_community(@share.user,@item).deliver
    end
  end

  # Public:  Retrieves the shares of the item
  def shares
    @item=Item.find(params[:id])
    respond_to do |format|
      @share=@item.shares.serializable_hash(:only=>[:_id],:methods=>[:user_details,:role])
      format.json{render :json=>{:shares=>@share}}
    end
  end
  
  # Public: Share send the emails
  def send_shares_emails
    params[:share][:emails].split(',').each do |email|
      @user=User.where(:email=>email).first
      @user.nil? ? send_invites(email) : create_shares
    end
  end

  # Public: Creating share
  def create_shares
    @share=@item.shares.create(:user_id=>@user._id)
    @share.create_permission(params[:share][:permission_id])
    Invite.share_community(@user,@item).deliver
  end
  
  # Public: To send invites
  def send_invites(email)
    @item.invitations.find_or_create_by(:email=>email)
    Invite.send_invitations(@current_user,email).deliver
  end
  
  # Public: search user contacts
  def search_contacts
    contacts = Contact.search(params,@current_user)
      respond_to do |format|
        format.json {render :json =>{:mls_users=>contacts[0].to_json(:only=>[:first_name, :last_name, :job_title, :company, :email], :methods => [:user_info]).parse, :other_users=>contacts[1]}.to_success}
      end
    end
    
  # Public: Delete multiple contacts  
  def multiple_contact_delete
      contacts = Contact.any_in(:email =>params[:mail_ids]).where(:user_id => @current_user._id).destroy_all
      respond_to do |format|
        if contacts
          format.json {render :json=>success}
        else
          format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
        end
     end
  end

  #finds the contact
  def find_contact
    @contact=@current_user.contacts.find(params[:id])
  end

  #find parameters needed for the contacts
  def find_parameters
    @contact={:contact=>@contact.serializable_hash(:only=>[:_id,:first_name,:last_name,:job_title,:company,:email])}.to_success
  end

  def find_item
    @item=Item.find(params[:share][:item_id])
  end
end
