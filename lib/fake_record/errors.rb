module FakeRecord
  class Errors
    include Enumerable

    attr_accessor :base, :error_hash

    def initialize base
      self.base = base
      self.error_hash = {}
    end

    @@default_error_messages = {
      :blank => "can't be blank",
    }

    cattr_accessor :default_error_messages

    # returns a humanized list of error messages (in no particular order)
    def full_messages
      error_hash.keys.inject([]) do |acc, error_key|
        if error_key == :base
          # append all the base errors "as is"
          [acc, error_hash[error_key]].flatten
        else
          # append all errors with a humanized attribute name + the error message
          [acc, error_hash[error_key].map { |msg| "#{error_key.to_s.humanize} #{msg}" } ].flatten
        end
      end
    end

    # adds an error message which is not specifically tied to any attribute.
    def add_to_base msg
      add(:base, msg)
    end

    # adds an error for the specified attribute
    def add attribute, msg = default_error_messages[:invalid]
      error_hash[attribute] ||= [] # initialize the errors array for the attribute if necessary
      error_hash[attribute] << msg
    end

    # returns errors on the specified attribute
    def on(attr)
      error_hash[attr] || []
    end

    # implents each to for the Enumerable mixin by yielding to each attr/msg pair available in errors hash.
    def each
      raise "Missing block." unless block_given?
      error_hash.each_key { |attr| error_hash[attr].each {|msg| yield attr, msg } } 
    end

    [:empty?, :blank?, :clear, :size ].each do |delegated_method|
      define_method delegated_method do
        error_hash.send(delegated_method)
      end
    end
    alias count size
  end
end
