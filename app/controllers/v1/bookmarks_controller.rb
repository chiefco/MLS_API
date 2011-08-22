class V1::BookmarksController < ApplicationController
  # GET /v1/bookmarks
  # GET /v1/bookmarks.xml
  def index
    @v1_bookmarks = Bookmark.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @v1_bookmarks }
      format.json  { render :json => @v1_bookmarks }
    end
  end

  # GET /v1/bookmarks/1
  # GET /v1/bookmarks/1.xml
  def show
    @v1_bookmark = Bookmark.where(:_id=>params[:id]).first
    respond_to do |format|
      if  @v1_bookmark
       format.xml  { render :xml => @v1_bookmark }
      else
       format.xml  { render :xml => failure.merge(invalid_parameter_id).to_xml(:root=>'xml') }
       format.json  { render :json=> failure.merge(invalid_parameter_id)}
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
        format.json  { render :json =>{:bookmark=>{:name=>@v1_bookmark.name,:show_in_quick_links=>@v1_bookmark.show_in_quick_links}} }
      else
        format.xml  { render :xml => @v1_bookmark.errors}
        format.json  { render :json => @v1_bookmark.all_errors }
      end
    end
  end

  # PUT /v1/bookmarks/1
  # PUT /v1/bookmarks/1.xml
  def update
    @v1_bookmark = Bookmark.where(:_id=>params[:id]).first
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
        format.xml  { render :xml => failure.merge(invalid_parameter_id).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(invalid_parameter_id)}
      end
    end
  end

  # DELETE /v1/bookmarks/1
  # DELETE /v1/bookmarks/1.xml
  def destroy
    @v1_bookmark = Bookmark.where(:_id=>params[:id]).first
     respond_to do |format|
      if  @v1_bookmark
        @v1_bookmark.destroy
        format.xml  { render :xml => success.to_xml(:root=>'xml') }
        format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(invalid_parameter_id).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(invalid_parameter_id)}
      end
    end
  end
  
end
