require 'spec_helper'

describe "template_categories/show.html.erb" do
  before(:each) do
    @template_category = assign(:template_category, stub_model(TemplateCategory))
  end

  it "renders attributes in <p>" do
    render
  end
end
