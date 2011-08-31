class V1::PagesController < ApplicationController
  # GET /v1/pages
  # GET /v1/pages.xml

  before_filter :authenticate_request!
  before_filter :find_page, :except=>[:create, :index]
  before_filter :find_item, :only=>[:index, :create]

  def index

    paginate_options = {}
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    @pages = Page.list(@item.pages,params,paginate_options)
    
    respond_to do |format|
      format.json { render :json=> success.merge(:pages=>@pages.to_json(:only=>[:_id, :page_order], :include=>{:page_texts=>{:only=>[:_id, :content, :position]}, :attachment=>{:only=>[:file_link]}}).parse) }
      format.xml { render :xml => @pages.to_xml(:only=>[:_id, :page_order])}
    end
  end

  # GET /v1/pages/1
  # GET /v1/pages/1.xml
  def show
  
    respond_to do |format|
      format.json { render :json=> @page.to_json(:only=>[:_id, :page_order], :include=>{:page_texts=>{:only=>[:_id, :content, :position]}, :attachment=>{:only=>[:file_link]}}).parse.to_success }
      format.xml { render :xml => @page.to_xml(:only=>[:_id, :page_order])}
    end
  end

  # POST /v1/pages
  # POST /v1/pages.xml
  def create
    set_position;set_page_order;set_attachment
    @page = @item.pages.new(:page_order=>params[:page][:page_order])

    respond_to do |format|
      if @page.save
        @page.page_texts.create(params[:page][:page_text]) if params[:page][:page_text]
        @page.create_attachment(params[:attachment])
        
        success_json =  success.merge(:item_id=>@item.id, :page=>@page.to_json(:only=>[:_id, :page_order], :include=>{:attachment=>{:only=>:file_link}}).parse)
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
    
    respond_to do |format|
      if @page.update_attributes(params[:page])
        format.xml  { head :ok }
      else
        format.json  { render :json => failure.merge(:errors=>@page.all_errors) }
        format.xml  { render :xml => @page.all_errors, :root=>:errors}
      end
    end
  end

  # DELETE /v1/pages/1
  # DELETE /v1/pages/1.xml
  def destroy
    @page.destroy

    respond_to do |format|
      format.json  { render :json=> success }
      format.xml  { render :xml=> success.to_xml(:root=>:result) }
    end
  end

  private

  def find_page
    @page = Page.find(params[:id])
  end

  def find_item
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
