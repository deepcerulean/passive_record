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
      def lookup
        child_class.where(parent_model_id_field => parent_model.id).all
      end
    end
  end
end
