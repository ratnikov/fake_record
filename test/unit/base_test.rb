require File.dirname(__FILE__) + '/../test_helper'

class BaseTest < ActiveSupport::TestCase
  
  def setup
    @record = FakeRecord::Base.new
  end

  def test_truth
    assert true

    assert FakeRecord::Base.include?(FakeRecord::Persistence)
  end

  def test_has_attribute?

    assert_equal false, @record.has_attribute?(:foo), "Record should not have :foo attribute before it got woven in."

    @record.metaclass.class_eval do
      attr_accessor :foo
      def bar=; end
      def zeta; end
    end

    assert_equal true, @record.has_attribute?(:foo), "Record should have attribute after being woven in."
    assert_equal false, @record.has_attribute?(:bar), "Record should not consider items that only have setters as attribute."
    assert_equal false, @record.has_attribute?(:zeta), "Record should not consider items that only have getters as attribute."
  end

  def test_update_attribute
    @record.metaclass.class_eval do
      attr_accessor :foo, :foo_set
      def foo= new_foo
        self.foo_set = true
        @foo = new_foo
      end
    end

    assert_equal nil, @record.foo_set, "Foo should have not been called before update."
    assert_equal true, @record.update_attribute(:foo, "foobar"), "Attribute update should return true as the attribute was successfully updated."
    assert_equal true, @record.foo_set, "Foo should have been set."
    assert_equal "foobar", @record.foo, "Foo should have been set to foobar."

    assert_raise RuntimeError do
      @record.update_attribute :unknown_attribute, "barzimo"
    end
  end

  def test_attributes_setter
    @record.metaclass.class_eval do
      attr_accessor :foo, :bar, :foo_set, :bar_set

      def update_attribute field, value
        send "#{field}_set=", true
        super field, value
      end
    end

    [:foo, :bar].each { |field| assert_equal nil, @record.send("#{field}_set"), "#{field} should not be set before the update takes place." }
    @record.attributes = { :foo => "alpha", :bar => :beta }
    assert_equal true, @record.foo_set, "Foo setter should have been called."
    assert_equal "alpha", @record.foo, "Foo should have been set to correct value."

    assert_equal true, @record.bar_set, "Bar update_attribute should have been called."
    assert_equal :beta, @record.bar, "Bar should have been set to correct value."
  end

  def test_logger
    assert_equal RAILS_DEFAULT_LOGGER, @record.logger, "Record logger should be the rails default logger."
  end
    
end
