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
or look them up based on attributes, or even utilize some limited relational semantics,
but have no real need for persistence?

PassiveRecord may be right for you.


## Features

  - Just 'include PassiveRecord' to activate a PORO in the system
  - New objects are tracked and assigned IDs
  - Query on attributes and simple relations (belongs_to, has_one, has_many)
  - No database required!

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
    dog.child # ==> child

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
