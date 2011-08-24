require 'spec_helper'

describe "custom_pages/new.html.erb" do
  before(:each) do
    assign(:custom_page, stub_model(CustomPage).as_new_record)
  end

  it "renders new custom_page form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => custom_pages_path, :method => "post" do
    end
  end
end
