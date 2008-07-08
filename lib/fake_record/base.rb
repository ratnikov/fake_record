module FakeRecord
  class Base

    include Persistence

    def initialize attributes = nil
      self.attributes = attributes unless attributes.nil?
      @new_record = true
      self
    end

    def attributes= attributes
      attributes.each_pair do |field, value|
        update_attribute field, value
      end
      attributes
    end

    def has_attribute? attribute
      self.respond_to?("#{attribute}=") && self.respond_to?(attribute)
    end

    def update_attribute field, value
      if has_attribute? field
        send("#{field}=", value)
        true
      else
        raise "Unknown attribute: #{field.inspect}."
      end
    end

    def logger
      RAILS_DEFAULT_LOGGER
    end
  end
end
