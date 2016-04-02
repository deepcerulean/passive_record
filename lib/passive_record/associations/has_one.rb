module PassiveRecord
  module Associations
    class HasOneAssociation < Struct.new(:parent_class, :child_class_name, :child_name_sym)
      def to_relation(parent_model)
        HasOneRelation.new(self, parent_model)
      end

      def target_name_symbol
        child_name_sym
      end
    end

    class Relation < Struct.new(:association, :parent_model)
      def singular?
        true
      end
    end

    class HasOneRelation < Relation
      def lookup
        child_class.find_by(parent_model_id_field => parent_model.id)
      end

      def create(attrs={})
        child_class.create(
          attrs.merge(
            parent_model_id_field => parent_model.id
          )
        )
      end

      def lookup_or_create
        lookup || create
      end

      def parent_model_id_field
        association.parent_class.name.demodulize.underscore + "_id"
      end

      def child_class
	module_name = association.parent_class.name.deconstantize
	module_name = "Object" if module_name.empty?
	(module_name.constantize).const_get(association.child_class_name.singularize)
      end

      def id
        parent_model.id
      end

      def child_class_name
        child_class.name
      end
    end
  end
end
