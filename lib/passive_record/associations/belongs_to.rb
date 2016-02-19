module PassiveRecord
  module Associations
    class BelongsToAssociation < Struct.new(:child_class, :parent_class_name, :target_name_symbol)
      def to_relation(child_model)
        BelongsToRelation.new(self, child_model)
      end

      def parent_class
        Object.const_get(parent_class_name)
      end
    end

    class BelongsToRelation < Struct.new(:association, :child_model)
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
