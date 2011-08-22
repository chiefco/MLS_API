require 'spec_helper'

describe "v1/bookmarks/index.html.erb" do
  before(:each) do
    assign(:v1_bookmarks, [
      stub_model(V1::Bookmark,
        :name => "Name"
      ),
      stub_model(V1::Bookmark,
        :name => "Name"
      )
    ])
  end

  it "renders a list of v1/bookmarks" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
  end
end
