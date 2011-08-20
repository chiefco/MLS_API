require 'spec_helper'

describe "template_categories/index.html.erb" do
  before(:each) do
    assign(:template_categories, [
      stub_model(TemplateCategory),
      stub_model(TemplateCategory)
    ])
  end

  it "renders a list of template_categories" do
    render
  end
end
