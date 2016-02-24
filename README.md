# passive_record

* [Homepage](https://rubygems.org/gems/passive_record)
* [Documentation](http://rubydoc.info/gems/passive_record/frames)
* [Email](mailto:jweissman1986 at gmail.com)

[![Code Climate GPA](https://codeclimate.com/github/deepcerulean/passive_record/badges/gpa.svg)](https://codeclimate.com/github/deepcerulean/passive_record)
[![Codeship Status for deepcerulean/passive_record](https://www.codeship.io/projects/66bb2d90-ba61-0133-af95-025ac38368ea/status)](https://codeship.com/projects/128700)
[![Test Coverage](https://codeclimate.com/github/deepcerulean/passive_record/badges/coverage.svg)](https://codeclimate.com/github/deepcerulean/passive_record/coverage)
[![Gem Version](https://badge.fury.io/rb/passive_record.svg)](https://badge.fury.io/rb/passive_record)

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

## Interface

  A class including PassiveRecord will gain the following new instance and class methods.

### Instance Methods

  A class `Role` which is declared to `include PassiveRecord` will gain the following instance methods:
  - `role.update(attrs_hash)`
  - `role.to_h`
  - We override `role.inspect` to show ID and visible attributes

### Class Methods

  A class `User` which is declared to `include PassiveRecord` will gain the following class methods:
  - `User.create(attrs_hash)`
  - `User.find(id_or_ids)`
  - `User.find_by(conditions_hash)`
  - `User.find_all_by(conditions_hash)`
  - `User.all` and `User.each`
  -  User is enumerable through `User.all`, so we have `User.count`, `User.first`, etc.
  - `User.where(conditions_hash)` (returns a `PassiveRecord::Query` object)
  - `User.descendants`
  - `User.destroy_all`

## Relationships

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

### Has Many

  A model `Parent` which declares `has_many :children` will gain:

  - `parent.children` (returns a `Relation`, documented below)
  - `parent.children_ids`
  - `parent.children=`
  - `parent.children_ids=`
  - `parent.create_child(attrs)`
  - `parent.children<<` (insert a related model)
  - `parent.children.all?(&predicate)`
  - `parent.children.empty?`
  - `parent.children.where` (returns a `Core::Query`)

### Explicit Relations

  Parent models decorated with `has_many :children` gain a `parent.children` instance which directly returns a PassiveRecord relation object, which has the following public interface:

  - `parent.children.all`
  -  `parent.children` is enumerable through `parent.children.all`, so we have `parent.children.count`, `parent.children.first`, etc.
  - `parent.children.all?(&predicate)`
  - `parent.children.empty?`
  - `parent.children.where(conditions)` (returns a `Core::Query`)
  - `parent.children<<` (insert a new child into the relation)

### Queries

  `Core::Query` objects (usually acquired through `where`) are chainable and have their own API.

  - `where(conditions).all`
  - Queries are enumerable through `#all`, so we have `where(conditions).count`, `where(conditions).first`, etc.
  - `where(conditions).create(attrs)`
  - `where(conditions).first_or_create`
  - `where(conditions).where(further_conditions)` (chaining)

## Hooks

  - `before_create :call_a_method`
  - `after_create :call_another_method, :and_then_call_another_one`
  - `after_update { or_use_a_block }`

## Copyright

Copyright (c) 2016 Joseph Weissman
