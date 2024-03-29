class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sunspot::Mongoid
  include_root_in_json
  SORT_BY_ALLOWED = [ :due_date, :is_completed, :description]
  ORDER_BY_ALLOWED =  [:asc,:desc]
  #~ STATUS_TASK=[:current_task,:late_task,:pending_task]
  field :title, :type => String
  field :due_date, :type => Time
  field :is_completed,:type=>Boolean,:default=>false
  field :assignee_id,:type=> String
  field :description,:type=> String
  field :sync_status,:type=> Boolean,:default=>false
  references_many :reminders
  has_many :activities, as: :activity, :dependent=>:destroy
  referenced_in :user
  referenced_in :item
  validates_presence_of :title,:code=>3083,:message=>"title-blank_parameter - Blank Parameter"
  after_save :sunspot_index
  scope :completed_tasks,self.where(:due_date.gt=>Date.today,:due_date.lt=>Date.tomorrow).excludes(:is_completed=>false)
  scope :today_tasks,self.where(:due_date.gt=>Date.today,:due_date.lt=>Date.tomorrow)
  searchable do
    text :description
    date :due_date
    string :user_id
  end

  def task_item
    {:item=>self.item.nil?  ? "nil" : self.item.to_json(:only=>[:_id,:name])}
  end

  def self.list(params,paginate_options,user)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    query = 'user.tasks'
    query += '.any_of(self.get_criteria(params[:q]))' if params[:q]
    query +='.where(:due_date.gt=>Date.today,:due_date.lt=>Date.tomorrow)' if params.include? "current_task"
    query +='.where(:due_date.lt=>Date.today)' if params.include? "late_task"
    query +='.where(:due_date.gt=>Date.today)' if params.include? "pending_task"
    if params.include? "completed"
      query +='.where(:is_completed=>true)'
    else
      query +='.where(:is_completed=>false)'
    end
    query +='.where(:activity_type=>params[:activity_type])' if params[:activity_type]
    query += '.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)'
    eval(query)
  end

  #~ def self.today_completed_percentage(user)
    #~ today_tasks=user.tasks.today_tasks.count.to_i
    #~ today_completed_tasks=user.tasks.completed_tasks.count.to_i
    #~ completed_percentage=today_tasks.zero? ? 0 : today_completed_tasks/today_tasks * 100
  #~ end

  def self.get_criteria(query)
    [ {due_date: query} , { description: query }, { is_completed: query }]
  end
 end
