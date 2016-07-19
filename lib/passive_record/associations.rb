require 'passive_record/associations/belongs_to'
require 'passive_record/associations/has_one'
require 'passive_record/associations/has_many'
require 'passive_record/associations/has_many_through'

module PassiveRecord
  module Associations
    def associate!(assn)
      @associations ||= []
      @associations += [assn] unless @associations.include?(assn)
      self
    end

    def associations_id_syms
      @associations && @associations.map do |assn|
        if assn.is_a?(HasOneAssociation) || assn.is_a?(BelongsToAssociation)
          (assn.target_name_symbol.to_s + "_id").to_sym
        else
          (assn.target_name_symbol.to_s.singularize + "_ids").to_sym
        end
      end || []
    end

    def belongs_to(parent_name_sym, opts={})
      target_class_name = opts.delete(:class_name) { (parent_name_sym.to_s).split('_').map(&:capitalize).join }
      association = BelongsToAssociation.new(self, target_class_name, parent_name_sym)
      associate!(association)

      define_method(:"#{parent_name_sym}_id") do
        prnt = send(parent_name_sym)
        prnt && prnt.id
      end

      define_method(parent_name_sym) do
        relation = relata.detect { |rel| rel.association == association }
        association.parent_class.find(relation.parent_model_id)
      end

      define_method(:"#{parent_name_sym}=") do |new_parent|
        send(:"#{parent_name_sym}_id=", new_parent.id)
      end

      define_method(:"#{parent_name_sym}_id=") do |new_parent_id|
        relation = relata.detect { |rel| rel.association == association }
        relation.parent_model_id = new_parent_id
      end
    end

    def has_one(child_name_sym)
      child_class_name = (child_name_sym.to_s).split('_').map(&:capitalize).join
      association = HasOneAssociation.new(self, child_class_name, child_name_sym)
      associate!(association)

      define_method(:"#{child_name_sym}_id") do
        chld = send(child_name_sym)
        chld && chld.id
      end

      define_method(child_name_sym) do
        relation = relata.detect { |rel| rel.association == association }
        relation.lookup
      end

      define_method(:"create_#{child_name_sym}") do |attrs={}|
        relation = relata.detect { |rel| rel.association == association }
        relation.create(attrs)
      end

      define_method(:"#{child_name_sym}=") do |new_child|
        send(:"#{child_name_sym}_id=", new_child.id)
      end

      define_method(:"#{child_name_sym}_id=") do |new_child_id|
        relation = relata.detect { |rel| rel.association == association }
        rel = relation.lookup
        rel && rel.send(:"#{relation.parent_model_id_field}=", nil)

        relation.child_class.
          find(new_child_id).
          update(relation.parent_model_id_field => relation.id)
      end
    end

    def has_many(collection_name_sym, opts={})
      target_class_name = opts.delete(:class_name) { (collection_name_sym.to_s).split('_').map(&:capitalize).join.singularize }
      habtm = opts.delete(:habtm) { false }

      association = nil
      if opts.key?(:through)
        through_class_collection_name = opts.delete(:through)

        through_class_name = (through_class_collection_name.to_s).split('_').map(&:capitalize).join.singularize
        base_association = associations.detect { |assn| assn.child_class_name == through_class_name rescue false }

        association = HasManyThroughAssociation.new(
          self, target_class_name, collection_name_sym, through_class_collection_name, base_association, habtm)

        associate!(association)

        define_method(:"#{collection_name_sym}=") do |new_collection|
          send(:"#{collection_name_sym.to_s.singularize}_ids=", new_collection.map(&:id))
        end

        define_method(:"#{collection_name_sym.to_s.singularize}_ids=") do |new_collection_ids|
          relation = relata.detect { |rel| rel.association == association }

          intermediary = relation.intermediary_relation

          # drop all intermediary relations
          intermediary.where( relation.parent_model_id_field => relation.id ).each do |intermediate|
            intermediate.destroy
          end

          # add in new ones...
          singular_target = collection_name_sym.to_s.singularize
          if !(relation.nested_association.is_a?(BelongsToAssociation))# && 
            intermediary.create(
              singular_target + "_ids" => new_collection_ids,
              relation.parent_model_id_field => relation.id 
            )
          else
            new_collection_ids.each do |child_id|
              intermediary.create(
                singular_target + "_id" => child_id, 
                relation.parent_model_id_field => relation.id 
              )
            end
          end
        end
      else
        association = HasManyAssociation.new(self, target_class_name, collection_name_sym)
        associate!(association)

        define_method(:"#{collection_name_sym}=") do |new_collection|
          relation = relata.detect { |rel| rel.association == association }

          # detach existing children...
          relation.all.each do |child|
            child.send(:"#{relation.parent_model_id_field}=", nil)
          end

          # reattach new children
          new_collection.each do |child|
            child.send(:"#{relation.parent_model_id_field}=", relation.id)
          end
        end

        define_method(:"#{collection_name_sym.to_s.singularize}_ids=") do |new_collection_ids|
          relation = relata.detect { |rel| rel.association == association }
          send(:"#{collection_name_sym}=", relation.child_class.find(new_collection_ids))
        end
      end

      define_method(collection_name_sym) do
        relata.detect { |rel| rel.association == association }
      end

      define_method(:"#{collection_name_sym.to_s.singularize}_ids") do
        send(collection_name_sym).map(&:id)
      end

      define_method(:"create_#{collection_name_sym.to_s.singularize}") do |attrs={}|
        relation = relata.detect { |rel| rel.association == association }
        relation.create(attrs)
      end
    end

    def has_and_belongs_to_many(collection_name_sym)
      habtm_join_class_name =
        self.name.split('::').last.singularize +
        collection_name_sym.to_s.camelize.singularize +
        "JoinModel"
      inverse_habtm_join_class_name =
        collection_name_sym.to_s.camelize.singularize +
        self.name.split('::').last.singularize +
        "JoinModel"

      module_name = self.name.deconstantize
      module_name = "Object" if module_name.empty?
      intended_module = module_name.constantize

      if (intended_module.const_get(inverse_habtm_join_class_name) rescue false)
        has_many inverse_habtm_join_class_name.underscore.to_sym
        has_many collection_name_sym, :through => inverse_habtm_join_class_name.underscore.to_sym, habtm: true
      else
        auto_collection_sym = self.name.split('::').last.underscore.pluralize.to_sym
        eval <<-ruby
        class #{module_name}::#{habtm_join_class_name}          # class System::UserRoleJoinModel
          include PassiveRecord                                 #   include PassiveRecord
          belongs_to :#{collection_name_sym.to_s.singularize}   #   belongs_to :role
          belongs_to :#{auto_collection_sym.to_s.singularize}   #   belongs_to :user
        end                                                     # end
        ruby
        has_many habtm_join_class_name.underscore.to_sym
        has_many(collection_name_sym, :through => habtm_join_class_name.underscore.to_sym, habtm: true)
      end
    end
  end
end
