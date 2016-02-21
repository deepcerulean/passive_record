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

      def results
        intermediary_relation.lookup
      end

      def lookup
        if target_sym && results
          results.flat_map(&target_sym)
        else
          []
        end
      end

      def target_sym
        singular_target_sym = association.target_name_symbol.to_s.singularize.to_sym
        plural_target_sym   = association.target_name_symbol.to_s.pluralize.to_sym
        has_child_class = begin child_class rescue false end
        if has_child_class
          singular_class_name_sym = child_class.name.split('::').last.to_s.underscore.singularize.to_sym
          plural_class_name_sym = child_class.name.split('::').last.to_s.underscore.pluralize.to_sym
        end

        if !results.empty?
          if results.first.respond_to?(singular_target_sym)
            singular_target_sym
          elsif results.first.respond_to?(plural_target_sym)
            plural_target_sym
          elsif has_child_class
            if results.first.respond_to?(singular_class_name_sym)
              singular_class_name_sym
            elsif results.first.respond_to?(plural_class_name_sym)
              plural_class_name_sym
            end
          end
        end
      end

      def create(attrs={})
        child_class.create(attrs)
      end
    end
  end
end
