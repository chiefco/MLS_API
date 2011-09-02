class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sunspot::Mongoid
  SORT_BY_ALLOWED = [ :due_date, :is_completed, :description]
  ORDER_BY_ALLOWED =  [:asc,:desc]
  field :due_date, :type => Time
  field :is_completed,:type=> Boolean,:default=>false
  field :assignee_id,:type=> String
  field :description,:type=> String
  references_many :reminders
  has_many :activities, as: :activity, :dependent=>:destroy
  referenced_in :user
  referenced_in :item
  validates_presence_of :description,:code=>"3014",:message=>"description - Blank Parameter"
  after_save :sunspot_index
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
    query +='.where(:due_date.gt=>params[:current_task].to_time,:due_date.lt=>params[:current_task].to_time.tomorrow)' if params[:current_task]
    query +='.where(:due_date.lt=>Date.today)' if params[:late_task]
    query +='.where(:due_date.gt=>Date.today)' if params[:pending_task]
    query +='.where(:activity_type=>params[:activity_type])' if params[:activity_type]
    query += '.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)'
    eval(query)
  end

  def self.get_criteria(query)
    [ {due_date: query} , { description: query }, { is_completed: query }]
  end
 end
