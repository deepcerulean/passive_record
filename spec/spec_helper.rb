require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'rspec'
require 'pry'
require 'passive_record'

class Model
  include PassiveRecord
  attr_accessor :created_at
  after_create { @created_at = Time.now }
end

class SimpleModel < Struct.new(:foo)
  include PassiveRecord
  attr_reader :updated_at
  after_update { @updated_at = Time.now }
end

module Family
  class Dog < Model
    attr_reader :sound
    attr_accessor :breed
    belongs_to :child
    before_create { @breed = %w[pom pug].sample }
    after_create { @sound = 'bark' }
  end

  class ToyQuality < Model
    attr_accessor :name
    belongs_to :toy
  end

  class Toy < Model
    belongs_to :child
    has_many :toy_qualities
    attr_reader :kind
    after_create {@kind = %w[ stuffed_animal blocks cards ].sample}
  end

  class Child < Model
    has_one :toy
    has_many :toy_qualities, :through => :toy
    has_many :dogs
    belongs_to :parent
    has_and_belongs_to_many :secret_clubs

    attr_reader :name
    after_create :give_name

    def give_name; @name = "Alice" end
  end

  class SecretClub < Model
    has_and_belongs_to_many :children
  end

  class Parent < Model
    has_many :children
    has_many :dogs, :through => :children
    has_many :toys, :through => :children
  end
end
#include Family

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
  has_and_belongs_to_many :roles
end

class Role < Model
  has_and_belongs_to_many :users
end

###

class Post < Model
  has_many :comments
  has_many :commenters, :through => :comments, :class_name => "User"

  attr_accessor :published_at
  before_create { @published_at = Time.now }

  def self.recent
    where(:published_at => 3.days.ago..Time.now)
  end

  def self.published_within_days(n)
    where(:published_at => n.days.ago..Time.now)
  end
end

class User < Model
  has_many :comments
end

class Comment < Model
  belongs_to :post
  belongs_to :user
end
