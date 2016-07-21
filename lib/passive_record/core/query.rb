module PassiveRecord
  module Core
    class Query
      include Enumerable
      extend Forwardable
      include PassiveRecord::ArithmeticHelpers

      attr_reader :conditions

      def initialize(klass,conditions={},scope=nil)
        @klass = klass
        @conditions = conditions
        @scope = scope
      end

      def not(new_conditions={})
        NegatedQuery.new(@klass, new_conditions)
      end

      def or(query=nil)
        DisjoinedQuery.new(@klass, self, query)
      end

      def all
        if @scope
          matching = @scope.method(:matching_instances)
          if negated?
            raw_all.reject(&matching)
          else
            raw_all.select(&matching)
          end
        else
          matching = method(:matching_instances)
          raw_all.select(&matching)
        end
      end
      def_delegators :all, :sample

      def raw_all
        @klass.all
      end

      def each
        if @scope
          matching = @scope.method(:matching_instances)
          if negated?
            raw_all.each do |instance|
              yield instance unless matching[instance]
            end
          else
            raw_all.each do |instance|
              yield instance if matching[instance]
            end
          end
        else
          matching = method(:matching_instances)
          @klass.all.each do |instance|
            yield instance if matching[instance]
          end
        end
      end

      def matching_instances(instance)
        @conditions.all? do |(field,value)|
          evaluate_condition(instance, field, value)
        end
      end

      def create(attrs={})
        @klass.create(@conditions.merge(attrs))
      end

      def first_or_create
        first || create
      end

      def where(new_conditions={})
        @conditions.merge!(new_conditions)
        self
      end

      def negated?
        false
      end

      def disjoined?
        false
      end

      def conjoined?
        false
      end

      def basic?
        !negated? && !disjoined? && !conjoined?
      end

      def and(scope_query)
        ConjoinedQuery.new(@klass, self, scope_query)
      end

      def method_missing(meth,*args,&blk)
        if @klass.methods.include?(meth)
          scope_query = @klass.send(meth,*args,&blk)
          if negated? && @scope.nil? && @conditions.empty?
            @scope = scope_query
            self
          elsif basic? && scope_query.basic?
            @conditions.merge!(scope_query.conditions)
            self
          else
            scope_query.and(self)
          end
        else
          super(meth,*args,&blk)
        end
      end

      protected
      def evaluate_condition(instance, field, value)
        case value
        when Hash  then evaluate_nested_conditions(instance, field, value)
        when Range then value.cover?(instance.send(field))
        when Array then value.include?(instance.send(field))
        else
          instance.send(field) == value
        end
      end

      def evaluate_nested_conditions(instance, field, value)
        association = instance.send(field)
        association && value.all? do |(association_field,val)|
          if association.is_a?(Associations::Relation) && !association.singular?
            association.where(association_field => val).any?
          elsif val.is_a?(Hash)
            evaluate_nested_conditions(association, association_field, val)
          else
            association.send(association_field) == val
          end
        end
      end
    end

    class NegatedQuery < Query
      def matching_instances(instance)
        @conditions.none? do |(field,value)|
          evaluate_condition(instance, field, value)
        end
      end

      def negated?
        true
      end
    end

    class DisjoinedQuery < Query
      def initialize(klass, first_query, second_query, conditions={})
        @klass = klass
        @first_query = first_query
        @second_query = second_query
        @conditions = conditions
      end

      def all
        (@first_query.where(conditions).all + @second_query.where(conditions).all).uniq
      end

      def disjoined?
        true
      end
    end

    class ConjoinedQuery < Query
      def initialize(klass, first_query, second_query, conditions={})
        @klass = klass
        @first_query = first_query
        @second_query = second_query
        @conditions = conditions
      end

      def all
        @first_query.where(conditions).all & @second_query.all
      end

      def conjoined?
        true
      end
    end

    class HasManyThroughQuery < Query
      def initialize(klass, instance, target_name_sym, conditions={})
        @klass = klass
        @instance = instance
        @target_name_sym = target_name_sym
        @conditions = conditions
      end

      def raw_all
        @instance.send(@target_name_sym).all
      end
    end
  end
end
