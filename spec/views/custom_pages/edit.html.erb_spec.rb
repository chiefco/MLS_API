require 'spec_helper'

describe "custom_pages/edit.html.erb" do
  before(:each) do
    @custom_page = assign(:custom_page, stub_model(CustomPage))
  end

  it "renders the edit custom_page form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => custom_pages_path(@custom_page), :method => "post" do
    end
  end
end
