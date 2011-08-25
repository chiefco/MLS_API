require 'spec_helper'

describe "custom_pages/show.html.erb" do
  before(:each) do
    @custom_page = assign(:custom_page, stub_model(CustomPage))
  end

  it "renders attributes in <p>" do
    render
  end
end
