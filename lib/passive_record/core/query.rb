module PassiveRecord
  module Core
    class Query
      include Enumerable
      extend Forwardable

      attr_accessor :klass, :conditions

      def initialize(klass,conditions={})
        @klass = klass
        @conditions = conditions
      end

      def not(conditions={})
        NegatedQuery.new(@klass, conditions)
      end

      def all
        return [] unless conditions
        matching = method(:matching_instances)
        klass.select(&matching)
      end
      def_delegators :all, :each

      def matching_instances(instance)
        conditions.all? do |(field,value)|
          evaluate_condition(instance, field, value)
        end
      end

      def create(attrs={})
        klass.create(conditions.merge(attrs))
      end

      def first_or_create
        first || create
      end

      def where(new_conditions={})
        @conditions = new_conditions.merge(conditions)
        self
      end

      def ==(other_query)
        @klass == other_query.klass && @conditions == other_query.conditions
      end

      def method_missing(meth,*args,&blk)
        if klass.methods.include?(meth)
          klass.send(meth,*args,&blk)
        else
          super(meth,*args,&blk)
        end
      end

      protected
      def evaluate_condition(instance, field, value)
        if value.is_a?(Hash)
          evaluate_nested_conditions(instance, field, value)
        elsif value.is_a?(Range) || value.is_a?(Array)
          value.include?(instance.send(field))
        else
          instance.send(field) == value
        end
      end

      def evaluate_nested_conditions(instance, field, value)
        association = instance.send(field)
        association && value.all? do |(association_field,val)|
          if association.is_a?(Associations::Relation) && !association.singular?
            association.where(association_field => val).any?
          else
            association.send(association_field) == val
          end
        end
      end
    end

    class NegatedQuery < Query
      def matching_instances(instance)
        conditions.none? do |(field,value)|
          evaluate_condition(instance, field, value)
        end
      end
    end
  end
end
