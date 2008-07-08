require File.dirname(__FILE__) + '/../test_helper'

class ValidationsTest < ActiveSupport::TestCase

  def setup
    @foo_class = Class.new { include FakeRecord::Validations }
    @foo = Class.new(@foo_class).new
  end

  def test_truth
    assert true
  end

  def test_class_methods_inclusion
    FakeRecord::Validations::ClassMethods.instance_methods.each do |method|
      assert @foo_class.respond_to?(method), "Method #{method} should have been added to a class when Validations module is included."
    end
  end

  def test_add_validation
    foo = Class.new(@foo_class).new
    assert_equal [], foo.validations, "@foo should have no validations by default."

    tautological_validation = proc { true }
    foo.class.send(:add_validation, tautological_validation)
    assert_equal [tautological_validation], foo.validations, "Validations should contain only the added tautological validation."

    assert_equal [], @foo_class.new.validations, "A new instance of @foo_class should still contain no validations since the validation was added to @foo."
  end

  def test_errors
    foo = @foo_class.new
    assert foo.errors.blank?, "Errors should be blank by default."
  end

  def test_run_validations
    @foo.metaclass.class_eval do
      attr_accessor :validate_invoked
      def validate; self.validate_invoked = true end
    end

    assert !@foo.validate_invoked, "Validate should have been not invoked after instantiation."
    @foo.run_validations
    assert_equal true, @foo.validate_invoked, "Validate should have been invoked when validations were run."
  end

  def test_valid?
    @foo.metaclass.class_eval do
      attr_accessor :errors_to_add
      def validate; (errors_to_add || {}).each_pair { |attr, msg| errors.add attr, msg } end
    end

    assert_equal true, @foo.valid?, "Should be valid if no errors were added" 
    @foo.errors_to_add = { :foo => "bad foo", :bar => "Bad bar" }
    assert_equal false, @foo.valid?, "Should be invalid since errors were added."
  end

  def test_validate_without_block
    @foo.class.class_eval do
      attr_accessor :foo, :validation_invoked
      def validate_foo; validation_invoked = true; errors.add(:foo, "foo must be equal to :bar") if foo != :bar end
      validate :validate_foo
    end

    assert_equal nil, @foo.validation_invoked, "Foo's validation should not have been invoked yet."
    assert_equal 1, @foo.validations.size
    assert_equal false, @foo.valid?, "@foo must be invalid."
    assert_equal [ "foo must be equal to :bar" ], @foo.errors.on(:foo), "Wrong errors for foo."

    @foo.foo = :bar
    assert_equal true, @foo.valid?, "@foo with foo set to :bar should be valid."
  end

  def test_validate_with_block
    @foo.class.class_eval do
      attr_accessor :foo
      def validate_foo; errors.add(:foo, "foo must be equal to :bar") if foo != :bar end
      validate { |foo| foo.validate_foo }
    end

    assert_equal 1, @foo.validations.size
    assert_equal false, @foo.valid?, "@foo must be invalid with :foo not set."
    @foo.foo = :bar
    assert_equal true, @foo.valid?, "@foo should be valid when :foo is set to :bar."
  end

  def test_validates_presence_of
    @foo.class.class_eval do
      attr_accessor :bar
      validates_presence_of :bar
    end

    assert_equal 1, @foo.validations.size, "@foo should have 1 validations about bar's presence."
    assert_equal nil, @foo.bar
    assert_equal false, @foo.valid?, "Foo should be invalid since bar is nil."
    assert_equal [ FakeRecord::Errors.default_error_messages[:blank] ], @foo.errors.on(:bar)
    
    @foo.bar = :foo
    assert_equal true, @foo.valid?, "Foo should be valid since bar has been set."
  end

  # This test illustrates the point that objects of same class share validations.
  def test_sharing_of_validations
    a_class = Class.new(@foo_class)
    b_class = Class.new(a_class)

    make_validation = proc { Proc.new { true } }
    vals = 4.inject([]) do |acc, i| 
      val = make_validation.call
      val.metaclass.send(:define_method, :to_s) { "validation_#{i}" }
      [acc, val].flatten
    end

    a_class.send(:add_validation, vals[0])
    b_class.send(:add_validation, vals[1])

    a = a_class.new
    b = b_class.new
    c = b_class.new

    assert_equal [vals[0]], a.validations, "a should contain only validations of A and no validations of subclass B."
    assert_equal [vals[1]], b.validations
    assert_equal [vals[1]], c.validations

    c.metaclass.send(:add_validation, vals[2])
    assert_equal [vals[1]], c.validations, "Adding a validation to metaclass should not affect validations returned."

    c.class.send(:add_validation, vals[3])
    assert_equal [vals[1], vals[3]], c.validations, "Adding a validation to a class should be reflected."
    assert_equal [vals[1], vals[3]], b.validations, "Adding a validation to a class should be also reflected in the sibling instances."
  end
end
