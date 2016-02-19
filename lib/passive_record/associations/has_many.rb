module PassiveRecord
  module Associations
    class HasManyAssociation < Struct.new(:parent_class, :child_class, :target_name_symbol)
      def to_relation(parent_model)
        HasManyRelation.new(self, parent_model)
      end
    end

    class HasManyRelation < HasOneRelation #Struct.new(:association, :parent_model)
      def lookup
        association.child_class.where(parent_model_id_field => parent_model.id).all
        # return self if results.empty?
        # results
      end
    end
  end
end
