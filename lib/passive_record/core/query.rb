module PassiveRecord
  module Core
    class Query < Struct.new(:klass, :conditions)
      def all
        return [] unless conditions
        klass.all.select do |instance|
          conditions.all? do |(field,value)|
            if value.is_a?(Hash)
              assn = instance.send(field)
              matched = assn && value.all? do |(assn_field,val)|
                if assn.is_a?(Array)
                  assn.any? do |assc_model|
                    assc_model.send(assn_field) == val
                  end
                else
                  assn.send(assn_field) == val
                end
              end

              matched
            else
              instance.send(field) == value
            end
          end
        end
      end

      def first
        all.first
      end

      def create
        klass.create(conditions)
      end

      def first_or_create
        first || create
      end
    end
  end
end
