class V1::PagesController < ApplicationController
  # GET /v1/pages
  # GET /v1/pages.xml

  before_filter :authenticate_request!
  before_filter :find_item

  def index
    @pages = Page.all

    respond_to do |format|
      format.xml  { render :xml => @pages }
    end
  end

  # GET /v1/pages/1
  # GET /v1/pages/1.xml
  def show
    @page = Page.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @page }
    end
  end

  # POST /v1/pages
  # POST /v1/pages.xml
  def create
    set_position;set_page_order;set_attachment
    @page = @item.pages.new(params[:page])

    respond_to do |format|
      if @page.save
        @page.create_attachment(params[:attachment])
        @page.page_texts.create(:content=>params[:page][:page_text][:content], :position=>params[:page][:page_text][:position]) if params[:page][:page_text]

        success_json =  success.merge(:item_id=>@item.id, :page=>@page.to_json(:only=>[:_id, :page_order]).parse)
        success_json[:page].store(:page_texts,@page.page_texts.to_a.to_json(:only=>[:_id, :position, :content]).parse) unless @page.page_texts.empty?
        format.json  { render :json => success_json }
        format.xml  { render :xml => @page.to_xml(:root=>:page, :except=>[:created_at, :updated_at]) }
      else
        format.json  { render :json => failure.merge(:errors=>@page.all_errors) }
        format.xml  { render :xml => @page.all_errors, :root=>:errors}
      end
    end
  end

  # PUT /v1/pages/1
  # PUT /v1/pages/1.xml
  def update
    @page = Page.find(params[:id])

    respond_to do |format|
      if @page.update_attributes(params[:page])
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /v1/pages/1
  # DELETE /v1/pages/1.xml
  def destroy
    @page = Page.find(params[:id])
    @page.destroy

    respond_to do |format|
      format.xml  { head :ok }
    end
  end

  private

  def find_item
    params[:item_id]="" unless params.has_key?(:item_id)
    @item = Item.find(params[:item_id])
  end

  def set_position
    if params[:page][:page_text]
      return params[:page][:page_text][:position] =  eval(params[:page][:page_text][:position])  unless params[:page][:page_text][:position].blank?
      params[:page][:page_text][:position] = [0,0]
    end
  end

  def set_page_order
      return params[:page][:page_order] = 1 if @item.pages.empty?
      current_page = @item.pages.order_by(:page_order, :desc).first.page_order
      return params[:page][:page_order] = current_page+=1 if params[:page][:page_order].blank?
      params[:page][:page_order] = params[:page][:page_order].to_i > current_page ?  params[:page][:page_order] : current_page+=1
  end

  def set_attachment
    params.store(:attachment,{})
    params[:attachment][:file] =params[:page].delete(:file)
    set_attachment_options
  end

end
