# taken directly from http://stackoverflow.com/a/10729812/90042
module ClassLevelInheritableAttributes
  def self.included(base)
    base.extend(ClassMethods)    
  end

  module ClassMethods
    def inheritable_attrs(*args)
      @inheritable_attributes ||= [:inheritable_attributes]
      @inheritable_attributes += args
      args.each do |arg|
        class_eval %(
          class << self; attr_accessor :#{arg} end
        )
      end

      # binding.pry
      @inheritable_attributes
    end

    def inherited(subclass)
      @inheritable_attributes.each do |inheritable_attribute|
        instance_var = "@#{inheritable_attribute}"
        subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
      end
    end
  end
end
