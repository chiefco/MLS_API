class CustomDatas
	def list
		@methods=["Item","Category","Location","Industry","Template","Search","Contact","Comment","User","Activity"]
		Dir.mkdir("#{Rails.root.to_s}/dummy_jsons") if (!File.directory?("#{Rails.root.to_s}/dummy_jsons"))
		path=Yamler.load("#{Rails.root.to_s}/config/mls_end_point.yml", {:locals => {:id => nil} })
		@methods.each do |g|
			response=HTTParty.get("http://localhost:3000/v1/#{path[g][:list]}",:query=>{:access_token=>"Bwi0D8DD2WmB82MyYspXRhWhVaxKZnwx"}).to_json
			File.open("#{Rails.root.to_s}/dummy_jsons/#{g}_list", 'w') {|f| f.write(response) }
		end
	end
	def view
		@methods=["Item","Category","Location","Template","Search","Contact","Comment"]
		@methods.each do |g|
			id=eval(g).first.nil? ? nil : eval(g).first._id
			path=Yamler.load("#{Rails.root.to_s}/config/mls_end_point.yml", {:locals => {:id => id} })
			response=HTTParty.get("http://localhost:3000/v1/#{path[g][:view]}/#{id}",:query=>{:access_token=>"Bwi0D8DD2WmB82MyYspXRhWhVaxKZnwx"}).to_json unless id.nil?
			File.open("#{Rails.root.to_s}/dummy_jsons/#{g}_view", 'w') {|f| f.write(response) } unless id.nil?
		end
	end
	def delete
		@methods=["Item","Category","Location"]
		@methods.each do |g|
			id=eval(g).first.nil? ? nil : eval(g).first._id
			path=Yamler.load("#{Rails.root.to_s}/config/mls_end_point.yml", {:locals => {:id => id} })
			response=HTTParty.delete("http://localhost:3000/v1/#{path[g][:delete]}/#{id}",:query=>{:access_token=>"Bwi0D8DD2WmB82MyYspXRhWhVaxKZnwx"}).to_json unless id.nil?
			File.open("#{Rails.root.to_s}/dummy_jsons/#{g}_delete", 'w') {|f| f.write(response) } unless id.nil?
		end
	end
end
