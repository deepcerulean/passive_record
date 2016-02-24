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
      @associations&.map do |assn|
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
    end

    def has_one(child_name_sym)
      child_class_name = (child_name_sym.to_s).split('_').map(&:capitalize).join
      association = HasOneAssociation.new(self, child_class_name, child_name_sym)
      associate!(association)
    end

    def has_many(collection_name_sym, opts={})
      target_class_name = opts.delete(:class_name) { (collection_name_sym.to_s).split('_').map(&:capitalize).join }

      if opts.key?(:through)
        through_class_collection_name = opts.delete(:through)

        through_class_name = (through_class_collection_name.to_s).split('_').map(&:capitalize).join
        base_association = associations.detect { |assn| assn.child_class_name == through_class_name }

        association = HasManyThroughAssociation.new(self, target_class_name, collection_name_sym, through_class_collection_name, base_association)

        associate!(association)
      else
        association = HasManyAssociation.new(self, target_class_name, collection_name_sym)
        associate!(association)
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

      if (Object.const_get(inverse_habtm_join_class_name) rescue false)
        has_many inverse_habtm_join_class_name.underscore.pluralize.to_sym
        has_many collection_name_sym, :through => inverse_habtm_join_class_name.underscore.pluralize.to_sym
      else
        auto_collection_sym = self.name.split('::').last.underscore.pluralize.to_sym
        eval <<-ruby
        class ::#{habtm_join_class_name}                        # class UserRoleJoinModel
          include PassiveRecord                                 #   include PassiveRecord
          belongs_to :#{collection_name_sym.to_s.singularize}   #   belongs_to :role
          belongs_to :#{auto_collection_sym.to_s.singularize}   #   belongs_to :user
        end                                                     # end
        ruby
        has_many habtm_join_class_name.underscore.pluralize.to_sym
        has_many(collection_name_sym, :through => habtm_join_class_name.underscore.pluralize.to_sym)
      end
    end
  end
end
