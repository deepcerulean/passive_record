module PassiveRecord
  module InstanceMethods
    def update(attrs={})
      self.class.before_update_hooks.each do |hook|
        hook.run(self)
      end

      attrs.each do |k,v|
        send("#{k}=", v)
      end

      self.class.after_update_hooks.each do |hook|
        hook.run(self)
      end

      self
    end

    def destroy
      self.class.before_destroy_hooks.each do |hook|
        hook.run(self)
      end

      self.class.destroy(self.id)

      self.class.after_destroy_hooks.each do |hook|
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

    protected
    def attribute_names
      attr_names = instance_variables
      attr_names += self.class.associations_id_syms
      attr_names += members rescue []
      attr_names.reject! { |name| name.to_s.start_with?("@_") || name.match(/join_model/) }
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
  end
end
