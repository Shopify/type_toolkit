# frozen_string_literal: true

require "spec_helper"

module TypeToolkit
  class AbstractClassSpec < Minitest::Spec
    # A class that has some abstract methods.
    # *Note* this is _not_ an abstract class.
    class AbstractClass
      abstract!

      abstract def m1; end
      abstract def m2; end

      def concrete_method = "AbstractClass#concrete_method"
    end

    # A class that does not implement any of `AbstractClass`'s abstract methods.
    class NonImpl < AbstractClass
    end

    class PartialImpl < AbstractClass
      def m1 = "PartialImpl#m1"
      # Does not implement `m2`
    end

    class FullImpl < AbstractClass
      def m1 = "FullImpl#m1"
      def m2 = "FullImpl#m2"
    end

    describe "An abstract class" do
      it "cannot be instantiated" do
        assert_raises(CannotInstantiateAbstractClassError) { AbstractClass.new }
      end

      describe ".abstract_instance_methods" do
        it "only contains the abstract methods" do
          assert_equal [:m1, :m2], AbstractClass.abstract_instance_methods
          assert_equal [:m1, :m2], AbstractClass.abstract_instance_methods(true)
          assert_equal [:m1, :m2], AbstractClass.abstract_instance_methods(false)
        end
      end

      describe ".abstract_method?" do
        it "returns true for abstract methods" do
          assert AbstractClass.abstract_method?(:m1)
          assert AbstractClass.abstract_method?(:m2)
        end

        it "returns false for non-abstract methods" do
          refute AbstractClass.abstract_method?(:concrete_method)
        end
      end

      describe ".abstract_method_declared?" do
        it "returns true for abstract methods" do
          assert AbstractClass.abstract_method_declared?(:m1)
          assert AbstractClass.abstract_method_declared?(:m2)
        end

        it "returns false for non-abstract methods" do
          refute AbstractClass.abstract_method_declared?(:concrete_method)
        end
      end
    end

    describe "A subclass that does not implement any abstract methods" do
      before do
        @class = NonImpl
      end

      it "can be instantiated" do
        # ...despite not implementing all the abstract methods. This matches sorbet runtime's behaviour.
        #
        # The Sorbet static typechecker ensures that when you subclass an abstract class, you must either:
        # 1. Implement all of its abstract methods.
        # 2. Mark the subclass as abstract! as well.
        #
        # Attempting to call actually any of the abstract methods will still raise, like usual.
        refute_nil @class.new
      end

      it "does not respond to .__original_allocate_impl" do
        refute_respond_to @class, :__original_allocate_impl
        assert_raises(NoMethodError) { @class.__original_allocate_impl }
      end

      describe ".abstract_method?" do
        it "returns true for abstract methods that have not been implemented" do
          assert @class.abstract_method?(:m1)
          assert @class.abstract_method?(:m2)
        end

        it "returns false for non-abstract methods" do
          refute @class.abstract_method?(:concrete_method)
        end
      end

      describe ".abstract_method_declared?" do
        it "is true for all abstract methods" do
          assert @class.abstract_method_declared?(:m1)
          assert @class.abstract_method_declared?(:m2)
        end

        it "is false for non-abstract methods" do
          refute @class.abstract_method_declared?(:concrete_method)
        end
      end

      describe ".abstract_instance_methods" do
        it "returns all abstract methods" do
          assert_equal [:m1, :m2], @class.abstract_instance_methods
          assert_equal [:m1, :m2], @class.abstract_instance_methods(true)
          assert_equal [], @class.abstract_instance_methods(false)
        end
      end
    end

    describe "A subclass that partially implements the abstract methods" do
      before do
        @class = PartialImpl
        @x = PartialImpl.new
      end

      describe "calling an implemented abstract method" do
        it "calls the concrete implementation" do
          assert_respond_to @x, :m1
          assert_equal "PartialImpl#m1", @x.m1
          assert_equal "PartialImpl#m1", @x.method(:m1).call
          refute_predicate @x.method(:m1), :abstract?
          refute_predicate @x.method(:m1).unbind, :abstract?
        end
      end

      describe "calling an unimplemented abstract method" do
        it "raises AbstractMethodNotImplementedError" do
          assert_respond_to @x, :m2

          # Notice it's not `NoMethodError`, so we can give a better error message.
          e = assert_abstract { @x.m2 }

          # Do not rely on this message content! Its content is subject to change!
          # We only test it to ensure it's formatted correctly.
          assert_equal "Abstract method `#m2` was never implemented.", e.message

          m2 = @x.method(:m2)
          assert_kind_of Method, m2
          assert_predicate m2, :abstract?
          assert_predicate m2.unbind, :abstract?
        end
      end

      describe "calling a non-abstract method" do
        it "calls the concrete implementation" do
          assert_respond_to @x, :inspect
          assert_kind_of String, @x.inspect
          assert_kind_of String, @x.method(:inspect).call
          refute_predicate @x.method(:inspect), :abstract?
          refute_predicate @x.method(:inspect).unbind, :abstract?
        end
      end

      describe ".abstract_method?" do
        it "returns false for abstract methods that have been implemented" do
          refute @class.abstract_method?(:m1)
        end

        it "returns true for abstract methods that have not been implemented" do
          assert @class.abstract_method?(:m2)
        end

        it "returns false for non-abstract methods" do
          refute @class.abstract_method?(:inspect)
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :abstract_method?
        end
      end

      describe ".abstract_method_declared?" do
        it "is true for all abstract methods" do
          assert @class.abstract_method_declared?(:m1) # Even the one that's been implemented
          assert @class.abstract_method_declared?(:m2)
        end

        it "is false for non-abstract methods" do
          refute @class.abstract_method_declared?(:inspect)
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :abstract_method_declared?
        end
      end

      describe ".declared_abstract_instance_methods" do
        it "returns all declared abstract methods, even those that have been implemented" do
          assert_equal [:m1, :m2], @class.declared_abstract_instance_methods
          assert_equal [:m1, :m2], @class.declared_abstract_instance_methods(true)
          assert_equal [], @class.declared_abstract_instance_methods(false)
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :declared_abstract_instance_methods
        end
      end

      describe ".abstract_instance_methods" do
        it "returns only unimplemented abstract methods" do
          assert_equal [:m2], @class.abstract_instance_methods
          assert_equal [:m2], @class.abstract_instance_methods(true)
          assert_equal [], @class.abstract_instance_methods(false)
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :abstract_instance_methods
        end
      end
    end

    describe "A subclass that fully implements the abstract methods" do
      before do
        @class = FullImpl
        @x = FullImpl.new
      end

      describe "calling an implemented abstract method" do
        it "calls the concrete implementation" do
          assert_respond_to @x, :m1
          assert_equal "FullImpl#m1", @x.m1
          assert_equal "FullImpl#m1", @x.method(:m1).call
          refute_predicate @x.method(:m1), :abstract?
          refute_predicate @x.method(:m1).unbind, :abstract?

          assert_respond_to @x, :m2
          assert_equal "FullImpl#m2", @x.m2
          assert_equal "FullImpl#m2", @x.method(:m2).call
          refute_predicate @x.method(:m2), :abstract?
          refute_predicate @x.method(:m2).unbind, :abstract?
        end
      end

      describe ".abstract_method?" do
        it "returns false for abstract methods that have been implemented" do
          refute @class.abstract_method?(:m1)
          refute @class.abstract_method?(:m2)
        end

        it "returns false for non-abstract methods" do
          refute @class.abstract_method?(:inspect)
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :abstract_method?
        end
      end

      describe ".abstract_method_declared?" do
        it "returns true for all abstract methods" do
          assert @class.abstract_method_declared?(:m1)
          assert @class.abstract_method_declared?(:m2)
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :abstract_method_declared?
        end
      end

      describe ".declared_abstract_instance_methods" do
        it "returns all declared abstract methods, even those that have been implemented" do
          assert_equal [:m1, :m2], @class.declared_abstract_instance_methods
          assert_equal [:m1, :m2], @class.declared_abstract_instance_methods(true)
          assert_equal [], @class.declared_abstract_instance_methods(false)
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :declared_abstract_instance_methods
        end
      end

      describe ".abstract_instance_methods" do
        it "returns only unimplemented abstract methods" do
          assert_equal [], @class.abstract_instance_methods
          assert_equal [], @class.abstract_instance_methods(true)
          assert_equal [], @class.abstract_instance_methods(false)
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :abstract_instance_methods
        end
      end
    end

    class PartialParentClass
      def m1 = "PartialParentClass#m1"
    end

    class AbstractSubclass < PartialParentClass
      abstract!

      abstract def m1; end
      abstract def m2; end
    end

    class PartiallyInheritsItsImpl < AbstractSubclass
      def m2 = "PartiallyInheritsItsImpl#m2"
    end

    describe "A subclass that fully implements the abstract methods, some via inheritance" do
      before do
        @class = PartiallyInheritsItsImpl
        @x = PartiallyInheritsItsImpl.new
      end

      describe "calling an abstract method with an inherited implementation" do
        it "calls the inherited implementation" do
          assert_respond_to @x, :m1
          assert_equal "PartialParentClass#m1", @x.m1
          assert_equal "PartialParentClass#m1", @x.method(:m1).call
          refute_predicate @x.method(:m1), :abstract?
          refute_predicate @x.method(:m1).unbind, :abstract?
        end
      end

      describe "calling an abstract method implemented by the subclass" do
        it "calls the child implementation" do
          assert_respond_to @x, :m2
          assert_equal "PartiallyInheritsItsImpl#m2", @x.m2
          assert_equal "PartiallyInheritsItsImpl#m2", @x.method(:m2).call
          refute_predicate @x.method(:m2), :abstract?
          refute_predicate @x.method(:m2).unbind, :abstract?
        end
      end

      describe ".abstract_method?" do
        it "returns false for abstract methods that have been implemented" do
          refute @class.abstract_method?(:m1)
          refute @class.abstract_method?(:m2)
        end

        it "returns false for non-abstract methods" do
          refute @class.abstract_method?(:inspect)
        end
      end

      describe ".abstract_method_declared?" do
        it "returns true for all abstract methods" do
          assert @class.abstract_method_declared?(:m1)
          assert @class.abstract_method_declared?(:m2)
        end
      end

      describe ".declared_abstract_instance_methods" do
        it "returns all declared abstract methods, even those that have been implemented" do
          assert_equal [:m1, :m2], @class.declared_abstract_instance_methods
          assert_equal [:m1, :m2], @class.declared_abstract_instance_methods(true)
          assert_equal [], @class.declared_abstract_instance_methods(false)
        end
      end

      describe ".abstract_instance_methods" do
        it "returns only unimplemented abstract methods" do
          assert_equal [], @class.abstract_instance_methods
          assert_equal [], @class.abstract_instance_methods(true)
          assert_equal [], @class.abstract_instance_methods(false)
        end
      end
    end

    class OverridesNew < AbstractClass
      # Overriding `.new` is pretty rare, but let's make sure we didn't break it.
      class << self
        def new(...)
          instance = super
          instance.instance_variable_set(:@custom_new_was_called, true)
          instance
        end
      end

      def initialize(arg, kwarg:, &block)
        @custom_initialize_was_called = true
        @arg = arg
        @kwarg = kwarg
        @block = block
        super()
      end
    end

    describe "A subclass that overrides .new" do
      before do
        @class = OverridesNew
      end

      describe "calling .new" do
        it "calls the overridden implementation of `.new` and `#initialize`" do
          block = -> { "example" }
          arg = "positional"
          kwarg = "keyword"
          x = OverridesNew.new(arg, kwarg:, &block)

          assert_instance_of OverridesNew, x

          assert_same arg, x.instance_variable_get(:@arg)
          assert_same kwarg, x.instance_variable_get(:@kwarg)
          assert_same block, x.instance_variable_get(:@block)

          assert_equal true, x.instance_variable_get(:@custom_new_was_called)
          assert_equal true, x.instance_variable_get(:@custom_initialize_was_called)
        end
      end

      describe "calling .allocate" do
        it "calls the normal implementation" do
          x = OverridesNew.allocate
          assert_instance_of OverridesNew, x
          assert_nil x.instance_variable_get(:@custom_allocate_was_called)
        end
      end
    end

    class OverridesAllocate < AbstractClass
      class << self
        # Overriding `.allocate` is exceptionally rare, but still, let's not break it.
        def allocate
          "custom allocator result"
        end
      end

      def initialize(arg, kwarg:, &block)
        @custom_initialize_was_called = true
        @arg = arg
        @kwarg = kwarg
        @block = block
        super()
      end
    end

    describe "A subclass that overrides .allocate" do
      before do
        @class = OverridesAllocate
      end

      describe "calling .new" do
        it "calls the overridden implementation of `.allocate` and `#initialize`" do
          block = -> { "example" }
          arg = "positional"
          kwarg = "keyword"
          x = OverridesAllocate.new(arg, kwarg:, &block)

          assert_instance_of OverridesAllocate, x

          assert_same arg, x.instance_variable_get(:@arg)
          assert_same kwarg, x.instance_variable_get(:@kwarg)
          assert_same block, x.instance_variable_get(:@block)

          assert_equal true, x.instance_variable_get(:@custom_initialize_was_called)
        end
      end

      describe "calling .allocate" do
        it "calls the overridden implementation of `.allocate`" do
          x = OverridesAllocate.allocate
          assert_equal "custom allocator result", x
        end
      end
    end
  end
end
