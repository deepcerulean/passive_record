module PassiveRecord
  module PrettyPrinting
    def inspect
      pretty_vars = instance_variables_hash.map do |k,v|
        "#{k.to_s.gsub(/^\@/,'')}: #{v.inspect}"
      end.join(', ')
      "#{self.class.name} (#{pretty_vars})"
    end

    protected

    def uninspectable_instance_variables
      []
    end

    private

    def inspectable_instance_variables
      vars = instance_variables
      vars += members rescue []
      vars - uninspectable_instance_variables
    end

    # from http://stackoverflow.com/a/8417341/90042
    def instance_variables_hash
      Hash[
        inspectable_instance_variables.
        reject { |sym| sym.to_s.start_with?("@_") }.
        map { |name| [name, (instance_variable_get(name) rescue send(name))] }
      ]
    end
  end
end
