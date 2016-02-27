module PassiveRecord
  class SecureRandomIdentifier < Struct.new(:value)
    def self.generate(klass)
      new(generate_id_value_for(klass))
    end

    def self.generate_id_value_for(*)
      SecureRandom.uuid
    end

    def ==(other_id)
      self.value == other_id.value rescue self.value == other_id
    end

    def inspect
      value
    end
  end
end
