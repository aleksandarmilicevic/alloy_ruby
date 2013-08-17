require 'alloy/ast/types'

module Alloy
  module Ast

    # ============================================================================
    # == Class +FunBuilder+
    #
    # Used to handle expressions like
    #   func_name[a: A, b: B][Int]
    # ============================================================================
    class FunBuilder < BasicObject
      attr_reader :name, :args, :ret_type

      def initialize(name)
        @name = name
        @args = {}
        @ret_type = notype
        @state = :init
      end

      def in_init?()     @state == :init end
      def in_args?()     @state == :args end
      def in_ret_type?() @state == :ret_type end
      def past_init?()   in_args? || in_ret_type? end
      def past_args?()   in_ret_type? end

      def [](*args)
        case @state
        when :init
          @args = to_args_hash(args)
          @state = :args
        when :args
          msg = "can only specify 1 arg for fun return type"
          ::Kernel.raise ::Alloy::Ast::SyntaxError, msg unless args.size == 1
          @ret_type = args[0]
          @state = :ret_type
        else
          ::Kernel.raise ::Alloy::Ast::SyntaxError, "only two calls to [] allowed"
        end
        self
      end

      def method_missing(sym, *args, &block)
        msg = "Tried to invoke `#{sym}' on a FunBuilder object. "
        msg += "It's likely you mistakenly misspelled `#{@name}' in the first place"
        ::Kernel.raise ::NameError, msg
      end

      def ==(other) 
        if ::Alloy::Ast::FunBuilder === other
          @name == other.name
        else
          @name == other
        end
      end

      def hash()   @name.hash end
      def to_str() name.to_s end

      def to_s
        ans = name
        ans += "[#{args}]" if past_init?
        ans += "[#{ret_type}]" if past_args?
        ans
      end

      private

      def notype() ::Alloy::Ast::NoType.new end

      def to_args_hash(args)
        case
        when args.size == 1 && ::Hash === args[0]
          args[0]
        else
          # treat as a list of arg names
          args.reduce({}) do |acc, arg_name|
            acc.merge!({arg_name => notype})
          end
        end
      end
    end

  end
end
