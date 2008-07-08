module FakeRecord
  module Persistence

    def self.included base
      base.send :include, FakeRecord::Validations
    end

    def custom_create; logger.warn "Called the empty custom_create stub." end
    def custom_update; logger.warn "Called the empty custom_update stub." end

    def saved_record?
      @was_saved || false
    end

    def new_record?
      ! saved_record?
    end

    def save
      if valid?
        if new_record?
          create
        else
          update
        end
      else
        false
      end
    end

    def save!
      save || raise(ActiveRecord::RecordNotSaved)
    end

    private
    def create
      if custom_create
        @was_saved = true
        true
      else
        false
      end
    end

    def update
      custom_update
    end
  end
end
