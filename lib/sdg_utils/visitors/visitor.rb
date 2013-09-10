require 'sdg_utils/config'
require 'sdg_utils/meta_utils'

module SDGUtils
  module Visitors

    class Visitor
      def self.mk_visitor_obj(visitor_obj=nil, target=Object.new, &visitor_blk)
        case visitor_obj
        when NilClass
          if visitor_blk
            target.define_singleton_method :visit, visitor_blk
          else
            target.define_singleton_method :visit, proc{|*a,&b|}
          end
          target
        when Hash
          visitor_obj.each{|key,val| target.define_singleton_method key.to_sym, val}
          target
        else
          visitor_obj
        end
      end

      def initialize(visitor_obj=nil, &visitor_blk)
        res = Visitor.mk_visitor_obj(visitor_obj, self, &visitor_blk)
        unless res == self
          class << self
            include SDGUtils::MDelegator
            @target = res
          end
        end
      end

      def visit(*args, &block)
      end
    end

    class TypeDelegatingVisitor
      Conf = SDGUtils::Config.new(nil, {
        :top_class        => Object,
        :visit_meth_namer => proc{|cls, cls_short_name| "visit_#{cls_short_name}"},
        :default_return   => proc{nil}
      })

      def initialize(visitor_obj=nil, opts={}, &visitor_blk)
        @visitor = Visitor.mk_visitor_obj(visitor_obj, &visitor_blk)
        @conf = Conf.extend(opts)
      end

      # Assumes that the first argument is the node to be visited.
      # Delegates to more specific "visit" methods based on that
      # node's type.
      def visit(*args, &block)
        return if args.empty?
        node = args.first
        node.singleton_class.ancestors.select{|cls|
          cls <= @conf.top_class
        }.each do |cls|
          kind = cls.relative_name.downcase
          meth = @conf.visit_meth_namer[cls, kind].to_sym
          if @visitor.respond_to? meth
            return @visitor.send meth, node
          end
        end
        return @conf.default_return[node]
      end

    end

  end
end