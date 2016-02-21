# passive_record

* [Homepage](https://rubygems.org/gems/passive_record)
* [Documentation](http://rubydoc.info/gems/passive_record/frames)
* [Email](mailto:jweissman1986 at gmail.com)

[![Code Climate GPA](https://codeclimate.com/github//passive_record/badges/gpa.svg)](https://codeclimate.com/github//passive_record)

## Description

PassiveRecord is an extremely lightweight in-memory pseudo-relational algebra.

We implement a simplified subset of AR's interface in pure Ruby.

## Why?

Do you need to track objects by ID and look them up again,
or look them up based on attributes,
or even utilize some relational semantics,
but have no real need for persistence?

PassiveRecord may be right for you.


## Features

  - New objects are tracked and assigned IDs
  - Build relationships with belongs_to, has_one and has_many
  - Query on attributes and associations
  - Supports many-to-many and self-referential relationships
  - No database required!
  - Just `include PassiveRecord` to activate a PORO in the system

## Examples

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

    child = parent.create_child
    dog = child.create_dog

    # inverse relationships
    dog.child # ===> dog

    Dog.find_by(child: child) # ===> dog

    # has many thru
    parent.dogs # ==> [dog]

## Requirements

## Install

    $ gem install passive_record


## Synopsis

    $ passive_record

## Copyright

Copyright (c) 2016 Joseph Weissman

See {file:LICENSE.txt} for details.
