module PassiveRecord
  module Associations
    class HasManyAssociation < Struct.new(:parent_class, :child_class, :target_name_symbol)
      def to_relation(parent_model)
        HasManyRelation.new(self, parent_model)
      end
    end

    class HasManyRelation < HasOneRelation
      def lookup
        association.child_class.where(parent_model_id_field => parent_model.id).all
      end
    end
  end
end
