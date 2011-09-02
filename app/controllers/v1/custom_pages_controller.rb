class V1::CustomPagesController < ApplicationController
    before_filter :authenticate_request!
    before_filter :find_custom_page,:only=>([:update,:destroy])
    before_filter :find_custom_page_field,:only=>([:update_custom_page_fields,:custom_page_fields_remove])

  # POST /custom_pages
  # POST /custom_pages.xml
  def create
    @custom_page = CustomPage.new(params[:custom_page])
    respond_to do |format|
      if @custom_page.save
        format.json  { render :json =>{:custom_page=>@custom_page.to_json(:only=>[:_id,:page_data])}.merge(success)}
      end
    end
  end

  # PUT /custom_pages/1
  # PUT /custom_pages/1.xml
  def update
    respond_to do |format|
      if @custom_page
        @custom_page.update_attributes(params[:custom_page])
        format.json  { render :json =>{:custom_page=>@custom_page.to_json(:only=>[:_id,:page_data])}.merge(success)}
      else
        format.xml  {render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  {render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # DELETE /custom_pages/1
  # DELETE /custom_pages/1.xml
   def destroy
     respond_to do |format|
      if  @custom_page
        @custom_page.destroy
        format.xml  { render :xml => success.to_xml(:root=>'xml') }
        format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  #Adds the Custom Page Fields to the given Custom Page
  def custom_page_fields
    @custom_page = CustomPage.find(params[:custom_page_field][:custom_page_id])
    respond_to do |format|
      if @custom_page
        @custom_page_field=@custom_page.custom_page_fields.new(params[:custom_page_field])
        if @custom_page_field.save
          format.json  { render :json =>{:custom_page_field=>@custom_page_field.to_json(:except=>([:created_at,:updated_at]))}.merge(success)}
        else
          format.json{render :json=>{:errors=>@custom_page_field.all_errors}.merge(failure)}
        end
      else
        format.json {render :json=>{:code=>"3069",:message=>"custom_page_id - Blank Parameter"}.merge(failure)}
      end
    end
  end

    #Updates the Custom Page Fields
  def update_custom_page_fields
    respond_to do |format|
      if @custom_page_field
        if @custom_page_field.update_attributes(params[:custom_page_field])
          format.json{render :json=>{:custom_page_field=>@custom_page_field.to_json(:except=>([:created_at,:updated_at]))}.merge(success)}
        else
          format.json{render :json=>{:errors=>@custom_page_field.all_errors}.merge(failure)}
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

    def custom_page_fields_remove
    respond_to do |format|
      if @custom_page_field
        @custom_page_field.destroy
        format.xml  { render :xml => success.to_xml(:root=>'xml') }
        format.json{render :json=>success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  #finds the custompage
  def find_custom_page
   @custom_page = CustomPage.where(:_id=>params[:id]).first
  end
  def find_custom_page_field
     @custom_page_field = CustomPageField.find(params[:id])
  end
end
