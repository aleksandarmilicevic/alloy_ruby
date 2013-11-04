require 'sdg_utils/config'
require 'sdg_utils/dsl/syntax_error'
require 'sdg_utils/track_nesting'

module SDGUtils
  module DSL

    #=========================================================================
    # == Class ClassBuilder
    #
    #=========================================================================
    class BaseBuilder
      extend SDGUtils::TrackNesting

      def self.top()             top_ctx end
      def self.get()             SDGUtils::DSL::BaseBuilder.find(self) end
      def self.find(builder_cls) find_ctx{|e| builder_cls === e} end
      def self.in_builder?()     curr = self.get and curr.in_builder? end
      def self.in_body?()        curr = self.get and curr.in_body? end

      def get_prev()
        SDGUtils::DSL::BaseBuilder.find_ctx{|e| e != self && self.class === e}
      end

      def in_builder?() @in_builder end
      def in_body?()    @in_body end

      def missing_builders()                @missing_builders ||= [] end
      def register_missing_builder(blder)   missing_builders << blder end
      def unregister_missing_builder(blder) missing_builders.delete blder end

      def fail_if_missing_methods()
        # unless missing_builders.none?{|mb| mb.past_init? || mb.has_body?}
        unless missing_builders.empty?
          mb = missing_builders.first
          raise NoMethodError, "Unconsumed method missing: `#{mb}'\n"
        end
      end

      def result()
        (SDGUtils::DSL::BaseBuilder === @result) ? @result.result() : @result
      end

      def return_result(return_form=@conf.return)
        res = result()
        case return_form
        when :as_is; res
        when :array; (Array === res) ? res : [res]
        when :builder; self
        else
          raise ArgumentError, "invalid return option: `#{@conf.return}'"
        end
      end

      def build(*args, &body)
        BaseBuilder.push_ctx(self)
        @in_builder = true
        @missing_builders = []

        begin
          @result = case
          # if the argument is a builder, that means that the object has already
          # been built, so now only evaluate the body (if given)
          when args.size == 1 && BaseBuilder === args.first
            bb = args.first
            bb.return_result(:array).each{|obj| eval_body(obj, &body) }
            bb.result()
          else
            @result = nil
            do_build(*args, &body)
          end
          # send :finish
          return_result(:array).each{|obj| safe_send obj, @conf.finish_mthd}

          # check missing builders
          fail_if_missing_methods

          return_result
        ensure
          @in_builder = false
          @missing_builders = []
          BaseBuilder.pop_ctx
        end
      end

      def apply_modifier(modifier, expected_cls=nil, *args, &block)
        build self, &block
        return_result(:array).each do |obj|
          unless check_type(obj, expected_cls) && obj.respond_to?(:"set_#{modifier}")
            raise_illegal_modifier(obj, modifier)
          end
          obj.send :"set_#{modifier}", *args
        end
        return_result
      end

      protected

      def raise_illegal_modifier(obj, modifier)
        raise SyntaxError, "Modifier `#{modifier}' is illegal for #{obj}:#{obj.class}"
      end

      def check_type(obj, expected_cls)
        return true unless expected_cls
        if Class === obj
          obj < expected_cls
        else
          expected_cls === obj
        end
      end

      # @param optinos [Hash]
      #
      # Valid options:
      #
      #   :created_mthd    [Symbol] - callback method to call as soon as the target
      #                               is created
      #
      #   :eval_body_mthd  [Symbol] - method to call to evaluate the block in the
      #                               context of the newly created class/module
      #
      #   :body_evald_mthd [Symbol] - callback method to call upon evaluating body
      #
      #   :finish_method   [Symbol] - callback method to call upon finishing
      #
      #   :create_const    [Bool]   - whether to assign a constant to the created
      #                               class/module
      #
      #   :return          [Symbol] - instructs what to return. Valid values:
      #                                 :as_is   => returns either a single created,
      #                                             or an array of created classes,
      #                                             depending on the invocation args
      #                                 :array   => always returns an array of classes
      #                                             (if a single class was created, wraps
      #                                             it in a singleton array)
      #                                 :builder => returns self
      def initialize(options={})
        @conf = SDGUtils::Config.new(nil, {
          :created_mthd     => :__created,
          :eval_body_mthd   => :__eval_body,
          :body_evald_mthd  => :__body_evaluated,
          :finish_mthd      => :__finish,
          :create_const     => true,
          :return           => :as_is
        }).extend(options)
      end

      def do_build(*args, &body) fail "must override" end

      def eval_body(obj, default_eval_mthd=:class_eval, &body)
        return unless body
        # body_src = SDGUtils::Lambda::Sourcerer.proc_to_src(body) rescue nil

        ebm = @conf.eval_body_mthd
        eval_body_mthd_name = obj.respond_to?(ebm) ? ebm : default_eval_mthd
        begin
          @in_body = true
          obj.send eval_body_mthd_name, &body
          safe_send obj, @conf.body_evald_mthd
        ensure
          @in_body = false
        end
      end

      def opts_to_flat_array(*opts)
        opts.each do |opt|
          @conf[opt] = Array[@conf[opt]].flatten.compact
        end
      end

      def safe_send(obj, sym, *args)
        obj.send sym, *args if obj.respond_to? sym
      end
    end

  end
end
