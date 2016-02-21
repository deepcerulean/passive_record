require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'rspec'
require 'pry'
require 'passive_record'

class Model
  include PassiveRecord
  attr_reader :created_at
  after_create { @created_at = Time.now }
end

class SimpleModel < Struct.new(:foo)
  include PassiveRecord
end

class Dog < Model
  attr_reader :sound
  belongs_to :child
  after_create {@sound = 'bark'}
end

class Toy < Model
  belongs_to :child
  attr_reader :kind
  after_create {@kind = %w[ stuffed_animal blocks cards ].sample}
end

class Child < Model
  has_one :toy
  has_many :dogs
  belongs_to :parent

  attr_reader :name
  after_create :give_name

  def give_name; @name = "Alice" end
end

class Parent < Model
  has_many :children
  has_many :dogs, :through => :children
  has_many :toys, :through => :children
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

### 

class Post < Model
  has_many :comments 
  has_many :commenters, :through => :comments, :class_name => "User"
end

class User < Model
  has_many :comments
end

class Comment < Model
  belongs_to :post
  belongs_to :user
end
