require 'spec_helper'

describe PassiveRecord do
  describe ".drop_all" do
    it 'should remove all records' do
      SimpleModel.create
      Post.create
      10.times { Doctor.create }

      PassiveRecord.drop_all

      expect(SimpleModel.count).to eq(0)
      expect(Post.count).to eq(0)
      expect(Doctor.count).to eq(0)
    end
  end
end

describe Model do
  describe "with a simple model including PR" do
    let!(:model) { SimpleModel.create(foo: value) }
    let(:value) { 'foo_value' }

    describe "#id" do
      it 'should be retrievable by id' do
        expect(SimpleModel.find_by(model.id)).to eq(model)
      end
    end

    context 'should be enumerable over models' do
      describe "#count" do
        it 'should indicate the size of the models list' do
          expect { SimpleModel.create }.to change { SimpleModel.count }.by(1)
        end
      end
    end

    describe "#create" do 
      it 'should assign attributes' do
        expect(model.foo).to eq('foo_value')
      end
    end

    describe "#destroy_all" do
      before { 
        SimpleModel.create(foo: 'val')
        SimpleModel.create(foo: 'val')
      }
      it 'should remove all models' do
        expect { SimpleModel.destroy_all }.to change { SimpleModel.count }.by(-SimpleModel.count)
      end
    end

    context 'querying by attributes' do
      describe "#find_by" do
        it 'should be retrievable by query' do
          expect(SimpleModel.find_by(foo: 'foo_value')).to eq(model)
        end

        context 'nested queries' do
          let(:post) { Post.create }
          let(:user) { User.create }

          subject(:posts_with_comments_by_user) do
            Post.find_by comments: { user: user }
          end

          before do
            post.create_comment(user: user)
          end

          it 'should find a single record through a nested query' do
            post = Post.find_by comments: { user: user }
            expect(post).to eq(post)
          end

          it 'should find multiple records through a nested query' do
            another_post = Post.create
            another_post.create_comment(user: user)

            posts = Post.find_all_by comments: { user: user }
            expect(posts).to eq([post,another_post])
          end
        end
      end
    end
  end

  context 'hooks' do
    context 'after create hooks' do
      it 'should use a symbol to invoke a method' do
        expect(Child.create.name).to eq("Alice")
      end

      it 'should use a block' do
        expect(Dog.create.sound).to eq("bark")
      end

      it 'should use an inherited block' do
        expect(Parent.create.created_at).to be_a(Time)
      end
    end
  end

  context 'associations' do
    context 'one-to-one relationships' do
      let(:child) { Child.create }
      let(:another_child) { Child.create }

      it 'should create children' do
        expect { child.create_toy }.to change { Toy.count }.by(1)
        expect(child.toy).to eq(Toy.last)
      end

      it 'should have inverse relationships' do
        toy = child.create_toy
        expect(toy.child).to eq(child)
        another_toy = another_child.create_toy
        expect(another_toy.child).to eq(another_child)
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

      it 'should collect children of children' do
        child.create_dog
        expect(parent.dogs).to all(be_a(Dog))
        expect(parent.dogs.count).to eq(1)
        expect(parent.dogs.first).to eq(child.dogs.first)
      end

      it 'should do the nested query example from the readme' do
        child.create_dog
        expect(Dog.find_all_by(child: {parent: parent})).
          to eq(parent.dogs)
      end

      it 'should work for has-one intermediary relationships' do
        child.create_toy
        expect(parent.toys).to all(be_a(Toy))
        expect(parent.toys.count).to eq(1)
        expect(parent.toys.first).to eq(child.toy)
      end
      
    end

    context 'many-to-many' do
      let(:patient) { Patient.create }
      let(:doctor)  { Doctor.create }
      let!(:appointment) { Appointment.create(patient: patient, doctor: doctor) }

      it 'should manage many-to-many relations' do
        expect(appointment.doctor).to eq(doctor)
        expect(appointment.patient).to eq(patient)

        expect(patient.doctors).to eq([doctor])
        expect(doctor.patients).to eq([patient])
      end
    end

    context 'self-referential many-to-many' do
      let!(:user_a) { User.create }
      let!(:user_b) { User.create }

      it 'should permit relations' do
        expect(user_a.friends).to be_empty

        # need to create bidirectional friendship
        Friendship.create(user: user_a, friend: user_b)
        Friendship.create(user: user_b, friend: user_a)

        expect(user_a.friends).to eq([user_b])
        expect(user_b.friends).to eq([user_a])
      end
    end
  end
end
