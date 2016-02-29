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

    def inject_hook(hook)
      @hooks ||= []
      @hooks += [ hook ]
    end

    def find_hooks_of_type(type)
      @hooks ||= []
      @hooks.select { |hook| hook.kind == type }
    end

    def before_create_hooks
      find_hooks_of_type :before_create
    end

    def before_create(*meth_syms, &blk)
      hook = Hook.new(:before_create,*meth_syms,&blk)
      inject_hook hook
      self
    end

    def after_create_hooks
      find_hooks_of_type :after_create
    end

    def after_create(*meth_syms, &blk)
      hook = Hook.new(:after_create,*meth_syms,&blk)
      inject_hook hook
      self
    end

    def before_update_hooks
      find_hooks_of_type :before_update
    end

    def before_update(*meth_syms, &blk)
      hook = Hook.new(:before_update,*meth_syms,&blk)
      inject_hook hook
      self
    end

    def after_update_hooks
      find_hooks_of_type :after_update
    end

    def after_update(*meth_syms, &blk)
      hook = Hook.new(:after_update,*meth_syms,&blk)
      inject_hook hook
      self
    end

    def before_destroy_hooks
      find_hooks_of_type :before_destroy
    end

    def before_destroy(*meth_syms,&blk)
      hook = Hook.new(:before_destroy,*meth_syms,&blk)
      inject_hook(hook)
      self
    end

    def after_destroy_hooks
      find_hooks_of_type :after_destroy
    end

    def after_destroy(*meth_syms,&blk)
      hook = Hook.new(:after_destroy,*meth_syms,&blk)
      inject_hook(hook)
      self
    end
  end
end
