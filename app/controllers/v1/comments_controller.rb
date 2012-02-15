class V1::CommentsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_comment,:only=>[:update,:show,:destroy]
  before_filter :add_pagination,:only=>[:index]
  # GET /comments
  # GET /comments.xml
  def index
    @comments = Comment.undeleted
    respond_to do |format|
      format.json  { render :json =>{:comment=>@comments.to_json(:except=>[:_type]).parse,:count=>@comments.count}.to_success}
    end
  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    respond_to do |format|
      if @comment.status!=false
        get_parameters
        format.json  { render :json =>success.merge({:comment=>@comment})}
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # POST /comments
  # POST /comments.xml
  def create
    @comment = @current_user.comments.new(params[:comments])
    respond_to do |format|
      if !@comment.commentable.nil?
        if @comment.save
          get_parameters
          format.json  { render :json =>success.merge({:comment=>@comment})}
        else
          format.json  { render :json => @comment.all_errors}
        end
      else
        format.json {render :json=>failure.merge(INVALID_COMMENTABLE)}
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    respond_to do |format|
      if  @comment.status!=false
        if !@comment.commentable.nil?
          if @comment.update_attributes(params[:comments])
            get_parameters
            format.json  { render :json =>success.merge({:comment=>@comment})}
          else
            format.json  { render :json => @comment.all_errors}
          end
        else
        format.json {render :json=>failure.merge(INVALID_COMMENTABLE)}
        end
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment.update_attributes(:status=>false)
    respond_to do |format|
      format.json {render :json=>success}
    end
  end

  def get_parameters
    @comment=@comment.serializable_hash(:only=>[:_id,:message,:is_public,:commentable_type,:commentable_id])
  end
  #finds the comment
  def find_comment
    @comment=@current_user.comments.find(params[:id])
  end
end
