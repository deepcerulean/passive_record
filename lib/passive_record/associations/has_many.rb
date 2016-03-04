module PassiveRecord
  module Associations
    class HasManyAssociation < Struct.new(:parent_class, :child_class_name, :children_name_sym)
      def to_relation(parent_model)
        HasManyRelation.new(self, parent_model)
      end

      def target_name_symbol
        children_name_sym
      end
    end

    class HasManyRelation < HasOneRelation
      include Enumerable
      extend Forwardable

      def all
        child_class.where(parent_model_id_field => parent_model.id).all
      end
      def_delegators :all, :each

      def last
        all.last
      end

      def all?(*args)
        all.all?(*args)
      end

      def empty?
        all.empty?
      end

      def where(conditions={})
        child_class.where(conditions.merge(parent_model_id_field.to_sym => parent_model.id))
      end

      def <<(child)
        child.send(parent_model_id_field + "=", parent_model.id)
        all
      end

      def pluck(attr)
        all.map(&attr)
      end

      def sum(attr)
        pluck(attr).inject(&:+)
      end

      def average(attr)
        sum(attr) / count
      end

      def mode(attr)
        arr = pluck(attr)
        freq = arr.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
        arr.max_by { |v| freq[v] }
      end

      def singular?
        false
      end
    end
  end
end
