module PassiveRecord
  module Associations
    class HasManyThroughAssociation < Struct.new(:parent_class, :child_class_name, :target_name_symbol, :through_class, :base_association)
      def to_relation(parent_model)
        HasManyThroughRelation.new(self, parent_model)
      end
    end

    class HasManyThroughRelation < HasManyRelation
      def lookup
        intermediate_results = association.base_association.
          to_relation(parent_model).
          lookup

        singular_target_sym = association.target_name_symbol.to_s.singularize.to_sym
        plural_target_sym   = association.target_name_symbol.to_s.pluralize.to_sym

        if !intermediate_results.empty?
          if intermediate_results.first.respond_to?(singular_target_sym)
            intermediate_results.flat_map(&singular_target_sym)
          elsif intermediate_results.first.respond_to?(plural_target_sym)
            intermediate_results.flat_map(&plural_target_sym)
          end
        else
          []
        end
      end

      def create(attrs={})
        # binding.pry
        raise "missing intermediate relational key #{association.through_class}" unless attrs.key?(association.through_class)
        super(attrs)
      end
    end
  end
end
