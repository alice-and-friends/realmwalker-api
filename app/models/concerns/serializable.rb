# https://codeburst.io/json-serialized-columns-with-rails-a610a410fcdf

module Serializable
  extend ActiveSupport::Concern
  def initialize(json)
    unless json.blank?
      if json.is_a?(String)
        json = JSON.parse(json)
      end
      # Will only set the properties that have an accessor,
      # such as those provided to an attr_accessor call.
      json.to_hash.each do |k, v| self.public_send("#{k}=", v) if self.respond_to? k
      end
    end
  end
  class_methods do
    def load(json)
      return nil if json.blank?
      self.new(json)
    end
    def dump(obj)
      # Make sure the type is right.
      if obj.is_a?(self)
        obj.to_json
      else
        raise StandardException, "Expected #{self}, got #{obj.class}"
      end
    end
  end
end
