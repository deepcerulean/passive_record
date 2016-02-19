module PassiveRecord
  module Hooks
    class Hook
      def initialize(*meth_syms,&blk)
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

    def hooks
      @hooks ||= {}
    end

    def after_hooks
      hooks[:after] ||= {}
    end

    def after_create_hooks
      after_hooks[:create] ||= []
    end

    def after_create(*meth_syms, &blk)
      hook = Hook.new(*meth_syms,&blk)
      after_create_hooks.push(hook)
    end
  end
end
