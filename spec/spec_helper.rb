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

###

class Patient < Model
  has_many :appointments
  has_many :doctors, :through => :appointments
end

class Appointment < Model
  belongs_to :patient
  belongs_to :doctor
end

class Doctor < Model
  has_many :appointments
  has_many :patients, :through => :appointments
end

###
#
# self-referential case
#
class Friendship < Model
  belongs_to :user
  belongs_to :friend, class_name: "User"
end

class User < Model
  has_many :friendships
  has_many :friends, :through => :friendships
end
