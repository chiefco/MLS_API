class V1::PagesController < ApplicationController
  # GET /v1/pages
  # GET /v1/pages.xml

  before_filter :authenticate_request!
  before_filter :find_page, :except=>[:create, :index]
  before_filter :find_item, :only=>[:index, :create, :update]

  def index
    paginate_options = {}
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    @pages = Page.list(@item.pages,params,paginate_options)

    respond_to do |format|
      format.json { render :json=> success.merge(:count=>@pages.count,:pages=>@pages.to_a.to_json(:only=>[:_id, :page_order],:include=>{:page_texts=>{:only=>[:_id, :content, :position]}, :attachment=>{:only=>[:file]}}).parse) }
      format.xml { render :xml => @pages.to_xml(:only=>[:_id, :page_order])}
    end
  end

  # GET /v1/pages/1
  # GET /v1/pages/1.xml
  def show
    respond_to do |format|
      if @page.status!=false
        format.json { render :json=> @page.to_json(:only=>[:_id, :page_order], :include=>{:page_texts=>{:only=>[:_id, :content, :position]}, :attachment=>{:only=>[:file]}}).parse.to_success }
        format.xml { render :xml => @page.to_xml(:only=>[:_id, :page_order])}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # POST /v1/pages
  # POST /v1/pages.xml
  def create
    if valid_file?
      set_position; set_page_order; set_attachment
      @page = @item.pages.new(:page_order=>params[:page][:page_order])

      respond_to do |format|
        if @page.save
          @page.create_attachment(params[:attachment])
          params[:page][:page_text].each { |page_txt| @page.page_texts.create(page_txt) } unless params[:page][:page_text].blank?

          success_json =  success.merge(:item_id=>@item.id, :page=>@page.to_json(:only=>[:_id, :page_order], :include=>{:attachment=>{:only=>[:file]}}).parse)
          success_json[:page].store(:page_texts,@page.page_texts.to_a.to_json(:only=>[:_id, :position, :content]).parse) unless @page.page_texts.empty?

          format.json  { render :json => success_json }
          format.xml  { render :xml => @page.to_xml(:root=>:page, :except=>[:created_at, :updated_at]) }
        else
          format.json  { render :json => failure.merge(:errors=>@page.all_errors) }
          format.xml  { render :xml => @page.all_errors, :root=>:errors}
        end
      end
    else
      render_invalid_file
    end
  end

  # PUT /v1/pages/1
  # PUT /v1/pages/1.xml
  def update
    respond_to do |format|
      if @page.status!=false
        if valid_file?
          set_position; set_attachment
          params[:page][:page_order] = @page.page_order if params[:page][:page_order].blank?
          if @page.update_attributes(:page_order=>params[:page][:page_order], :item_id=>params[:item_id])
            @page.attachment.update_attributes(params[:attachment])
            update_page_texts  unless params[:page][:page_text].blank?
            success_json =  success.merge(:item_id=>@item.id, :page=>@page.to_json(:only=>[:_id, :page_order], :include=>{:attachment=>{:only=>[:file]}}).parse)
            success_json[:page].store(:page_texts,@page.page_texts.to_a.to_json(:only=>[:_id, :position, :content]).parse) unless @page.page_texts.empty?
            format.json  { render :json => success_json }
            format.xml  { render :xml => @page.to_xml(:root=>:page, :except=>[:created_at, :updated_at]) }
          else
            format.json  { render :json => failure.merge(:errors=>@page.all_errors) }
            format.xml  { render :xml => @page.all_errors, :root=>:errors}
          end
        else
        render_invalid_file
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # DELETE /v1/pages/1
  # DELETE /v1/pages/1.xml
  def destroy
    @page.update_attributes(:status=>false)

    respond_to do |format|
      format.json  { render :json=> success }
      format.xml  { render :xml=> success.to_xml(:root=>:result) }
    end
  end

  private

  def find_page
    return render_missing("id","2012") unless params.has_key?("id")
    @page = Page.find(params[:id])
  end

  def find_item
    return render_missing("item_id","2012") unless params.has_key?("item_id")
    @item = Item.find(params[:item_id])
    p @item.inspect
  end

  def set_position
    unless params[:page][:page_text].blank?
      params[:page][:page_text].collect! { |page_text| page_text unless page_text["content"].blank? }.compact!
      params[:page][:page_text].each do |page_txt|
        if page_txt.has_key?("position")
          page_txt["position"] = eval(page_txt["position"])
        else
          page_txt["position"] = [0,0]
        end
      end
    end
  end

  def set_page_order
      return params[:page][:page_order] = 1 if @item.pages.empty?
      current_page = @item.pages.order_by(:page_order, :desc).first.page_order
      current_pages = @item.pages.map(&:page_order)
      return params[:page][:page_order] = current_page+=1 if params[:page][:page_order].blank?
      params[:page][:page_order] = !current_pages.include?(params[:page][:page_order].to_i) ?  params[:page][:page_order].to_i : current_page+=1
  end

  def set_attachment
    params.store(:attachment,{})
    params[:attachment][:file] =params[:page].delete(:file)
    set_attachment_options
  end

  def valid_file?
    return true if params[:page] && params[:page].has_key?(:file) && !params[:page][:file].blank?
    false
  end

  def  update_page_texts
    params[:page][:page_text].each do |page_txt|
      page_txt_to_update = @page.page_texts.find(page_txt["id"]) if page_txt["id"]
      page_txt_to_update.update_attributes(:content=>page_txt["content"], :position=>page_txt["position"]) if page_txt_to_update
    end
  end
  def render_invalid_file
    respond_to do |format|
      format.json {render :json=>failure.merge(FILE_FORMAT)}
    end
  end
end
