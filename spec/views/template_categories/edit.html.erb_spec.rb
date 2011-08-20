require 'spec_helper'

describe "template_categories/edit.html.erb" do
  before(:each) do
    @template_category = assign(:template_category, stub_model(TemplateCategory))
  end

  it "renders the edit template_category form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => template_categories_path(@template_category), :method => "post" do
    end
  end
end
