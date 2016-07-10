module PassiveRecord
  module Associations
    class HasManyAssociation < Struct.new(:parent_class, :child_class_name, :children_name_sym)
      def to_relation(parent_model)
        HasManyRelation.new(self, parent_model)
      end

      def target_name_symbol
        children_name_sym
      end
    end

    class HasManyRelation < HasOneRelation
      include Enumerable
      extend Forwardable

      include PassiveRecord::ArithmeticHelpers

      def all
        child_class.where(parent_model_id_field => parent_model.id).all
      end

      def_delegators :all, :each, :last, :all?, :empty?, :sample

      def where(conditions={})
        child_class.where(conditions.merge(parent_model_id_field.to_sym => parent_model.id))
      end

      def <<(child)
        child.send(parent_model_id_field + "=", parent_model.id)
        all
      end

      def singular?
        false
      end

      def method_missing(meth,*args,&blk)
        if child_class.methods.include?(meth)
          where.send(meth,*args,&blk)
        else
          super(meth,*args,&blk)
        end
      end
    end
  end
end
