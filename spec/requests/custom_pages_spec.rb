require 'spec_helper'

describe "CustomPages" do
  describe "GET /custom_pages" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get custom_pages_path
      response.status.should be(200)
    end
  end
end
