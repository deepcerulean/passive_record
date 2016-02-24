module PassiveRecord
  module InstanceMethods
    def update(attrs={})
      attrs.each do |k,v|
        send("#{k}=", v)
      end

      self.class.after_update_hooks.each do |hook|
        hook.run(self)
      end
    end

    # from http://stackoverflow.com/a/8417341/90042
    def to_h
      Hash[
        attribute_names.
        map do |name| [
          name.to_s.gsub("@","").to_sym,  # key
          (instance_variable_get(name) rescue send(name))] # val
        end
      ]
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
        send_relation(matching_relation, meth, *args)
      else
        super(meth,*args,&blk)
      end
    end

    protected
    def attribute_names
      attr_names = instance_variables
      attr_names += self.class.associations_id_syms
      attr_names += members rescue []
      attr_names.reject! { |name| name.to_s.start_with?("@_") }
      attr_names - blacklisted_attribute_names
    end

    def blacklisted_attribute_names
      []
    end

    private

    def relata
      @_relata ||= self.class.associations&.map do |assn|
        assn.to_relation(self)
      end || []
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

    def send_relation(matching_relation, meth, *args)
      target_name = matching_relation.association.target_name_symbol.to_s

      case meth.to_s
      when target_name
        if matching_relation.singular?
          matching_relation.lookup
        else
          matching_relation
        end
      when "#{target_name}="
        if args.first.is_a?(Array)
          # need to loop through each arg and set id
          args.first.each do |child|
            child.send(matching_relation.parent_model_id_field + "=", id)
          end
        else
          # assume simple assignment
          matching_relation.parent_model_id = args.first.id
        end
      when "create_#{target_name}", "create_#{target_name.singularize}"
        matching_relation.create(*args)
      when "#{target_name}_id"
        if matching_relation.is_a?(Associations::HasOneRelation)
          matching_relation.lookup&.id
        elsif matching_relation.is_a?(Associations::BelongsToRelation)
          matching_relation.parent_model_id
        end
      when "#{target_name}_id="
        matching_relation.parent_model_id = args.first
      when "#{target_name}_ids", "#{target_name.singularize}_ids"
        matching_relation.parent_model.send(target_name).map(&:id)
      end
    end
  end
end
