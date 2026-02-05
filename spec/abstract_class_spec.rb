# frozen_string_literal: true

require "spec_helper"
require "type_toolkit/ext"

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

    # A class that provides a partial implementation of `SimpleInterface` for `PartiallyInheritsItsImpl`.
    module PartialParentModule
      def m1 = "PartialParentModule#m1"
      # Does not implement `m2`
    end

    # A class that implements all of the SimpleInterface's abstract methods, some via inheritance and some via direct implementation.
    class PartiallyInheritsItsImpl < AbstractClass
      include PartialParentModule # This doesn't actually end up earlier in the ancestor chain than `AbstractClass`.

      def m2 = "PartiallyInheritsItsImpl#m2"
    end

    describe "An abstract class" do
      it "cannot be instantiated" do
        skip "Not implemented yet"
        assert_raises { AbstractClass.new }
      end

      describe ".abstract_instance_methods" do
        it "only contains the abstract methods" do
          assert_equal [:m1, :m2], AbstractClass.abstract_instance_methods
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

    describe "A class that does not implement any abstract methods" do
      before do
        @class = NonImpl
      end

      it "cannot be instantiated" do
        skip "Not implemented yet"
        assert_raises { NonImpl.new }
      end

      # describe "a method with the same name as another interface's members" do
      #   # These tests sanity-check that our runtime trickery didn't accidentally change the
      #   # normal behaviour of method calling and `method_missing` for unrelated classes.

      #   it "calls a defined method like normal" do
      #     assert_respond_to @x, :m1
      #     assert_equal "NonImpl#m1", @x.m1
      #     assert_equal "NonImpl#m1", @x.method(:m1).call
      #     refute_predicate @x.method(:m1), :abstract?
      #     refute_predicate @x.method(:m1).unbind, :abstract?
      #   end
      # end

      # it "raises NoMethodError for an undefined method like normal" do
      #   refute_respond_to @x, :does_not_exist
      #   assert_raises(NameError) { @x.method(:does_not_exist) }
      #   assert_raises(NameError) { @class.instance_method(:does_not_exist) }
      #   assert_raises(NoMethodError) { @x.does_not_exist }
      # end

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
        end
      end
    end

    describe "A class that partially implements the interface" do
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
          assert_abstract { @x.m2 }

          m2 = @x.method(:m2)
          assert_kind_of Method, m2
          assert_abstract { @x.m2 }
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

      describe ".abstract_instance_methods" do
        it "returns all abstract methods" do
          # ... even `#m1`, which has been implemented
          assert_equal [:m1, :m2], @class.abstract_instance_methods
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :abstract_instance_methods
        end
      end
    end

    describe "A class that fully implements the interface" do
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

      describe ".abstract_instance_methods" do
        it "returns all abstract methods" do
          # ... even through they're both implemented
          assert_equal [:m1, :m2], @class.abstract_instance_methods
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :abstract_instance_methods
        end

        it "is not defined on instances of the class" do
          refute_respond_to @x, :abstract_instance_methods
        end
      end
    end

    describe "A class that partially inherits its implementation" do
      before do
        @class = PartiallyInheritsItsImpl
        @x = PartiallyInheritsItsImpl.new
      end

      describe "calling an abstract method with an inherited implementation" do
        it "calls the inherited implementation" do
          assert_respond_to @x, :m1
          assert_equal "PartialParentModule#m1", @x.m1
          assert_equal "PartialParentModule#m1", @x.method(:m1).call
          refute_predicate @x.method(:m1), :abstract?
          refute_predicate @x.method(:m1).unbind, :abstract?
        end
      end

      describe "calling an abstract method with defined in the child implementation" do
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

      describe ".abstract_instance_methods" do
        it "returns all abstract methods" do
          # ... even through they're both implemented
          assert_equal [:m1, :m2], @class.abstract_instance_methods
        end
      end
    end
  end
end
