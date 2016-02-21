module PassiveRecord
  module Hooks
    class Hook
      attr_reader :kind

      def initialize(kind,*meth_syms,&blk)
        @kind = kind
        @methods_to_call = meth_syms
        @block_to_invoke = blk
      end

      def run(instance)
        @methods_to_call.each do |meth|
          instance.send(meth)
        end

        unless @block_to_invoke.nil?
          instance.instance_eval(&@block_to_invoke)
        end
      end
    end

    def after_create_hooks
      @hooks ||= []
      @hooks.select { |hook| hook.kind == :after_create }
    end

    def after_create(*meth_syms, &blk)
      hook = Hook.new(:after_create,*meth_syms,&blk)
      @hooks ||= []
      @hooks += [ hook ]
      self
    end
  end
end