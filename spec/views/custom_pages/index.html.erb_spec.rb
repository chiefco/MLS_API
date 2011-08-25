require 'spec_helper'

describe "custom_pages/index.html.erb" do
  before(:each) do
    assign(:custom_pages, [
      stub_model(CustomPage),
      stub_model(CustomPage)
    ])
  end

  it "renders a list of custom_pages" do
    render
  end
end
