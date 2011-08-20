require 'spec_helper'

describe "TemplateCategories" do
  describe "GET /template_categories" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get template_categories_path
      response.status.should be(200)
    end
  end
end
