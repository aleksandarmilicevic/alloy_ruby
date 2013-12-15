require 'arby/dsl/helpers'
require 'arby/dsl/command_helper'
require 'arby/dsl/sig_builder'
require 'arby/ast/model'
require 'arby/ast/expr_builder'
require 'sdg_utils/lambda/sourcerer'

module Arby
  module Dsl

    # ============================================================================
    # == Class +Model+
    #
    # Module to be included in each +alloy_model+.
    # ============================================================================
    module ModelDslApi
      include MultHelper
      include QuantHelper
      include AbstractHelper
      include FunHelper
      include CommandHelper
      include Arby::Ast::ExprHelper
      include Arby::Ast::TypeConsts
      extend self

      # protected

      # --------------------------------------------------------------
      # Creates a new class, subclass of either Arby::Ast::Sig or a
      # user supplied super class, creates a constant with a given
      # +name+ in the callers namespace and assigns the created class
      # to it.
      #
      # @param args [Array] --- @see +SigBuilder#sig+
      # @return [SigBuilder]
      # --------------------------------------------------------------
      def sig(*args, &block)
        SigBuilder.new({
          :return => :builder
        }).sig(*args, &block)
      end

      def __created(scope_module)
        require 'arby/arby.rb'
        mod = Arby.meta.find_model(name) || __create_model(scope_module)
        Arby.meta.add_model(mod)
        __define_meta(mod)
      end

      def __eval_body(&block)
        mod = meta()
        Arby.meta.open_model(mod)
        begin
          body_src = nil #SDGUtils::Lambda::Sourcerer.proc_to_src(block) rescue nil
          if body_src
            puts body_src
            Arby::Utils::CodegenRepo.module_eval_code mod.ruby_module, body_src,
                                                       *block.source_location
          else
            mod.ruby_module.module_eval &block
          end
        ensure
          Arby.meta.close_model(mod)
        end
      end

      def __create_model(scope_module)
        Arby::Ast::Model.new(scope_module, self)
      end

      def __define_meta(alloy_model)
        define_singleton_method :meta, lambda{alloy_model}
      end

    end

  end
end