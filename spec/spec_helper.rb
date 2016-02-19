require 'rspec'
require 'pry'
require 'passive_record'

class Model
  include PassiveRecord
end

class SimpleModel < Struct.new(:foo)
  include PassiveRecord
end

class Dog < Model
  belongs_to :child
end

class Child < Model
  has_one :dog
  belongs_to :parent
end

class Parent < Model
  has_many :children
  has_many :dogs, :through => :children
end
