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

      case meth.to_s
      when target_name       
        matching_relation.lookup
      when "#{target_name}=" 
        matching_relation.parent_model_id = args.first.id
      when "create_#{target_name}", "create_#{target_name.singularize}"
        matching_relation.create(*args)
      when "#{target_name}_id"
        matching_relation.parent_model_id
      when "#{target_name}_id="
        matching_relation.parent_model_id = args.first
      when "#{target_name}_ids", "#{target_name.singularize}_ids"
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
        possible_target_names(relation).include?(meth.to_s)
      end
    end

    def possible_target_names(relation)
      target_name = relation.association.target_name_symbol.to_s
      [
        target_name,
        "#{target_name}=",
        "#{target_name}_id",
        "#{target_name}_ids",
        "#{target_name.singularize}_ids",
        "#{target_name}_id=",
        "create_#{target_name}",
        "create_#{target_name.singularize}"
      ]
    end
  end
end
