#
# build a hash-initialized 'record' class
#
# singleton_class pattern taken from http://stackoverflow.com/questions/15256940/in-ruby-how-do-i-implement-a-class-whose-new-method-creates-subclasses-of-itsel
#
class HStruct
  singleton_class.class_eval { alias :old_new :new }

  def initialize(attributes={})
    attributes.each do |k,v|
      send("#{k}=",v)
    end
  end

  def fetch_values(*args)
    to_h.fetch_values(*args)
  end

  def to_h
    attribute_names.inject({}) do |hsh,k|
      hsh[k] = send("#{k}"); hsh
    end
  end

  def self.new(*attribute_names)
    Class.new(self){
      singleton_class.class_eval {
        alias :new :old_new
      }

      attribute_names.each do |k|
        attr_accessor k.to_sym
      end

      define_method(:attribute_names) { attribute_names }
    }
  end
end
