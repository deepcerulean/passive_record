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

      def all
        return [] unless conditions
        klass.select do |instance|
          conditions.all? do |(field,value)|
            if value.is_a?(Hash)
              assn = instance.send(field)
              matched = assn && value.all? do |(assn_field,val)|
                if assn.is_a?(Array)
                  assn.any? do |assc_model|
                    assc_model.send(assn_field) == val
                  end
                else
                  if assn.is_a?(Core::Query) || (assn.is_a?(Associations::Relation) && !assn.singular?)
                    assn.where(assn_field => val)
                  else
                    assn.send(assn_field) == val
                  end
                end
              end
              matched
            else
              instance.send(field) == value
            end
          end
        end
      end
      def_delegators :all, :each

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
    end
  end
end
