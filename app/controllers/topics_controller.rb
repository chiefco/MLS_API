class TopicsController < ApplicationController
  # GET /topics
  # GET /topics.xml
  def index
    @topics = Topic.all
    respond_to do |format|
      format.xml  { render :xml => @topics }
    end
  end

  # GET /topics/1
  # GET /topics/1.xml
  def show
    @topic = Topic.find(params[:id])
    respond_to do |format|
      format.xml  { render :xml => @topic }
    end
  end

  # GET /topics/1/edit
  def edit
    @topic = Topic.find(params[:id])
  end

  # POST /topics
  # POST /topics.xml
  def create
    @topic = Topic.new(params[:topic])
    respond_to do |format|
      if @topic.save
        format.xml  { render :xml => @topic, :status => :created, :location => @topic }
        format.json  { render :json => @topic }
      else
        format.xml  { render :xml => @topic.errors, :status => :unprocessable_entity }
        format.json  { render :json => {"errors"=>@topic.all_errors }}
      end
    end
  end

  # PUT /topics/1
  # PUT /topics/1.xml
  def update
    @topic = Topic.find(params[:id])
    respond_to do |format|
      if @topic.update_attributes(params[:topic])
        format.xml  { render :xml => @topic, :status => :created, :location => @topic }
        format.json  { render :json => @topic }    
      else
        format.xml  { render :xml => @topic, :status => :created, :location => @topic }
        format.json  { render :json => @topic }        
      end
    end
  end

  # DELETE /topics/1
  # DELETE /topics/1.xml
  def destroy
    @topic = Topic.find(params[:id])
    @topic.destroy
    respond_to do |format|
      format.xml  { head :ok }
      format.xml  { render :xml => success.to_xml(:root=>'xml') }
      format.json  { render :json=> success}
    end
  end
end
