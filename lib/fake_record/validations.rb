module FakeRecord
  module Validations

    def self.included base
      base.extend ClassMethods
    end

    def validate; end

    def errors
      @errors ||= FakeRecord::Errors.new(self)
    end

    def run_validations
      self.errors.clear
      validate
      self.validations.each { |class_validation| instance_eval &class_validation }
    end

    def valid?
      run_validations
      errors.blank?
    end

    def validations
      self.class.read_inheritable_set :validation
    end

    module ClassMethods
      
      def validate *methods, &block
        methods.each { |method| add_validation(proc { self.send(method) }) }
        add_validation(proc { block.call(self) }) if block_given?
      end

      def validates_presence_of *args
        options = args.last.is_a?(Hash) ? args.pop : {}

        message = options[:message] || FakeRecord::Errors.default_error_messages[:blank]
        args.each do |field|
          add_validation(proc do 
            if self.send(field).blank? 
              errors.add field, message
              false
            else
              true
            end
          end)
        end
      end

      def read_inheritable_set key
        read_inheritable_attribute(key) || []
      end

      protected

      def add_validation *validations
        write_inheritable_set :validation, validations
      end

      private

      def write_inheritable_set(key, methods)
        existing_methods = read_inheritable_attribute(key) || []
        write_inheritable_attribute(key, existing_methods | methods)
      end
    end # ClassMethods
  end # Validations
end
