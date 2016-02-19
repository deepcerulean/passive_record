require 'passive_record/associations/belongs_to'
require 'passive_record/associations/has_one'
require 'passive_record/associations/has_many'

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
      target_class_name = (child_name_sym.to_s).split('_').map(&:capitalize).join
      target_class = Object.const_get(target_class_name)

      association = HasOneAssociation.new(self, target_class, child_name_sym)
      associations.push(association)
    end

    def has_many(collection_name_sym)
      target_class_name = (collection_name_sym.to_s).split('_').map(&:capitalize).join
      target_class = Object.const_get(target_class_name.singularize)

      association = HasManyAssociation.new(self, target_class, collection_name_sym)
      associations.push(association)
    end

    # def has_many(collection_name_sym, opts={})
    #   target_class_name = (collection_name_sym.to_s).split('_').map(&:capitalize).join
    #   target_class = Object.const_get(target_class_name.singularize)
    #   if opts[:through]
    #     through_class_name = (opts[:through].to_s).split('_').map(&:capitalize).join
    #     through_class = Object.const_get(through_class_name.singularize)
    #     base_association = associations.detect { |assn| assn.target_klass == through_class }
    #     raise "No such association with #{through_class}" unless base_association

    #     association = HasManyThroughAssociation.new(
    #       base_association,
    #       target_class,
    #       collection_name_sym
    #     )

    #     associations.push(association)

    #     define_method(collection_name_sym) { association }
    #     define_method(collection_name_sym.to_s + "_ids") { association.ids }
    #   else
    #     association = HasManyAssociation.new(self, target_class)

    #     associations.push(association)

    #     define_method(collection_name_sym) { association }
    #     define_method(collection_name_sym.to_s + "_ids") { association.ids }
    #   end
    # end
  end
end

