module PassiveRecord
  module Associations
    class HasOneAssociation < Struct.new(:parent_class, :child_class, :target_name_symbol)
      def to_relation(parent_model)
        HasOneRelation.new(self, parent_model)
      end
    end

    class HasOneRelation < Struct.new(:association, :parent_model)
      def lookup
        association.child_class.find_by(parent_model_id_field => parent_model.id)
      end

      def create
        model = association.child_class.create
        model.send(parent_model_id_field + "=", parent_model.id)
        model
      end

      def parent_model_id_field
        parent_class_name + "_id"
      end
      
      def parent_class_name
        association.parent_class.name.underscore
      end
    end
  end
end
