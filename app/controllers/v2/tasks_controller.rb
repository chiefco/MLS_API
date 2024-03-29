class V2::TasksController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_task,:only=>([:update,:show,:destroy])
  before_filter :find_reminder,:only=>([:get_reminder,:delete_reminder,:update_reminder])
  before_filter :add_pagination,:only=>[:index]

  #Retrieves the tasks of the current_user
  def index
    @tasks = Task.list(params,@paginate_options,@current_user)
    completed=@current_user.tasks.completed_tasks.count.to_i
    total_tasks=@current_user.tasks.today_tasks.count.to_i
    today_tasks if params[:today_tasks]=="true"
      respond_to do |format|
        format.json {render :json=>{:tasks=>@tasks.as_json(:only=>[:_id,:title,:due_date,:is_completed,:description, :item_id],:include=>{:reminders => {:only => [:time]}, :item=>{:only=>[:_id,:name]}}),:count=>@tasks.count,:completed=>completed,:total_tasks=>total_tasks,:uncompleted=>total_tasks-completed}.to_success}
        format.xml
      end
  end
  # GET /v1/tasks/1
  # GET /v1/tasks/1.xml
  def show
    respond_to do |format|
      if @task
        @task={:task=>@task.serializable_hash(:only=>[:_id,:description,:due_date,:is_completed,:title],:include=>{:reminders=>{:only =>[ :time]}, :item=>{:only =>[ :_id,:name]}})}.to_success
        format.json  { render :json =>@task }
        format.xml  { render :json =>@task.to_xml(ROOT) }
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # POST /v1/tasks
  # POST /v1/tasks.xml
  def create
    @task = @current_user.tasks.new(params[:task])
    #~ p validate_item(params[:task][:item_id]) if params[:task][:item_id]
    #~ @count.to_i>0 ? save_task : evaluate_item
    save_task
  end

  # PUT /v1/tasks/1
  # PUT /v1/tasks/1.xml
  def update
    #~ validate_item(params[:task][:item_id]) if params[:task][:item_id]
    #~ @count.to_i>0 ? update_task : evaluate_item
    update_task
  end

  # DELETE /v1/tasks/1
  # DELETE /v1/tasks/1.xml
 def destroy
   respond_to do |format|
      if @task
         @task.destroy
         format.xml  { render :xml => success.to_xml(ROOT) }
         format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: Validate the item
  def validate_item(value)
    @count=0
    @item=Item.find(value)
    @item.template.template_definitions.each do |item|
      @count=@count+1 if item.has_task_section == true
    end
  end

  # Public: To save task
  def save_task
    respond_to do |format|
      if @task.save
        #~ reminder = params[:reminder][:time]
        #~ @task.reminders.new(:task_id => @task.id, :time => reminder).save unless reminder.blank?
        @task={:task=>@task.serializable_hash(:only=>[:_id,:description,:title,:is_completed],:methods=>:due_date,:include=>{:item=>{:only =>[ :_id,:name]}})}.to_success
        format.xml  { render :xml => @task.to_xml(ROOT) }
        format.json { render :json => @task}
      else
        format.xml  { render :xml => failure.merge(@task.all_errors).to_xml(ROOT)}
        format.json  { render :json => @task.all_errors }
      end
    end
  end

  # Public: Update the task
  def update_task
   respond_to do |format|
      if @task
        if @task.update_attributes(params[:task])
          reminder = @task.reminders[0]
          if reminder.blank? && params[:reminder][:time]
            reminder = params[:reminder][:time]
            @task.reminders.new(:task_id => @task.id, :time => reminder).save unless reminder.blank?
          else
            reminder.update_attributes(params[:reminder]) if params[:reminder]
          end
          @task={:task=>@task.serializable_hash(:only=>[:_id,:description,:title,:is_completed],:methods=>:due_date,:include=>{:item=>{:only =>[ :_id,:name]}})}.to_success
          format.xml  { render :xml => @task.to_xml(ROOT) }
          format.json { render :json => @task}
        else
          format.xml  { render :xml => failure.merge(@task.all_errors).to_xml(ROOT)}
          format.json  { render :json => @task.all_errors }
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: Item evalution
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

	# Public: Adds the reminder to the task
  def add_reminder
		@task=Task.find(params[:reminder][:task_id])
		respond_to do |format|
			if @task
				@reminder=@task.reminders.new(params[:reminder])
				if @reminder.save
					format.xml  { render :xml => reminder_parameters.to_xml(ROOT)}
					format.json  { render :json =>reminder_parameters}
				else
					format.xml  { render :xml => failure.merge(@reminder.all_errors).to_xml(ROOT)}
          format.json  { render :json => @reminder.all_errors }
				end
			else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
			end
		end
  end

	# Public: Updates the single Reminder
  def update_reminder
    respond_to do |format|
      if @reminder
        if @reminder.update_attributes(params[:reminder])
          format.xml  { render :xml => reminder_parameters.to_xml(ROOT) }
          format.json  { render :json =>reminder_parameters}
        else
					format.xml  { render :xml => failure.merge(@reminder.all_errors).to_xml(ROOT)}
          format.json  { render :json => @reminder.all_errors }
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: Deletes the single Reminder
  def delete_reminder
    respond_to do |format|
      if @reminder
       @reminder.destroy
         format.xml  { render :xml => success.to_xml(ROOT) }
         format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

	# Public: Retrieves the single Reminder
  def get_reminder
    respond_to do |format|
      if @reminder
         format.xml  { render :xml => reminder_parameters.to_xml(ROOT) }
         format.json  { render :json=> reminder_parameters}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: Retrieves all reminders of the given task
  def get_all_reminders
    respond_to do |format|
			@task=Task.find(params[:task_id])
      if @task
        @reminders={:task=>@task.serializable_hash(:only=>[:_id],:include=>{:reminders=>{:only=>[:_id,:time]}})}.to_success
        format.json  { render :json=> @reminders}
        format.xml  { render :xml=> @reminders.to_xml(ROOT)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: To find remainder
  def find_reminder
    @reminder=Reminder.find(params[:id])
  end

  # Public: To get remainder parameters
  def reminder_parameters
    reminder={:reminder=>@reminder.serializable_hash(:only=>[:_id],:include=>{:task=>{:only=>[:_id,:description]}})}.to_success
    reminder[:reminder][:time] = @reminder.time.strftime("%d-%m-%Y")
    @reminder = reminder
  end

	 # Public: To find the task
  def find_task
    @task = Task.find(params[:id])
  end
  
  # Public: To get today tasks
  def today_tasks
    @tasks=[]
    @tasks=@current_user.tasks.today_tasks
  end
end