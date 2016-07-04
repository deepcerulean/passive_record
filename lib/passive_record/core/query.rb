module PassiveRecord
  module Core
    class Query
      include Enumerable
      extend Forwardable
      include PassiveRecord::ArithmeticHelpers

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
        return [] unless @conditions
        matching = method(:matching_instances)
        if @scope
          if negated?
            @klass.reject(&@scope.method(:matching_instances))
          else
            @klass.select(&@scope.method(:matching_instances))
          end
        else
          @klass.select(&matching)
        end
      end
      def_delegators :all, :each

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
        @conditions = new_conditions.merge(@conditions)
        self
      end

      def negated?
        false
      end

      def disjoined?
        false
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
          else
            scope_query.and(self)
          end
        else
          super(meth,*args,&blk)
        end
      end

      protected
      def evaluate_condition(instance, field, value)
        if value.is_a?(Hash)
          evaluate_nested_conditions(instance, field, value)
        elsif value.is_a?(Range)
          value.cover?(instance.send(field))
        elsif value.is_a?(Array)
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
            if val.is_a?(Hash)
              evaluate_nested_conditions(association, association_field, val)
            else
              association.send(association_field) == val
            end
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
      def initialize(klass, first_query, second_query)
        @klass = klass
        @first_query = first_query
        @second_query = second_query
      end

      def all
        (@first_query.all + @second_query.all).uniq
      end

      def disjoined?
        true
      end
    end

    class ConjoinedQuery < Query
      def initialize(klass, first_query, second_query)
        @klass = klass
        @first_query = first_query
        @second_query = second_query
      end

      def all
        @first_query.all & @second_query.all
      end
    end
  end
end
