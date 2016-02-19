require 'passive_record/associations/belongs_to'
require 'passive_record/associations/has_one'
require 'passive_record/associations/has_many'
require 'passive_record/associations/has_many_through'

module PassiveRecord
  module Associations
    def associations
      @associations ||= []
    end

    def belongs_to(parent_name_sym)
      target_class_name = (parent_name_sym.to_s).split('_').map(&:capitalize).join
      association = BelongsToAssociation.new(self, target_class_name, parent_name_sym)
      associations.push(association)
    end

    def has_one(child_name_sym)
      child_class_name = (child_name_sym.to_s).split('_').map(&:capitalize).join
      # target_class = Object.const_get(target_class_name)

      association = HasOneAssociation.new(self, child_class_name, child_name_sym)
      associations.push(association)
    end

    def has_many(collection_name_sym, opts={})
      target_class_name = (collection_name_sym.to_s).split('_').map(&:capitalize).join

      if opts.key?(:through)
        through_class_collection_name = opts.delete(:through)

        through_class_name = (through_class_collection_name.to_s).split('_').map(&:capitalize).join
        base_association = associations.detect { |assn| assn.child_class_name == through_class_name }

        association = HasManyThroughAssociation.new(self, target_class_name, collection_name_sym, through_class_collection_name, base_association)

        associations.push(association)
      else # simple has-many
        association = HasManyAssociation.new(self, target_class_name, collection_name_sym)
        associations.push(association)
      end
    end
  end
end
