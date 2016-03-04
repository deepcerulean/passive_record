module PassiveRecord
  module ArithmeticHelpers
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
  end
end
