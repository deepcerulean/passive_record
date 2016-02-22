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
  - Just `include PassiveRecord` to activate a PORO in the system

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

    # Let's create some models!
    parent = Parent.create
    => Parent (id: 1)

    child = parent.create_child
    => Child (id: 1)

    dog = child.create_dog
    => Dog (id: 1)

    # inverse relationships
    dog.child
    => Child (id: 1)

    Dog.find_by child: child
    => Dog (id: 1)

    # has many thru
    parent.dogs
    => [Dog (id: 1)]

    # nested queries
    Dog.find_all_by(child: { parent: parent })
    => [Dog (id: 1)]
````

## Requirements

## Install

    $ gem install passive_record


## Synopsis

    $ passive_record

## Copyright

Copyright (c) 2016 Joseph Weissman

See {file:LICENSE.txt} for details.
