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
    def all_errors
      self.errors.values.flatten
    end
  end
end

class Hash
  def recursive_symbolize_keys!
    symbolize_keys!
    values.select{ | v | v.is_a?( Hash ) }.each{ | h | h.recursive_symbolize_keys! }
    self
  end
end

class String
  def decode_credentials
    Base64.decode64(self).split #decodes the credentials as [email,password]
  end
end