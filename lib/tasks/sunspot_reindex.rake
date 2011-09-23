namespace :sunspot do
  desc "indexes searchable models"
  task :index => :environment do
    [Item, Category, Bookmark, Location].each {|model| Sunspot.index!(model.all)}
  end
end