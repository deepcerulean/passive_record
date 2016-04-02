![passive record logo](https://raw.githubusercontent.com/deepcerulean/passive_record/master/logo.png)


* [Documentation](https://rubygems.org/gems/passive_record)
* [Email](mailto:joe at deepc.io)

[![Code Climate GPA](https://codeclimate.com/github/deepcerulean/passive_record/badges/gpa.svg)](https://codeclimate.com/github/deepcerulean/passive_record)
[![Codeship Status for deepcerulean/passive_record](https://www.codeship.io/projects/66bb2d90-ba61-0133-af95-025ac38368ea/status)](https://codeship.com/projects/135673)
[![Test Coverage](https://codeclimate.com/github/deepcerulean/passive_record/badges/coverage.svg)](https://codeclimate.com/github/deepcerulean/passive_record/coverage)
[![Gem Version](https://badge.fury.io/rb/passive_record.svg)](https://badge.fury.io/rb/passive_record)
[![Join the chat at https://gitter.im/deepcerulean/passive_record](https://badges.gitter.im/deepcerulean/passive_record.svg)](https://gitter.im/deepcerulean/passive_record?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## Description

PassiveRecord is an extremely lightweight in-memory pseudo-relational algebra.

We implement a simplified subset of AR's interface in pure Ruby.

## Why?

Do you need to track objects by ID and look them up again,
or look them up based on attributes,
or even utilize some relational semantics,
but have no real need for persistence?

PassiveRecord may be right for you!


## Features

  - Build relationships with belongs_to, has_one and has_many
  - Query on attributes and associations
  - Supports many-to-many and self-referential relationships
  - No database required!
  - Just `include PassiveRecord` to get started

## Examples

````ruby
    require 'passive_record'

    class Model
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

    # Let's build some models!
    parent = Parent.create
    => Parent (id: 1, child_ids: [], dog_ids: [])

    child = parent.create_child
    => Child (id: 1, dog_id: nil, parent_id: 1)

    dog = child.create_dog
    => Dog (id: 1, child_id: 1)

    # Inverse relationships
    dog.child
    => Child (id: 1, dog_id: 1, parent_id: 1)

    Dog.find_by child: child
    => Dog (id: 1, child_id: 1)

    # Has many through
    parent.dogs
    => [ ...has_many :through relation... ]

    parent.dogs.all
    => [Dog (id: 1, child_id: 1)]

    # Nested queries
    Dog.find_all_by(child: { parent: parent })
    => [Dog (id: 1, child_id: 1)]
````

## PassiveRecord API


  A class including PassiveRecord will gain the following new instance and class methods.

### Instance Methods


  A class `Role` which is declared to `include PassiveRecord` will gain the following instance methods:
  - `role.update(attrs_hash)`
  - `role.destroy`
  - `role.to_h`
  - We override `role.inspect` to show ID and visible attributes

### Class Methods


  A class `User` which is declared to `include PassiveRecord` will gain the following class methods:

  - `User.all` and `User.each`
  - `User.create(name: 'Aloysius')`
  - `User.descendants`
  - `User.destroy(id)`
  - `User.destroy_all`
  - `User.each` enumerates over `User.all`, giving `User.count`, `User.first`, etc.
  - `User.find(id_or_ids)`
  - `User.find_by(name: 'Aloysius')`
  - `User.find_all_by(job: ['manager', 'developer', 'qa'])`
  - `User.where(birthday: 1.day.ago...1.day.from_now)` (returns a `PassiveRecord::Query` object)

### Belongs To

  A model `Child` which is declared `belongs_to :parent` will gain:

  - `child.parent`
  - `child.parent_id`
  - `child.parent=`
  - `child.parent_id=`

### Has One

  A model `Parent` which declares `has_one :child` will gain:

  - `parent.child`
  - `parent.child_id`
  - `parent.child=`
  - `parent.child_id=`
  - `parent.create_child(attrs)`

### Has Many / Has Many Through / HABTM

  A model `Parent` which declares `has_many :children` or `has_and_belongs_to_many :children` will gain:

  - `parent.children` (returns a `Relation`, documented below)
  - `parent.children=`
  - `parent.children_ids`
  - `parent.children_ids=`
  - `parent.children<<`
  - `parent.create_child(attrs)`
  - `parent.children.all?(&predicate)`
  - `parent.children.empty?`
  - `parent.children.where(conditions)` (returns a `Core::Query`)
  - `parent.children.pluck(attribute)`
  - `parent.children.sum(attribute)`
  - `parent.children.average(attribute)`
  - `parent.children.mode(attribute)`

### Relations

  Parent models which declare `has_many :children` gain a `parent.children` instance that returns an explicit PassiveRecord relation object, which has the following public methods:

  - `parent.children.all`
  - `parent.children.each` enumerates over `parent.children.all`, giving `parent.children.count`, `parent.children.first`, etc.
  - `parent.children.all?(&predicate)`
  - `parent.children.empty?`
  - `parent.children.where(conditions)` (returns a `Core::Query`)
  - `parent.children<<` (insert a new child into the relation)

### Queries

  You can acquire `Core::Query` objects through the class method `where`. These are chainable, accept nested conditions that traverse relationships, and understand scopes defined as class methods. The query object will have the following public methods:

  - `Post.where(conditions).all`
  - `Post.where(conditions).each` enumerates over `where(conditions).all`, so we have `where(conditions).count`, `where(conditions).first`, etc.
  - `Post.where(conditions).create(attrs)`
  - `Post.where(conditions).first_or_create(attrs)`
  - `Post.where(conditions).pluck(attr)`
  - `Post.where(conditions).sum(attr)`
  - `Post.where(conditions).average(attr)`
  - `Post.where(conditions).mode(attr)`
  - `Post.where(conditions).where(further_conditions)` (chaining)
  - `Post.where.not(conditions)` (negation)
  - `Post.where(conditions).or(Post.where(conditions))` (disjunction)
  - `Post.active.recent` (scoping with class methods that return queries; supports chaining)

  `conditions` here is expected to be a hash of attribute values. Note that there is special behavior for certain kinds of values.

  - Ranges select models with an attribute covered by the range (behaving like `BETWEEN`). For instance you might query for users with birthdays between yesterday and today with `User.where(birthday: 1.day.ago...1.day.from_now)`
  - Arrays select models with an attribute whose value is in the array (behaving like `IN`), so for instance you may query for users whose job title is included in a list of job titles like: `User.find_all_by(job_title: ['manager', 'developer', 'qa'])`
  - Hash values (subhashes) select models with related models who attributes match the inner hash. So `Doctor.where(appointments: { patient: patient })` would lookup doctors whose appointments include an appointment with `patient`.

## Hooks

  - `before_create :call_a_method`
  - `after_create :call_another_method, :and_then_call_another_one`
  - `before_update do manually_invoke(a_method) end`
  - `after_update { or_use_a_block }`
  - `before_destroy :something`
  - `after_destroy { something_else }`

# Prior Art

  - Approaches exist that use ActiveRecord directly, and then override various methods in such a way to prevent AR from trying to persist the model. The canonical example here is the [tableless model](http://railscasts.com/episodes/193-tableless-model?view=asciicast) approach, and the use case given there is a model that wraps around sending an email. This is maybe interesting because, similar to the round-trip with a database, sending mail is externally "effectful" (and so, for instance, you may wish to take additional care around confirmation or retry logic, in order ensure you are not sending the same message more than once.)
  - These approaches are seen as somewhat hacky today, given that [ActiveModel](https://github.com/rails/rails/tree/master/activemodel) can give plain old Ruby objects a lot of the augmentations that ActiveRecord gives, such as validations, hooks and attribute management. However I don't really see a way to do relations that interoperate with ActiveRecord the way you could, at least to some degree, with tableless models.  - It's not really clear to me yet if it's interesting for PassiveRecord to be able to interoperate smoothly with ActiveRecord relations. It seems like we might be able to pull some similar tricks as the "tableless" approach in order to permit at least some relations to work between them.  But their intentions are so different I can't help but think there would be very strange bugs lurking in any such integration -- so the encouraged architecture would be a complete separation between active and passive models.

## Copyright

Copyright (c) 2016 Joseph Weissman
