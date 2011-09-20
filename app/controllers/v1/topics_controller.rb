class  V1::TopicsController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_topic,:only=>([:update,:show,:destroy])
  # GET /topics/1
  # GET /topics/1.xml
  def show
    respond_to do |format|
      if @topic
        @topic={:topic=>@topic.serializable_hash(:only=>[:name,:_id,:status],:methods=>:topic_item)}.merge(success)
        format.json  { render :json =>@topic}
        format.xml  { render :xml =>@topic.to_xml(ROOT)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # POST /topics
  # POST /topics.xml
  def create
    validate_item(params[:topic][:item_id]) if params[:topic][:item_id]
    p @count
    @count.to_i.zero? ? evaluate_item : save_task
    #~ @topic = Topic.new(params[:topic])
    #~ respond_to do |format|
      #~ if @topic.save
        #~ @topic={:topic=>@topic.serializable_hash(:only=>[:name,:status,:item_id,:_id]) }.to_success
        #~ format.xml  { render :xml => @topic.to_xml(ROOT)}
        #~ format.json  { render :json => @topic}
      #~ else
        #~ format.xml  { render :xml => failure.merge(@topic.all_errors).to_xml(ROOT)}
        #~ format.json  { render :json => @topic.all_errors }
      #~ end
    #~ end
  end

  # PUT /topics/1
  # PUT /topics/1.xml
  def update
    respond_to do |format|
      if @topic
        if @topic.update_attributes(params[:topic])
        @topic={:topic=>@topic.serializable_hash(:only=>[:name,:status,:item_id]) }.to_success
        format.xml  { render :xml => @topic.to_xml(ROOT)}
        format.json  { render :json => @topic}
        else
          format.xml  { render :xml => failure.merge(@topic.all_errors).to_xml(ROOT)}
          format.json  { render :json => @topic.all_errors }
        end
      else
      format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
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
         format.xml  { render :xml => success.to_xml(ROOT) }
         format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  def validate_item(value)
    @count=0
    @item=Item.find(value)
    @item.template.template_definitions.each do |item|
      p item.has_topic_section
      @count=@count+1 if item.has_topic_section == true
    end
  end

  def save_task
    @topic=@item.topics.new(params[:topic])
    respond_to do |format|
      if @topic.save
        @topic={:task=>@topic.serializable_hash(:only=>[:_id,:name,:status,:item_id])}.to_success
        format.xml  { render :xml => @topic.to_xml(ROOT) }
        format.json { render :json => @topic}
      else
        format.xml  { render :xml => failure.merge(@topic.all_errors).to_xml(ROOT)}
        format.json  { render :json => @topic.all_errors }
      end
    end
  end

  def evaluate_item
    if @count.to_i<1
      respond_to do |format|
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    else
      request.post? ? save_task : update_task
   end
 end

   #Find the Topic by param[:id]
  def find_topic
    @topic = Topic.find(params[:id])
  end
end
