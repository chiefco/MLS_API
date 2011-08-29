require 'spec_helper'

describe "tasks/new.html.erb" do
  before(:each) do
    assign(:task, stub_model(Task,
      :is_completed => false,
      :assignee_id => "MyString"
    ).as_new_record)
  end

  it "renders new task form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => tasks_path, :method => "post" do
      assert_select "input#task_is_completed", :name => "task[is_completed]"
      assert_select "input#task_assignee_id", :name => "task[assignee_id]"
    end
  end
end
