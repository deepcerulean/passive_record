module PassiveRecord
  module Core
    class Query < Struct.new(:klass, :conditions)
      def all
        klass.all.select do |instance|
          conditions.all? do |(field,value)|
            instance.send(field) == value
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
