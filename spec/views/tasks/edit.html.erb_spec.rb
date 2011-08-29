require 'spec_helper'

describe "tasks/edit.html.erb" do
  before(:each) do
    @task = assign(:task, stub_model(Task,
      :is_completed => false,
      :assignee_id => "MyString"
    ))
  end

  it "renders the edit task form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => tasks_path(@task), :method => "post" do
      assert_select "input#task_is_completed", :name => "task[is_completed]"
      assert_select "input#task_assignee_id", :name => "task[assignee_id]"
    end
  end
end
