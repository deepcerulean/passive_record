module PassiveRecord
  module Associations
    class HasManyThroughAssociation < Struct.new(:parent_class, :child_class_name, :target_name_symbol, :through_class, :base_association)
      def to_relation(parent_model)
        HasManyThroughRelation.new(self, parent_model)
      end
    end

    class HasManyThroughRelation < HasManyRelation
      def intermediary_relation
        association.base_association.to_relation(parent_model)
      end

      def_delegators :all, :intermedia

      def results
        intermediary_relation.all
      end

      def all
        if target_sym && results
          final_results = results.flat_map(&target_sym)
          if final_results.first.is_a?(Associations::Relation) && !final_results.first.singular?
            final_results.first.send(:all)
          else
            Array(final_results)
          end
        else
          []
        end
      end

      def target_sym
        name_str = association.target_name_symbol.to_s
        singular_target_sym = name_str.singularize.to_sym
        plural_target_sym   = name_str.pluralize.to_sym

        singular_class_name_sym = association.child_class_name.underscore.singularize.to_sym
        plural_class_name_sym = association.child_class_name.underscore.pluralize.to_sym

        if !results.empty?
          if results.first.respond_to?(singular_target_sym)
            singular_target_sym
          elsif results.first.respond_to?(plural_target_sym)
            plural_target_sym
          elsif results.first.respond_to?(singular_class_name_sym)
            singular_class_name_sym
          elsif results.first.respond_to?(plural_class_name_sym)
            plural_class_name_sym
          end
        end
      end

      def create(attrs={})
        child_class.create(attrs)
      end
    end
  end
end
