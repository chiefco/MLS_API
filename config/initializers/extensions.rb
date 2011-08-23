#Add error codes with the error messages
module ActiveModel
  class Errors < ActiveSupport::OrderedHash
    def add(attribute, message = nil, options = {})
      message ||= :invalid
      if message.is_a?(Symbol)
        message = generate_message(attribute, message, options.except(*CALLBACKS_OPTIONS))
      elsif message.is_a?(Proc)
        message = message.call
      end
      self[attribute] << {:code=>options[:code], :message=>message}
    end
  end
end

module Mongoid #:nodoc:
  module Document
  mattr_accessor :id
    def all_errors
      self.errors.values.flatten
    end
    
    def as_json(options={})
      attrs = super(options)
      if attrs.has_key?("_id")
        attrs["id"]=attrs["_id"]
        attrs.delete("_id")
      end
      attrs
    end
    
    def id
      {:id=>self._id}
    end
  end
end

class Hash
  def recursive_symbolize_keys!
    symbolize_keys!
    values.select{ | v | v.is_a?( Hash ) }.each{ | h | h.recursive_symbolize_keys! }
    self
  end
  
  def to_success
    {:response=>:success}.merge(self)
  end
  
  def to_failure
    {:response=>:failure}.merge(self)
  end
end

class String
  def decode_credentials
    Base64.decode64(self).split #decodes the credentials as [email,password]
  end
end

#~ #Error code for routing errors

#~ module ActionDispatch
  #~ class ShowExceptions
    #~ def render_exception(env, exception)
      #~ error=[{:message=>'bad request',:code=>9001}]
      #~ method='.to_json'
      #~ method='.to_xml(:root=>"errors")' if env['HTTP_ACCEPT']=='application/xml'
      #~ if exception.kind_of? ActionController::RoutingError
        #~ render(404, eval("#{error}#{method}"))
      #~ else
        #~ render(500, 'Something went wrong')
      #~ end
    #~ end
  #~ end
#~ end

#generate the token value
module ForDevise
  def self.friendly_token(count=15)
    SecureRandom.base64(count).tr('+/=', 'xyz')
  end
end
 