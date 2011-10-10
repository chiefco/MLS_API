class V1::CommentsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_comment,:only=>[:update,:show,:destroy]
  before_filter :add_pagination,:only=>[:index]
  # GET /comments
  # GET /comments.xml
  def index
    @comments = Comment.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @comments }
    end
  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # POST /comments
  # POST /comments.xml
  def create
    @comment = Comment.new(params[:comment])
    respond_to do |format|
      if @comment.save
        format.html { redirect_to(@comment, :notice => 'Comment was successfully created.') }
        format.xml  { render :xml => @comment, :status => :created, :location => @comment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        format.html { redirect_to(@comment, :notice => 'Comment was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to(comments_url) }
      format.xml  { head :ok }
    end
  end
  
  #finds the comment
  def find_comment
    @comment=Comment.find(params[:id])
  end
end
