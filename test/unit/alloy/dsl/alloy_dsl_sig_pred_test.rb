require 'unit/alloy/alloy_test_helper.rb'
require 'alloy/initializer.rb'

include Alloy::Dsl

module A_D_SPT
  alloy_model do
    sig S1 do
      def ruby_meth_no_arg()    end
      def ruby_meth_args(x, y)  end
      def ruby_meth_varargs(*a) end
    end

    sig S2 do
      fun :name => "f1", :args => {a: S1, b: S2}, :ret_type => Int do |a,b| a + b end
      fun :f2, a: S1, b: S2, _: Int do |a,b| a + b end
      fun :f3, {a: S1, b: S2}, Int do |a,b| a + b end
    end

    sig S3 do
      fun f1[a: S1, b: S2][Int] {
        a + b
      }
      fun f2[a: S1, b: S2][Int] { |a, b|
        a + b
      }
    end
  end
end

class AlloyDslPredTest < Test::Unit::TestCase
  include AlloyTestUtils
  include SDGUtils::Testing::SmartSetup
  include SDGUtils::Testing::Assertions

  include A_D_SPT

  def setup_class
    Alloy.reset
    Alloy.meta.restrict_to(A_D_SPT)
    Alloy.initializer.resolve_fields
    Alloy.initializer.init_inv_fields
  end

  def get_funs(sig)
    sig.meta.funs.reduce({}){|acc,f| acc.merge!({f.name => f})}
  end

  def check_arg_names(fun, arg_names)
    assert_seq_equal arg_names, fun.args.map{|a| a.name}
  end

  def check_arg_types(fun, arg_types)
    assert_seq_equal arg_types, fun.args.map{|a| a.type.klass}
  end

  def check_args(fun, arg_names, arg_types, ret_type)
    check_arg_names(fun, arg_names)
    check_arg_types(fun, arg_types)
    assert_equal ret_type, fun.ret_type.klass
  end

  def test1
    funs = get_funs S1
    assert_set_equal [:ruby_meth_no_arg, :ruby_meth_args, :ruby_meth_varargs], funs.keys
    check_arg_names funs[:ruby_meth_no_arg],  []
    check_arg_names funs[:ruby_meth_args],    [:x, :y]
    check_arg_names funs[:ruby_meth_varargs], [:a]
  end

  def test2
    funs = get_funs S2
    assert_set_equal [:f1, :f2, :f3], funs.keys

    check_args funs[:f1], [:a, :b], [S1, S2], Integer
    assert_equal 2, S2.new.f1(1,1)

    check_args funs[:f2], [:a, :b], [S1, S2], Integer
    assert_equal 2, S2.new.f2(1,1)

    check_args funs[:f3], [:a, :b], [S1, S2], Integer
    assert_equal 2, S2.new.f3(1,1)
  end

  def test3
    funs = get_funs S3
    assert_set_equal [:f1, :f2], funs.keys

    check_args funs[:f1], [:a, :b], [S1, S2], Integer
    assert_equal 2, S3.new.f1(1,1)

    check_args funs[:f2], [:a, :b], [S1, S2], Integer
    assert_equal 4, S3.new.f2(3,1)
  end

  def test_invalid_body
    ex = assert_raise(Alloy::Ast::SyntaxError) do
      alloy_model do
        sig :SSS do
          fun f1[a: S1, b: S2][Int] { |a|
            a + b
          }
        end
      end
    end
    assert_starts_with "number of function (f1) formal parameters (2) doesn't", ex.message
  end

  def test_invalid_too_many_ret
    ex = assert_raise(Alloy::Ast::SyntaxError) do
      alloy_model do
        sig :SSS do
          fun f1[a: S1, b: S2][Int,String] {
            a + b
          }
        end
      end
    end
    assert_starts_with "can only specify 1 arg", ex.message
  end

  def test_invalid_after_ret
    ex = assert_raise(Alloy::Ast::SyntaxError) do
      alloy_model do
        sig :SSS do
          fun f1[a: S1, b: S2][Int][] {
            a + b
          }
        end
      end
    end
    assert_starts_with "only two calls to [] allowed", ex.message
  end

  def test_invalid_fname_not_string
    ex = assert_raise(Alloy::Ast::SyntaxError) do
      alloy_model do
        sig :SSS do
          fun S1, a: S1, b: S2, _: Int do |a,b| a + b end
        end
      end
    end
    assert_starts_with "`A_D_SPT::S1' (function name) is not a valid identifier", ex.message
    ex = assert_raise(Alloy::Ast::SyntaxError) do
      alloy_model do
        sig :SSS do
          fun 1, a: S1, b: S2, _: Int do |a,b| a + b end
        end
      end
    end
    assert_starts_with "`1' (function name) is not a valid identifier", ex.message
  end

  def test_invalid_argname_not_string
    ex = assert_raise(Alloy::Ast::SyntaxError) do
      alloy_model do
        sig :SSS do
          fun f1[S1: S1][Int] {
            a + b
          }
        end
      end
    end
    assert_starts_with "`S1' (arg name) is not a valid identifier", ex.message
  end

end
