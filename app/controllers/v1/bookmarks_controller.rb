class V1::BookmarksController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_bookmark,:only=>([:update,:show,:destroy])
  # GET /v1/bookmarks
  # GET /v1/bookmarks.xml
  def index
    @v1_bookmarks = Bookmark.all
    bookmarks=[]
    respond_to do |format|
      @v1_bookmarks.each do |bookmark|
        sample={}
        item=[]
        bookmark.bookmarked_contents.each do |content|
          if content.bookmarkable_type=="Item"
            @item=Item.where(:_id=> content.bookmarkable_id).first
            bookmark_v1={:name=>@item.name,:id=>@item._id,:location=>(@item.location.nil? ? "nil" : @item.location.name)} if @item
            item<<bookmark_v1
            sample=sample.merge({:items=>item.compact.to_json}) if sample.is_a?(Hash) 
          end
        end
        bookmarks<<{:id=>bookmark._id,:name=>bookmark.name}.merge(sample).to_json
        format.json {render :json=>{:bookmarks=>bookmarks}} 
        format.xml {render :xml=>{:bookmarks=>bookmarks}.to_xml(:root=>'xml')} 
      end
    end
  end

  # GET /v1/bookmarks/1
  # GET /v1/bookmarks/1.xml
  def show
    item=[]
    attachments=[]
    sample={}
    respond_to do |format|
      if  @v1_bookmark
        bookmarks={:bookmark=>{:name=>@v1_bookmark.name,:id=>@v1_bookmark._id}}
        @v1_bookmark.bookmarked_contents.each do |bookmark|
          if bookmark.bookmarkable_type=="Item"
            @item=Item.where(:_id=> bookmark.bookmarkable_id).first
            bookmark_v1={:name=>@item.name,:id=>@item._id,:location=>(@item.location.nil? ? "nil" : @item.location.name)} if @item
            item<<bookmark_v1
            sample=sample.merge({:items=>item.to_json}) if sample.is_a?(Hash)
            #~ elsif bookmark.bookmarkable_type=="item1"
            #~ @item=Item.where(:_id=> bookmark.bookmarkable_id).first
            #~ bookmark_v2={:name=>@item.name,:id=>@item._id,:location=>(@item.location.nil? ? "nil" : @item.location.name)}    if @item
            #~ attachments<<bookmark_v2
            #~ sample=sample.merge({:attachments=>attachments.to_json}) if sample.is_a?(Hash)
          end
        end
        format.json {render :json=>sample.merge(bookmarks).merge(success)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # POST /v1/bookmarks
  # POST /v1/bookmarks.xml
  def create
    @v1_bookmark = Bookmark.new(params[:bookmark])
    respond_to do |format|
      if @v1_bookmark.save
        format.xml  { render :xml => @v1_bookmark, :status => :created, :location => @v1_bookmark }
        format.json  { render :json =>{:bookmark=>{:name=>@v1_bookmark.name,:id=>@v1_bookmark._id}} }
      else
        format.xml  { render :xml => @v1_bookmark.errors}
        format.json  { render :json => @v1_bookmark.all_errors }
      end
    end
  end

  # PUT /v1/bookmarks/1
  # PUT /v1/bookmarks/1.xml
  def update
    respond_to do |format|
      if  @v1_bookmark
        if @v1_bookmark.update_attributes(params[:bookmark])
          format.xml  { render :xml => @v1_bookmark, :status => :created, :location => @v1_bookmark }
          format.json  { render :json =>{:bookmark=>{:name=>@v1_bookmark.name,:show_in_quick_links=>@v1_bookmark.show_in_quick_links}} }
        else
          format.xml  { render :xml => @v1_bookmark.errors}
          format.json  { render :json => @v1_bookmark.all_errors }
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # DELETE /v1/bookmarks/1
  # DELETE /v1/bookmarks/1.xml
  def destroy
     respond_to do |format|
      if  @v1_bookmark
        @v1_bookmark.destroy
        format.xml  { render :xml => success.to_xml(:root=>'xml') }
        format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  #Find the Bookmark by the param[:id]
  def find_bookmark
    @v1_bookmark = Bookmark.where(:_id=>params[:id]).first
  end
end
