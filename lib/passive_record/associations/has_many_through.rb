module PassiveRecord
  module Associations
    class HasManyThroughAssociation < Struct.new(:parent_class, :child_class_name, :target_name_symbol, :through_class, :base_association, :habtm)
      def to_relation(parent_model)
        HasManyThroughRelation.new(self, parent_model)
      end

      def nested_association
        thru_klass = base_association.child_class_name.singularize.constantize
        thru_klass.associations.detect { |assn| assn.child_class_name == child_class_name }
      end
    end

    class HasManyThroughRelation < HasManyRelation
      def <<(child)
        if nested_association.is_a?(HasManyAssociation)
          intermediary_id =
            child.send(association.base_association.target_name_symbol.to_s.singularize + "_id")

          if intermediary_id
            intermediary_relation.child_class.find(intermediary_id).
              send(:"#{parent_model_id_field}=", parent_model.id)
          else
            nested_ids_field = nested_association.children_name_sym.to_s.singularize + "_ids"
            intermediary_model = intermediary_relation.singular? ?
                intermediary_relation.lookup_or_create :
                intermediary_relation.where(parent_model_id_field => parent_model.id).first_or_create

            intermediary_model.update(
                nested_ids_field => intermediary_model.send(nested_ids_field) + [ child.id ]
              )
          end
        else
          # binding.pry
          intermediary_model = intermediary_relation.
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
        join_results = intermediate_results
        if intermediate_results && !join_results.empty?
          final_results = join_results.flat_map(&nested_association.target_name_symbol)
          if final_results.first.is_a?(Associations::Relation)
            final_results.flat_map(&:all)
          else
            Array(final_results)
          end
        else
          []
        end
      end

      def intermediary_relation
        # binding.pry
        @intermediary_relation ||= association.base_association.to_relation(parent_model)
      end

      def intermediate_results
        if intermediary_relation.singular?
          Array(intermediary_relation.lookup)
        else
          intermediary_relation.all
        end
      end

      def intermediary_conditions
        if intermediary_relation.is_a?(HasManyThroughRelation)
          conds = intermediary_relation.intermediary_conditions

          if nested_association.habtm || nested_association.is_a?(HasManyThroughAssociation)
            { association.through_class => conds }
          else
            { association.through_class.to_s.singularize.to_sym => conds }
          end
        elsif intermediary_relation.association.is_a?(HasManyAssociation) # normal has many?
          intermediary_key = if association.is_a?(HasManyThroughAssociation)
                               ch = association.child_class_name.constantize
                               inverse_assn = ch.associations.detect { |assn| 
                                 if assn.is_a?(HasManyAssociation) || assn.is_a?(HasManyThroughAssociation)
                                   assn.child_class_name == association.base_association.child_class_name
                                 else # belongs to...
                                   assn.parent_class_name == association.base_association.child_class_name
                                 end
                               }

                               if inverse_assn.nil?
                                 association.through_class.to_s.singularize.to_sym
                               elsif inverse_assn.is_a?(HasManyAssociation) || inverse_assn.is_a?(HasManyThroughAssociation)
                                 inverse_assn.children_name_sym
                               else
                                 inverse_assn.target_name_symbol
                               end
                             elsif association.habtm
                               association.base_association.children_name_sym
                             else
                               association.base_association.children_name_sym.to_s.singularize.to_sym
                             end

          nested_conds = { intermediary_key => { parent_model_id_field.to_sym => parent_model.id } }

          if nested_association.is_a?(HasManyThroughAssociation)
            n = nested_association
            hash = nested_conds

            until !n.is_a?(HasManyThroughAssociation)
              key = n.through_class.to_s.singularize.to_sym
              p [ :n_class, n.class, key ] 
              hash = {key => hash}
              n = n.nested_association
            end

            # binding.pry

            hash
          else
            nested_conds
          end
        end
      end

      def where(conditions={})
        merged_conditions = conditions.merge(intermediary_conditions)
        # binding.pry
        child_class.where(merged_conditions)
      end
    end
  end
end
