module PassiveRecord
  module Associations
    class HasManyThroughAssociation < Struct.new(:parent_class, :child_class_name, :target_name_symbol, :through_class, :base_association)
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

      def create(attrs={})
        # binding.pry
        raise "missing intermediate relational key #{association.through_class}" unless attrs.key?(association.through_class)
        super(attrs)
      end
    end
  end
end
