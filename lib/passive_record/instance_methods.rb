module PassiveRecord
  module InstanceMethods
    def inspect
      pretty_vars = instance_variables_hash.map do |k,v|
        "#{k.to_s.gsub(/^\@/,'')}: #{v.inspect}"
      end.join(', ')
      "#{self.class.name} (#{pretty_vars})"
    end

    def respond_to?(meth,*args,&blk)
      if find_relation_by_target_name_symbol(meth)
        true
      else
        super(meth,*args,&blk)
      end
    end

    def method_missing(meth, *args, &blk)
      if (matching_relation = find_relation_by_target_name_symbol(meth))
        send_relation(matching_relation, meth, *args, &blk)
      else
        super(meth,*args,&blk)
      end
    end

    protected

    def send_relation(matching_relation, meth, *args, &blk)
      target_name = matching_relation.association.target_name_symbol.to_s

      if meth.to_s == target_name
        matching_relation.lookup

      elsif meth.to_s == target_name + "="
        matching_relation.parent_model_id = args.first.id

      elsif meth.to_s.start_with?("create_")
        matching_relation.create(*args)

      elsif meth.to_s == target_name + "_id"
        matching_relation.parent_model_id

      elsif meth.to_s == target_name + "_id="
        matching_relation.parent_model_id = args.first

      elsif meth.to_s == target_name + "_ids" || meth.to_s == target_name.singularize + "_ids"
        matching_relation.parent_model.send(target_name).map(&:id)

      end
    end

    private

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
        target_name = relation.association.target_name_symbol.to_s
        meth == relation.association.target_name_symbol ||
          meth.to_s == target_name + "=" ||
          meth.to_s == target_name + "_id" ||
          meth.to_s == target_name + "_ids" ||
          meth.to_s == target_name.singularize + "_ids" ||
          meth.to_s == target_name + "_id=" ||
          meth.to_s == "create_" + target_name ||
          meth.to_s == "create_" + target_name.singularize
      end
    end
  end
end
