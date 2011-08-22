require 'spec_helper'

describe "v1/bookmarks/show.html.erb" do
  before(:each) do
    @v1_bookmark = assign(:v1_bookmark, stub_model(V1::Bookmark,
      :name => "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
  end
end
