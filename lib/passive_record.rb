require 'active_support'
require 'active_support/core_ext/string/inflections'

require 'passive_record/version'
require 'passive_record/core/identifier'
require 'passive_record/core/query'

require 'passive_record/class_inheritable_attrs'

require 'passive_record/associations'
require 'passive_record/hooks'

module PassiveRecord
  def self.included(base)
    base.send :include, InstanceMethods
    base.send :include, ClassLevelInheritableAttributes

    base.class_eval do
      inheritable_attrs :hooks, :associations
    end

    base.extend(ClassMethods)

    model_classes << base
  end

  def self.model_classes
    @model_classes ||= []
  end

  def self.drop_all
    (model_classes + model_classes.flat_map(&:descendants)).each(&:destroy_all)
  end

  module InstanceMethods
    def inspect
      pretty_vars = instance_variables_hash.map do |k,v|
        "#{k.to_s.gsub(/^\@/,'')}: #{v.inspect}"
      end.join(', ')
      "#{self.class.name} (#{pretty_vars})"
    end

    # from http://stackoverflow.com/a/8417341/90042
    def instance_variables_hash
      Hash[
        instance_variables.
          reject { |sym| sym.to_s.start_with?("@_") }.
          map { |name| [name, instance_variable_get(name)] } 
      ]
    end

    def relata
      @_relata ||= self.class.associations.map do |assn|
        assn.to_relation(self)
      end
    end


    def find_relation_by_target_name_symbol(meth)
      relata.detect do |relation|  # matching relation...
        meth == relation.association.target_name_symbol ||
          meth.to_s == relation.association.target_name_symbol.to_s + "=" ||
          meth.to_s == relation.association.target_name_symbol.to_s + "_id" ||
          meth.to_s == relation.association.target_name_symbol.to_s + "_id=" ||
          meth.to_s == "create_" + relation.association.target_name_symbol.to_s ||
          meth.to_s == "create_" + (relation.association.target_name_symbol.to_s).singularize
      end
    end

    def respond_to?(meth,*args,&blk)
      if find_relation_by_target_name_symbol(meth)
        true
      else
        super(meth,*args,&blk)
      end
    end

    def method_missing(meth, *args, &blk)
      matching_relation = find_relation_by_target_name_symbol(meth)

      if matching_relation
        if meth.to_s == matching_relation.association.target_name_symbol.to_s + "_id"
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

    # from http://stackoverflow.com/a/2393750/90042
    def descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def all
      instances_by_id.values
    end
    def_delegators :all, :each

    def last
      all.last
    end

    def find(id_or_ids)
      if id_or_ids.is_a?(Array)
        find_by_ids(id_or_ids)
      else
        find_by_id(id_or_ids)
      end
    end

    def find_by(conditions)
      if conditions.is_a?(Identifier)
        find_by_id(conditions)
      elsif conditions.is_a?(Array) && conditions.all? { |c| c.is_a?(Identifier) }
        find_by_ids(conditions)
      else
        where(conditions).first
      end
    end

    def find_all_by(conditions)
      if conditions.is_a?(Array) && conditions.all? { |c| c.is_a?(Identifier) }
        find_by_ids(conditions)
      else
        where(conditions).all
      end
    end

    def where(conditions)
      Query.new(self, conditions)
    end

    def create(attrs={})
      instance = new

      instance.singleton_class.class_eval { attr_accessor :id }
      instance.send(:"id=", Identifier.generate(self))

      register(instance)

      attrs.each do |(k,v)|
        instance.send("#{k}=", v)
      end

      after_create_hooks.each do |hook|
        hook.run(instance)
      end

      instance
    end

    def destroy_all
      @instances = {}
    end

    protected
    def find_by_id(_id)
      key = instances_by_id.keys.detect { |id,_| id == _id }
      instances_by_id[key] if key
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
