class  V1::TopicsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_topic,:only=>([:update,:show,:destroy])
  # GET /topics/1
  # GET /topics/1.xml
  def show
    respond_to do |format|
      if @topic
        format.json  { render :json => {:topic=>@topic.to_json(:only=>[:name,:_id,:status],:methods=>:get_item)}.merge(success) }
        format.xml  { render :xml => {:topic=>@topic.to_xml(:only=>[:name,:_id,:status],:methods=>item)} }
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # POST /topics
  # POST /topics.xml
  def create
    @topic = Topic.new(params[:topic])
    respond_to do |format|
      if @topic.save
        @topic={:topic=>@topic.serializable_hash(:only=>[:name,:status,:item_id,:_id]) }.to_success
        format.xml  { render :xml => @topic.to_xml(:root=>:xml)}
        format.json  { render :json => @topic}
      else
        format.xml  { render :xml => failure.merge(@topic.all_errors).to_xml(:root=>:xml)}
        format.json  { render :json => @topic.all_errors }
      end
    end
  end

  # PUT /topics/1
  # PUT /topics/1.xml
  def update
    respond_to do |format|
      if @topic
        if @topic.update_attributes(params[:topic])
          format.xml  { render :xml => @topic }
          format.json  { render :json => {:topic=>@topic.to_json(:only=>[:name,:status,:item_id,:_id]) }.merge(success)}
        else
          format.xml  { render :xml => @topic.errors.to_xml(:root=>'xml')}
          format.json  { render :json => {"errors"=>@topic.all_errors }.merge(failure)}
        end
      else
      format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
      format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # DELETE /topics/1
  # DELETE /topics/1.xml
  def destroy
   respond_to do |format|
      if @topic
         @topic.destroy
         format.xml  { render :xml => success.to_xml(:root=>'xml') }
         format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

   #Find the Topic by param[:id]
  def find_topic
    @topic = Topic.find(params[:id])
  end
end
