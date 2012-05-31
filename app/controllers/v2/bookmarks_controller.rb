class V2::BookmarksController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_bookmark,:only=>([:update,:show,:destroy,:add_bookmark,:remove_bookmark])
  # GET /v1/bookmarks
  # GET /v1/bookmarks.xml
  def index
    @bookmark=@current_user.bookmarks.undeleted
    respond_to do |format|
      format.json{render :json=>{:count=>@bookmark.count,:bookmarks=>@bookmark.to_a.to_json(:only=>[:_id,:name],:include=>{:bookmarked_contents=>{:include=>{:bookmarkable=>{:only=>[:_id,:name,:description,:page_order,:attachable_type,:attachable_id,:file_name,:file_type,:status]}},:only=>[:_id,:bookmarkable_type,:bookmarkable_id]}}).parse}}
      format.xml
    end
  end

  # GET /v1/bookmarks/1
  # GET /v1/bookmarks/1.xml
  def show
    respond_to do |format|
      unless @v1_bookmark.status==false
        if @v1_bookmark
          @v1_bookmark={:bookmarks=>@v1_bookmark.serializable_hash(:only=>[:_id,:name],:include=>{:bookmarked_contents=>{:include=>{:bookmarkable=>{:only=>[:_id,:name,:description,:page_order,:attachable_type,:attachable_id,:file_name,:file_type]}},:only=>[:_id,:bookmarkable_type,:bookmarkable_id]}})}.to_success
          format.json{render :json=>@v1_bookmark}
          format.xml{render :xml=>@v1_bookmark.to_xml(ROOT)}
        else
          format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
          format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}      end
    end
  end

  # POST /v1/bookmarks
  # POST /v1/bookmarks.xml
  def create
    @v1_bookmark = @current_user.bookmarks.new(params[:bookmark])
    respond_to do |format|
      if @v1_bookmark.save
        format.xml  { render :xml => success.merge(:bookmark=>@v1_bookmark).to_xml(ROOT,:only=>[:name,:_id])}
        format.json  { render :json =>{:bookmark=>@v1_bookmark.to_json(:only=>[:name,:_id]).parse}.to_success }
      else
        format.xml  { render :xml => failure.merge(@v1_bookmark.all_errors).to_xml(ROOT)}
        format.json  { render :json => @v1_bookmark.all_errors }
      end
    end
  end

  # PUT /v1/bookmarks/1
  # PUT /v1/bookmarks/1.xml
  def update
    respond_to do |format|
      unless @v1_bookmark.status==false
        if  @v1_bookmark
          if @v1_bookmark.update_attributes(params[:bookmark])
            format.xml  { render :xml => success.merge(:bookmark=>@v1_bookmark).to_xml(ROOT,:only=>[:name,:_id])}
            format.json  { render :json =>{:bookmark=>@v1_bookmark.to_json(:only=>[:name,:_id]).parse}.to_success }
          else
            format.xml  { render :xml => failure.merge(@v1_bookmark.all_errors).to_xml(ROOT)}
            format.json  { render :json => @v1_bookmark.all_errors }
          end
        else
          format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
          format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # DELETE /v1/bookmarks/1
  # DELETE /v1/bookmarks/1.xml
  def destroy
     respond_to do |format|
      if  @v1_bookmark
        @v1_bookmark.update_attributes(:status=>false)
        format.xml  { render :xml => success.to_xml(ROOT) }
        format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: Add items in the bookmark
  def add_bookmark
    if @v1_bookmark
        @v1_bookmark.user==@current_user ? process_in_bookmark_content : failure_save
    else
      failure_save
    end
  end

  # Public: To remove bookmark
  def remove_bookmark
      if @v1_bookmark
        @v1_bookmark.user==@current_user ? remove_in_bookmark_content : failure_save
    else
      failure_save
    end
  end

  # Public: To save bookmark contents
  def save_bookmark_content
    @v1_bookmark.save
    respond_to do |format|
      @bookmark_content={:bookmark_content=>@v1_bookmark.serializable_hash(:only=>[:_id])}.to_success
      format.json {render :json => @bookmark_content}
      format.xml {render :xml => success.to_xml(ROOT)}
    end
  end

  # Public: To remove bookmark contents
  def remove_bookmark_content
    respond_to do |format|
      format.json {render :json => success}
      format.xml {render :xml => success.to_xml(ROOT)}
    end
  end

  # Public: Find the Bookmark by param[:id]
  def find_bookmark
    @v1_bookmark = Bookmark.find(params[:id])
  end

  # Public: Bookmark content process
  def process_in_bookmark_content
    @v1_bookmark=@v1_bookmark.bookmarked_contents.build(params[:add_bookmark])
    @v1_bookmark.bookmarkable.nil? ? failure_save : validate_in_bookmark_content
  end

  # Public: validate bookmark content
  def validate_in_bookmark_content
    @bookmarkable=@v1_bookmark.bookmarkable
      if @bookmarkable.class.to_s == "Page"
        @bookmarkable.item.user != @current_user ? failure_save : save_bookmark_content
      else
        @bookmarkable.user != @current_user ? failure_save : save_bookmark_content
      end
    end

  # Public: To Remove bookmark content
  def remove_in_bookmark_content
     @v1_bookmark=check_in_bookmark_content
    @v1_bookmark.nil? ?  failure_save  : remove_bookmark_content
   end

  # Public: Check if bookmark content is deleted or not
  def check_in_bookmark_content
     @v1_bookmark.bookmarked_contents.each do |content|
       if content.id.to_s == params[:content_id]
         content.delete
       end
     end
      #@bookmark_content = @bookmarkable.map(&:bookmarkable_id)

  end

  # Public: Failure save
  # Retruns error message
  def  failure_save
    respond_to do |format|
      format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
      format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
    end
  end
end
