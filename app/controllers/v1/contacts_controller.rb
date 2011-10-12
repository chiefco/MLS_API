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
    @contact.update_attributes(:status=>true)
    respond_to do |format|
      format.json  { render :json=> success}
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
end
