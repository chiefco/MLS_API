if defined?(Mongoid::Document)
  Mongoid::Document.send :include, ActsAsApi::Adapters::Mongoid 
  Mongoid::Document.send :include, Mongoid::Timestamps
end