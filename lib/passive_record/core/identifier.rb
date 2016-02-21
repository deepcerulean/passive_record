module PassiveRecord
  class Identifier < Struct.new(:value)
    def self.generate(klass)
      new(klass.count+1)
      # TODO maybe config to activate SecureRandom.uuid?
    end

    def ==(other_id)
      self.value == other_id.value rescue self.value == other_id
    end

    def inspect
      value
    end
  end
end
