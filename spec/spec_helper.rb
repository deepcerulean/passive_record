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
    attr_accessor :breed, :size
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
    belongs_to :parent
    has_one :toy
    has_many :toy_qualities, :through => :toy
    has_many :dogs
    has_and_belongs_to_many :secret_clubs

    attr_reader :name
    after_create :give_name
    attr_accessor :age

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

  has_many :resource_allocations
  has_many :resources, :through => :resource_allocations
end

class Role < Model
  has_and_belongs_to_many :users
end

class ResourceAllocation < Model
  belongs_to :user
  belongs_to :resource
end

class Resource < Model
  # TODO why can't we use a custom class name here???
  has_many :resource_allocations #, class_name: "ResourceAllocation"
  has_many :users, through: :resource_allocations
end

###
#

class Network < Model
  has_many :streams
  has_many :posts, :through => :streams
  has_many :comments, :through => :posts
  has_many :tags, :through => :posts
  has_many :categories, :through => :posts
end

class Stream < Model
  belongs_to :network
  has_many :channels
  has_many :posts, :through => :channels
end

class Channel < Model
  belongs_to :stream
  has_many :feeds
  has_many :posts, :through => :feeds
end

class Feed < Model
  belongs_to :channel
  has_many :blogs
  has_many :posts, :through => :blogs
end

class Blog < Model
  has_many :posts
  belongs_to :feed
end

class Tag < Model
  has_and_belongs_to_many :posts
  attr_accessor :promoted
  def self.promoted; where(promoted: true) end
end

class Category < Model
  attr_accessor :special
  has_many :post_categories
  has_many :posts, :through => :post_categories

  def self.special; where(special: true) end
end

class PostCategory < Model
  belongs_to :post
  belongs_to :category
end

class Post < Model
  belongs_to :author
  belongs_to :blog
  has_many :comments
  has_many :commenters, :through => :comments, :class_name => "Author"
  has_and_belongs_to_many :tags

  has_many :post_categories
  has_many :categories, :through => :post_categories

  attr_accessor :active, :published_at
  before_create { @published_at = Time.now }

  def self.active
    where(active: true)
  end

  def self.recent
    where(:published_at => 3.days.ago..Time.now)
  end

  def self.published_within_days(n)
    where(:published_at => n.days.ago..Time.now)
  end
end

class Author < Model
  has_many :posts
  has_many :comments
end

class Comment < Model
  attr_accessor :approved
  belongs_to :post
  belongs_to :author

  def self.approved; where(approved: true) end
end
