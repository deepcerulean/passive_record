module PassiveRecord
  class Identifier < Struct.new(:value)
    def self.generate
      new(SecureRandom.uuid)
    end

    def inspect
      value
    end
  end
end
