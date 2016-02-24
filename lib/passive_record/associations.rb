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
        else # plural ids
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
  end
end
