module PassiveRecord
  module Associations
    class BelongsToAssociation < Struct.new(:child_class, :parent_class_name, :target_name_symbol)
      def to_relation(child_model)
        BelongsToRelation.new(self, child_model)
      end

      def parent_class
        # look in same namespace as child class
	module_name = child_class.name.deconstantize
	module_name = "Object" if module_name.empty?
	(module_name.constantize).const_get(parent_class_name)
      end

      def child_class_name
        child_class.name
      end
    end

    class BelongsToRelation < Struct.new(:association, :child_model)
      def singular?
        true
      end

      def lookup
        association.parent_class.find_by(parent_model_id)
      end

      def parent_model_id
        @parent_model_id ||= nil
      end

      def parent_model_id=(id)
        @parent_model_id = id
      end
    end
  end
end
