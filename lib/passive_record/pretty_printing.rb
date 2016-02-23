module PassiveRecord
  module PrettyPrinting
    def inspect
      pretty_vars = to_h.map do |k,v|
        "#{k.to_s.gsub(/^\@/,'')}: #{v.inspect}"
      end.join(', ')

      "#{self.class.name} (#{pretty_vars})"
    end
  end
end
