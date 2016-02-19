require 'spec_helper'
require 'passive_record'

class Model # < Struct.new(:foo)
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

# class Patient < Model
#   has_many :appointments
#   has_many :doctors, :through => :appointments
# end
# 
# class Appointment < Model
#   belongs_to :patient
#   belongs_to :doctor
# end
# 
# class Doctor < Model
#   has_many :appointments
#   has_many :patients, :through => :appointments
# end

###

describe Model do
  describe "with a simple model including PR" do
    let!(:model) { SimpleModel.create(value) }
    let(:value) { 'foo_value' }

    describe "#id" do
      it 'should be retrievable by id' do
        expect(SimpleModel.find_by(model.id)).to eq(model)
      end
    end

    describe "#count" do
      it 'should indicate the size of the models list' do
        expect { SimpleModel.create }.to change { SimpleModel.count }.by(1)
      end
    end

    describe "#find_by" do
      it 'should be retrievable by query' do
        expect(SimpleModel.find_by(foo: 'foo_value')).to eq(model)
      end
    end
  end

  context 'one-to-one relationships' do
    let(:child) { Child.create }
    let(:another_child) { Child.create }

    it 'should create children' do
      expect { child.create_dog }.to change { Dog.count }.by(1) #from(0).to(1)
      expect(child.dog).to eq(Dog.first)
    end

    it 'should have inverse relationships' do
      dog = child.create_dog #dog.create
      expect(dog.child).to eq(child)
      another_dog = another_child.create_dog #.create
      expect(another_dog.child).to eq(another_child)
    end
  end

  context 'one-to-many relationships' do
    let(:parent) { Parent.create }

    it 'should create children' do
      expect { parent.create_child }.to change{ Child.count }.by(1)
      expect(parent.children).to all(be_a(Child))
    end

    it 'should create inverse relationships' do
      child = parent.create_child
      expect(child.parent).to eq(parent)

      another_child = parent.create_child
      expect(another_child.parent).to eq(parent)

      expect(child.id).not_to eq(another_child.id)
      expect(parent.children).to eq([child, another_child])
    end
  end

  context 'one-to-many through relationships' do
    let(:parent) { Parent.create }
    let(:child) { parent.create_child }
    subject(:dogs) { parent.dogs }

    it 'should create children of children' do
      child.create_dog
      expect(dogs).to all(be_a(Dog))
      expect(dogs.first).to eq(child.dog)
    end
  end
end
