module PassiveRecord
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
      if conditions.is_a?(Hash)
        where(conditions).first
      else # assume we have an identifier/identifiers
        find(conditions)
      end
    end

    def find_all_by(conditions)
      if conditions.is_a?(Array) && conditions.all? { |c| c.is_a?(Identifier) }
        find_by_ids(conditions)
      else
        where(conditions).all
      end
    end

    def where(conditions={})
      Query.new(self, conditions)
    end

    def create(attrs={})
      instance = new

      instance.singleton_class.class_eval { attr_accessor :id }
      instance.send(:"id=", SecureRandomIdentifier.generate(self))

      register(instance)

      before_create_hooks.each do |hook|
        hook.run(instance)
      end

      attrs.each do |(k,v)|
        instance.send("#{k}=", v)
      end

      after_create_hooks.each do |hook|
        hook.run(instance)
      end

      instance
    end

    def destroy(id)
      @instances.reject! {|k,_| id == k }
    end

    def destroy_all
      @instances = {}
    end

    protected
    def find_by_id(id_to_find)
      find_by(id: id_to_find)
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

    def id_factory
      PassiveRecord.configuration.identify_using
    end
  end
end
