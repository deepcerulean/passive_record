require 'active_support'
require 'active_support/core_ext/string/inflections'

require 'passive_record/version'
require 'passive_record/core/identifier'
require 'passive_record/core/query'

# should also be the same...?
require 'passive_record/associations'

require 'passive_record/class_inheritable_attrs'
require 'passive_record/hooks'

module PassiveRecord
  def self.included(base)
    base.send :include, InstanceMethods
    # include ClassLevelInheritableAttributes
    # base.send :include, ClassLevelInheritableAttributes
    base.extend(ClassMethods)
  end

  module InstanceMethods
    include ClassLevelInheritableAttributes

    inheritable_attributes :relata, :hooks

    def relationships
      @relata ||= self.class.associations.map do |assn|
        assn.to_relation(self)
      end
    end

    def method_missing(meth, *args, &blk)
      matching_relation = relationships.detect do |relation|  # matching relation...
        meth == relation.association.target_name_symbol ||
          meth.to_s == relation.association.target_name_symbol.to_s + "=" ||
          meth.to_s == relation.association.target_name_symbol.to_s + "_id" ||
          meth.to_s == relation.association.target_name_symbol.to_s + "_id=" ||
          meth.to_s == "create_" + relation.association.target_name_symbol.to_s ||
          meth.to_s == "create_" + (relation.association.target_name_symbol.to_s).singularize
      end

      if matching_relation
        if meth.to_s.end_with?("_id")
          matching_relation.parent_model_id
        elsif meth.to_s.end_with?("_id=")
          matching_relation.parent_model_id = args.first
        elsif meth.to_s.end_with?("=")
          matching_relation.parent_model_id = args.first.id
        elsif meth.to_s.start_with?("create_")
          matching_relation.create(*args)
        else
          # lookup the matching associated entities
          matching_relation.lookup
        end
      else
        super(meth,*args,&blk)
      end
    end
  end

  module ClassMethods
    include PassiveRecord::Core
    include PassiveRecord::Associations
    include PassiveRecord::Hooks

    include Enumerable
    extend Forwardable


    def all
      instances_by_id.values
    end
    def_delegators :all, :each

    def find_by(conditions)
      if conditions.is_a?(Identifier)
        find_by_id(conditions)
      elsif conditions.is_a?(Array) && conditions.all? { |c| c.is_a?(Identifier) }
        find_by_ids(conditions)
      else
        where(conditions).first
      end
    end

    def where(conditions)
      Query.new(self, conditions)
    end

    def create(attrs={})
      instance = new

      instance.singleton_class.class_eval { attr_accessor :id }
      instance.send(:"id=", Identifier.generate)
      register(instance)

      attrs.each do |(k,v)|
        instance.send("#{k}=", v)
      end

      after_create_hooks.each do |hook|
        hook.run(instance)
      end

      instance
    end

    protected
    def find_by_id(id)
      instances_by_id[id]
    end

    def find_by_ids(ids)
      instances_by_id.select { |id,_| ids.include?(id) }.values
    end

    private
    def instances_by_id
      @instances ||= {}
    end

    def register(model)
      instances_by_id[model.id] = model
      self
    end
  end
end
