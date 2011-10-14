class V1::ContactsController < ApplicationController
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
      if @contact.status!=true
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
      if @contact.status!=true
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
  
  def invite_member
    Invite.send_invitations(@current_user,params[:invite_member][:email]).deliver
    respond_to do |format|
      format.json  { render :json=> success}
    end
  end
  
  #Share's the Item to Community Members and Contacts
  def share
    find_item
    @community=Community.where(:_id=>params[:share][:community_id]).first
    share_to_members if @community
    send_shares_emails if !params[:share][:emails].empty?
    respond_to do |format|
      format.json {render :json=>success}
    end
  end
  
  def remove_share
    respond_to do |format|
      @share=Share.where(:user_id=>params[:share][:user_id],:item_id=>params[:share][:item_id]).first
      unless @share.nil?
        @share.update_attributes(:status=>false)
        format.json {render :json=>success}
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
    
  def share_to_members
    @community.members.each do |member|
      @share=@item.shares.create(:user_id=>member[:id])
      @share.create_permission(params[:share][:permission_id])
      Invite.share_community(@share.user,@item).deliver
    end
  end
  
  def send_shares_emails
    params[:share][:emails].split(',').each do |email|
      @user=User.where(:email=>email).first
      @user.nil? ? send_invites(email) : create_shares
    end
  end
  
  def create_shares
    @share=@item.shares.create(:user_id=>@user._id)
    @share.create_permission(params[:share][:permission_id])
    Invite.share_community(@user,@item).deliver
  end
  
  def send_invites(email)
    @item.invitations.find_or_create_by(:email=>email)
    Invite.send_invitations(@current_user,email).deliver
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
