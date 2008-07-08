require File.dirname(__FILE__) + '/../test_helper'

class PersistenceTest < ActiveSupport::TestCase

  def setup
    @foo_class = Class.new do
      include FakeRecord::Persistence

      # add a logger since otherwise it uses the Base's logger
      def logger
        RAILS_DEFAULT_LOGGER
      end
    end
    @foo = @foo_class.new
  end

  def test_truth
    assert true
  end

  def test_initialize
    @foo_class.class_eval do
      attr_accessor :initialized

      def initialize
        self.initialized = true
      end
    end

    foo = @foo_class.new
    assert_equal true, foo.initialized, "The initializer of the class should have been invoked."
    assert_equal true, foo.new_record?, "All records created via new should be 'new' after initialization."
  end

  def test_new_record?
    @foo_class.class_eval do
      def was_saved= val; @was_saved = val end
    end

    foo = @foo_class.new

    assert_equal true, foo.new_record?
    assert_equal false, foo.saved_record?
    foo.was_saved = true
    assert_equal false, foo.new_record?
    assert_equal true, foo.saved_record?
  end

  def test_create
    @foo_class.class_eval do
      attr_accessor :create_invoked, :create_return
      def custom_create; self.create_invoked = true; create_return end
    end
    foo = @foo_class.new

    foo.create_return = false

    assert_equal nil, foo.create_invoked
    assert_equal true, foo.new_record?

    assert_equal false, foo.save, "Save should have failed."
    assert_equal true, foo.create_invoked, "Custom create should have been invoked."
    assert_equal true, foo.new_record?, "New record should stay new after a failed create."
    
    foo.create_return = true
    foo.create_invoked = false
    assert_equal false, foo.create_invoked

    assert_equal true, foo.save, "Save should have been successful."
    assert_equal true, foo.create_invoked, "Custom create should have been invoked."
    assert_equal false, foo.new_record?, "Record should stop being new since it has been created."
  end

  def test_update
    @foo.metaclass.class_eval do
      attr_accessor :update_invoked, :update_return
      def custom_update; self.update_invoked = true; update_return end
    end

    @foo.update_return = false

    assert_equal true, @foo.save, "Should manage to save since update returned false."
    assert_equal nil, @foo.update_invoked, "Should not have invoked update for the first save."
    assert_equal false, @foo.new_record?, "Should be an old record now."

    assert_equal false, @foo.save, "Save should have failed since update should have failed."
    assert_equal true, @foo.update_invoked, "Custom update should have been invoked."
    assert_equal false, @foo.new_record?, "Should stay to be an old record even though the save has failed."

    @foo.update_return = true
    @foo.update_invoked = false
    assert_equal true, @foo.save, "Should manage to save since update returns now true."
    assert_equal true, @foo.update_invoked, "Update should have been invoked."
    assert_equal false, @foo.new_record?, "Should still be an old record."
  end

  def test_invalid_save
    @foo.metaclass.class_eval do
      def valid?; false end
    end

    assert_equal false, @foo.save, "Foo should manage to save if valid? returns false."
  end

  def test_save!
    @foo.metaclass.class_eval do
      attr_accessor :save_invoked, :save_return
      def save; self.save_invoked = true; save_return end
    end

    assert_raise ActiveRecord::RecordNotSaved, "Should raise exception if underlying save call returned false." do
      @foo.save!
    end

    assert_equal true, @foo.save_invoked, "Underlying save should have been invoked."

    @foo.save_invoked = false
    @foo.save_return = true

    assert_nothing_raised("Should be able to save successfully if underlying save return true.") { @foo.save! }
    assert_equal true, @foo.save_invoked, "save should have been invoked again."
  end
end
