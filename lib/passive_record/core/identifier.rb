module PassiveRecord
  class Identifier < Struct.new(:value)
    def self.generate
      new(SecureRandom.uuid)
    end

    def ==(other_id)
      self.value == other_id.value
    end

    def inspect
      value
    end
  end
end
