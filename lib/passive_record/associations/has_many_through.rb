module PassiveRecord
  module Associations
    class HasManyThroughAssociation < Struct.new(:parent_class, :child_class_name, :target_name_symbol, :through_class, :base_association)
      def to_relation(parent_model)
        HasManyThroughRelation.new(self, parent_model)
      end
    end

    class HasManyThroughRelation < HasManyRelation
      def <<(child)
        if nested_association.is_a?(HasManyAssociation)
          intermediary_relation.create(association.target_name_symbol.to_s.singularize + "_ids" => [child.id])
        else
          intermediary_relation.
            where(
              association.target_name_symbol.to_s.singularize + "_id" => child.id).
              first_or_create

        end
        self
      end

      def create(attrs={})
        child = child_class.create(attrs)
        send(:<<, child)
        child
      end

      def nested_class
        module_name = association.parent_class.name.deconstantize
        module_name = "Object" if module_name.empty?
        (module_name.constantize).
          const_get("#{association.base_association.child_class_name.singularize}")
      end

      def nested_association
        nested_class.associations.detect { |assn|
          assn.child_class_name == association.child_class_name ||
          assn.child_class_name == association.child_class_name.singularize ||

          (assn.parent_class_name == association.child_class_name rescue false) ||
          (assn.parent_class_name == association.child_class_name.singularize rescue false) ||

          assn.target_name_symbol == association.target_name_symbol.to_s.singularize.to_sym
        }
      end

      def all
        if intermediate_results && !intermediate_results.empty?
          final_results = intermediate_results.flat_map(&nested_association.target_name_symbol)
          if final_results.first.is_a?(Associations::Relation) && !final_results.first.singular?
            final_results.first.send(:all)
          else
            Array(final_results)
          end
        else
          []
        end
      end

      def intermediary_relation
        association.base_association.to_relation(parent_model)
      end

      def intermediate_results
        intermediary_relation.all
      end
    end
  end
end
