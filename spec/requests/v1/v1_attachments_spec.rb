require 'spec_helper'

describe "V1::Attachments" do
  describe "GET /v1_attachments" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get v1_attachments_path
      response.status.should be(200)
    end
  end
end
