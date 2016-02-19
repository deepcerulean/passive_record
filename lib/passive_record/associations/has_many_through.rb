module PassiveRecord
  module Associations
    class HasManyThroughAssociation < Struct.new(:parent_class, :child_class, :target_name_symbol, :through_class, :base_association)
      def to_relation(parent_model)
        HasManyThroughRelation.new(self, parent_model)
      end
    end

    class HasManyThroughRelation < HasManyRelation
      def lookup
        association.base_association.
          to_relation(parent_model).
          lookup.
          flat_map(&association.target_name_symbol.to_s.singularize.to_sym)
      end
    end
  end
end
