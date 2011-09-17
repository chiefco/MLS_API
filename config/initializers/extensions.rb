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
      {:response=>:failure,:errors=>self.errors.values.flatten}
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
    
    def sunspot_index
      Sunspot.index!(self)
      true
    end
  end

  module Serialization
    def serializable_hash(options = nil)
      hash = super(options)
      hash["id"] = hash.delete("_id") if hash && hash.has_key?("_id")
      hash
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

class Array
  def attributes
    self.collect! do |record|
      record=record.attributes if record.kind_of?(Mongoid::Document)
    end
  end
end

class String
  def decode_credentials
    Base64.decode64(self).split #decodes the credentials as [email,password]
  end

  def parse
    JSON.parse(self)
  end

  def as_hash
    Hash.from_xml(self)
  end

end

#Error code for routing errors

module ActionDispatch
  class ShowExceptions
    def render_exception(env, exception)
      error=[{:message=>'bad request',:code=>9001}]
      error2=[{:message=>'Something went wrong',:code=>500}]
      method='.to_json'
      method='.to_xml(:root=>"errors")' if env['HTTP_ACCEPT']=='application/xml'
      if exception.kind_of? ActionController::RoutingError
        render(404, eval("#{error}#{method}"))
      else
        render(500, eval("#{error2}#{method}"))
      end
    end
  end
end

#generate the token value
module ForDevise
  def self.friendly_token(count=15)
    SecureRandom.base64(count).tr('+/=', 'xyz')
  end
end

#added to customize authentication_token length
Devise.instance_eval do
  def friendly_token(len=15)
    SecureRandom.base64(len).tr('+/=', 'xyz')
  end
end

#added to customize authentication_token length
Devise::Models::Authenticatable::ClassMethods.module_exec do
  def generate_token(column)
    loop do
      token = column.eql?(:authentication_token) ? Devise.friendly_token(24) : Devise.friendly_token
      break token unless to_adapter.find_first({ column => token })
    end
  end
end