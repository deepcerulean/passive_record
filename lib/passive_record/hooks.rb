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

        instance
      end
    end

    def before_create_hooks
      @hooks ||= []
      @hooks.select { |hook| hook.kind == :before_create }
    end

    def before_create(*meth_syms, &blk)
      hook = Hook.new(:before_create,*meth_syms,&blk)
      @hooks ||= []
      @hooks += [ hook ]
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


    def before_update_hooks
      @hooks ||= []
      @hooks.select { |hook| hook.kind == :before_update }
    end

    def before_update(*meth_syms, &blk)
      hook = Hook.new(:before_update,*meth_syms,&blk)
      @hooks ||= []
      @hooks += [ hook ]
      self
    end

    def after_update_hooks
      @hooks ||= []
      @hooks.select { |hook| hook.kind == :after_update }
    end

    def after_update(*meth_syms, &blk)
      hook = Hook.new(:after_update,*meth_syms,&blk)
      @hooks ||= []
      @hooks += [ hook ]
      self
    end
  end
end
