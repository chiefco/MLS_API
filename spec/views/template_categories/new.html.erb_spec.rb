require 'spec_helper'

describe "template_categories/new.html.erb" do
  before(:each) do
    assign(:template_category, stub_model(TemplateCategory).as_new_record)
  end

  it "renders new template_category form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => template_categories_path, :method => "post" do
    end
  end
end
