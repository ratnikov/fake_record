require File.dirname(__FILE__) + '/../test_helper'

class ErrorsTest < ActiveSupport::TestCase

  def setup
    @base_model = :bar
    @errors = FakeRecord::Errors.new @base_model
  end

  def test_truth
    assert true
    assert FakeRecord::Errors.include?(Enumerable), "Errors class should include Enumerable mixin."
  end

  def test_full_messages
    base_msg = "There were very basic (as opposed to acidic) errors."
    @errors.add_to_base base_msg

    attr_messages = { :foo => [ "is a bad foo", "is a silly foo"], :bar => "is a very bad bar" }
    attr_messages.each_key { |attr| [*attr_messages[attr]].each { |msg| @errors.add attr, msg } }

    full_msgs = @errors.full_messages
    assert full_msgs.include?(base_msg), "The full errors should contain base message #{base_msg.inspect} (messages returned: #{full_msgs.inspect})."
    attr_messages.each_key do |attr|
      attr_messages[attr].to_a.each do |msg|
        assert full_msgs.include?("#{attr.to_s.humanize} #{msg}"), 
          "Full error messages should contain message for attribute #{attr.inspect} with message #{msg.inspect} (messages returned: #{full_msgs.inspect})."
      end
    end
  end

  def test_each
    errors_to_add = {
      "Bad foo" => "foo",
      "Bad bar" => "bar",
      "Very bad foo" => "foo",
    }

    errors_to_add.each_pair { |msg, attr| @errors.add attr, msg }
    @errors.each { |attr, msg| assert_equal attr, errors_to_add[msg], "Wrong attribute for message #{msg.inspect}. Error hash: #{@errors.error_hash.inspect}." }
  end

  def test_add
    assert @errors.blank?, "Should contain no errors by default."

    expected_error_hash = {}
    assert_equal expected_error_hash, @errors.error_hash, "The error hash should be empty."

    @errors.add :foo, "Bad foo"
    assert_equal expected_error_hash.merge!(:foo => [ "Bad foo" ]), @errors.error_hash, "The hash should have been set to one error on foo."
    @errors.add :bar, "Bad bar"
    assert_equal expected_error_hash.merge!(:bar => [ "Bad bar" ]), @errors.error_hash, "Should contain an error about foo and an error about bar."

    @errors.add :foo, "Very bad foo"
    assert_equal expected_error_hash.merge!(:foo => [ "Bad foo", "Very bad foo" ]), @errors.error_hash, "Should contain two errors about foo and one error about bar."
  end

  def test_add_to_base
    @errors.metaclass.class_eval do 
      attr_accessor :add_invoked; 
      def add(*args)
        self.add_invoked = true; super(*args) 
      end
    end

    @errors.add_to_base "Evil base error"
    assert_equal true, @errors.add_invoked, "Should have invoked the add method to add the base error."
    assert_equal({ :base => [ "Evil base error" ] }, @errors.error_hash, "Expected error hash to contain just one base error.")
  end

  def test_on
    @errors.add :foo, "Bad foo"
    @errors.add :bar, "Bad bar"
    @errors.add :foo, "Very bad foo"
    assert_equal ["Bad foo", "Very bad foo"], @errors.on(:foo), "Wrong errors for :foo"
    assert_equal [ "Bad bar" ], @errors.on(:bar), "Wrong errors for :bar"
  end

  [:empty?, :blank?].each do |empty_method|
    define_method "test_#{empty_method}" do
      assert_equal true, @errors.send(empty_method), "#{empty_method} should return true for a just created error object."
      @errors.add :foo, "Bad foo"
      assert_equal false, @errors.send(empty_method), "#{empty_method} should return false when error contains errors."
    end
  end

  def test_clear
    @errors.add :foo, "Bad foo"
    assert_equal false, @errors.empty?, "Should not be empty."
    @errors.clear
    assert_equal true, @errors.empty?, "Should be empty after being cleared."
  end

  def test_count
    assert_equal 0, @errors.count, "Count should return 0 for a new error object."
    errors_to_add = rand 10; errors_to_add.times { |i| @errors.add "foo #{i}", "Bad foo \##{i}" }
    assert_equal errors_to_add, @errors.count, "Count should return amount of added errors."

    @errors.clear
    2.times { |i| @errors.add :foo, "Bad foo #{i}." }
    assert_equal 1, @errors.count, "Should still contain only one error even if many messages."
  end
end
