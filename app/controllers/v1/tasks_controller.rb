class V1::TasksController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_task,:only=>([:update,:show,:destroy])
  before_filter :find_reminder,:only=>([:get_reminder,:delete_reminder,:update_reminder])
  	#Retrieves the tasks of the current_user
	def index
		p @current_user.tasks.count
		paginate_options = {}
    paginate_options.store(:page,set_page)
    paginate_options.store(:per_page,set_page_size)
    @tasks = Task.list(params,paginate_options,@current_user)
		p @tasks.count
			respond_to do |format|
				format.json {render :json=>{:tasks=>@tasks.to_a.to_json(:only=>[:_id,:due_date,:is_completed,:description],:include=>{:item=>{:only=>[:_id,:name]}})}}
			end
	end
  # GET /v1/tasks/1
  # GET /v1/tasks/1.xml
  def show
    respond_to do |format|
      if @task
          format.json  { render :json => {:task=>@task.to_json(:only=>[:_id,:description,:due_date,:is_completed],:include=>{:item=>{:only =>[ :_id,:name]}})}.to_success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # POST /v1/tasks
  # POST /v1/tasks.xml
  def create
    @task = @current_user.tasks.new(params[:task])
    validate_item(params[:task][:item_id]) if params[:task][:item_id]
    @count.nil? ? save_task : evaluate_item
  end

  # PUT /v1/tasks/1
  # PUT /v1/tasks/1.xml
  def update
    validate_item(params[:task][:item_id]) if params[:task][:item_id]
    @count.nil? ? update_task : evaluate_item
  end

  # DELETE /v1/tasks/1
  # DELETE /v1/tasks/1.xml
 def destroy
   respond_to do |format|
      if @task
         @task.destroy
         format.xml  { render :xml => success.to_xml(:root=>'xml') }
         format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  def validate_item(value)
    @count=0
    @item=Item.find(value)
    @item.template.template_definitions.each do |item|
      @count=@count+1 if item.has_task_section == true
    end
  end

  def save_task
    respond_to do |format|
      if @task.save
      format.xml  { render :xml => @task }
      format.json  { render :json => {:task=>@task.to_json(:only=>[:_id,:description,:due_date,:is_completed],:include=>{:item=>{:only =>[ :_id,:name]}})}.to_success}
      else
      format.xml  { render :xml => @task.errors}
      format.json  { render :json => {"errors"=>@task.all_errors }}
      end
    end
  end

  def update_task
   respond_to do |format|
      if @task
        if @task.update_attributes(params[:task])
          format.xml  { render :xml => @task }
          format.json  { render :json => {:task=>@task.to_json(:only=>[:_id,:description,:due_date,:is_completed],:include=>{:item=>{:only =>[ :_id,:name]}})}.to_success}
        else
          format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
          format.json  { render :json => {"errors"=>@task.all_errors }}
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  def evaluate_item
    if @count<0
      respond_to do |format|
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    else
      request.post? ? save_task : update_task
   end
 end

	#Adds the reminder to the task
  def add_reminder
		@task=Task.find(params[:reminder][:task_id])
		respond_to do |format|
			if @task
				@reminder=@task.reminders.new(params[:reminder])
				if @reminder.save
					format.xml  { render :xml => reminder_parameters }
					format.json  { render :json =>reminder_parameters}
				else
					format.xml  { render :xml => @reminder.errors}
					format.json  { render :json => {"errors"=>@reminder.all_errors }}
				end
			else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
			end
		end
  end

	#Updates the single Reminder
  def update_reminder
    respond_to do |format|
      if @reminder
        if @reminder.update_attributes(params[:reminder])
          format.xml  { render :xml => @reminder }
          format.json  { render :json =>reminder_parameters}
        else
          format.xml  { render :xml => @reminder.errors, :status => :unprocessable_entity }
          format.json  { render :json => {"errors"=>@reminder.all_errors }}
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  #Deletes the single Reminder
  def delete_reminder
    respond_to do |format|
      if @reminder
       @reminder.destroy
         format.xml  { render :xml => success.to_xml(:root=>'xml') }
         format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

	#Retrieves the single Reminder
  def get_reminder
    respond_to do |format|
      if @reminder
         format.json  { render :json=> reminder_parameters}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  #Retrieves all reminders of the given task
  def get_all_reminders
    respond_to do |format|
			@task=Task.find(params[:task_id])
			format.json  { render :json=> {:reminders=>@task.reminders.to_a.to_json(:only=>[:_id,:time],:include=>{:task=>{:only=>[:_id,:description]}})}.to_success}
    end
  end

  def find_reminder
    @reminder=Reminder.find(params[:id])
  end

  def reminder_parameters
    {:reminder=>{:id=>@reminder._id,:task=>{:id=>@reminder.task._id,:description=>@reminder.task.description},:time=>@reminder.time}}.to_success
  end

	  # finds the task
  def find_task
    @task = Task.find(params[:id])
  end
end