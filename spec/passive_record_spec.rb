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

describe "passive record models" do
  context "with a simple model including PR" do
    let!(:model) { SimpleModel.create(foo: value) }
    let(:value) { 'foo_value' }

    describe "instance methods" do
      describe "#inspect" do
        it 'should report attribute details' do
          expect(model.inspect).to eq("SimpleModel (id: #{model.id.inspect}, foo: \"foo_value\")")
        end

        it 'should report relations' do
          dog = Dog.create
          expect(dog.inspect).to eq("Dog (id: #{dog.id.inspect}, created_at: #{dog.created_at}, sound: \"bark\", child_id: nil)")
        end
      end

      describe "#id" do
        it 'should be retrievable by id' do
          expect(SimpleModel.find_by(model.id)).to eq(model)
        end
      end
    end

    describe "class methods" do
      describe "#first" do
        it 'should find the first model' do
          expect(Model.first).to eq(Model.find(1))
        end
      end

      describe "#count" do
        it 'should indicate the size of the models list' do
          expect { SimpleModel.create }.to change { SimpleModel.count }.by(1)
        end
      end

      describe "#create" do
        it 'should assign attributes' do
          expect(model.foo).to eq('foo_value')
        end
      end

      describe "#destroy_all" do
        before {
          SimpleModel.create(foo: 'val1')
          SimpleModel.create(foo: 'val2')
        }

        it 'should remove all models' do
          expect { SimpleModel.destroy_all }.to change { SimpleModel.count }.by(-SimpleModel.count)
        end
      end

      context 'querying by id' do
        describe "#find" do
          subject(:model) {  SimpleModel.create }
          it 'should lookup a record based on an identifier' do
            expect(SimpleModel.find(-1)).to eq(nil)
            expect(SimpleModel.find(model.id)).to eq(model)
          end

          it 'should lookup records based on primary key value' do
            expect(SimpleModel.find(model.id.value)).to eq(model)
          end

          it 'should lookup records based on ids' do
            model_b = SimpleModel.create
            expect(SimpleModel.find([model.id, model_b.id])).to eq([model, model_b])
          end
        end

        describe "#where" do
          it 'should return a query obj' do
            expect(SimpleModel.where(id: 'fake_id')).to be_a(PassiveRecord::Core::Query)
          end

          context "queries" do
            describe "#create" do
              it 'should create objects' do
                expect{SimpleModel.where(id: 'new_id').create }.to change{SimpleModel.count}.by(1)
              end
            end

            describe "#first_or_create" do
              it 'should create the object or return matching' do
                expect{SimpleModel.where(id: 'another_id').first_or_create }.to change{SimpleModel.count}.by(1)
                expect{SimpleModel.where(id: 'another_id').first_or_create }.not_to change{SimpleModel.count}
              end
            end
          end
        end
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
        expect(parent.children_ids).to eq([child.id, another_child.id])
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
        expect(parent.dog_ids).to eq([child.dogs.first.id])
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

      it 'should attempt to construct intermediary relations' do
        expect { parent.create_toy(child: child) }.to change {Toy.count}.by(1)
        expect(Toy.last.child).to eq(child)
        expect(Toy.last.child.parent).to eq(parent)
      end

      it 'should accept class name' do
        post = Post.create
        user = User.create
        Comment.create(post: post, user: user)
        expect(post.commenters).to eq([user])
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

describe "configuration" do
  describe 'configuring id factory' do
    context 'with default config' do
      it 'should generate simple identifiers' do
        expect(Model.create.id).to be_a(PassiveRecord::Identifier)
      end
    end

    context 'with a new id factory configured' do
      before do
        PassiveRecord.configure do |passive_records|
          passive_records.identify_using = PassiveRecord::SecureRandomIdentifier
        end
      end

      it 'should generate uuids' do
        expect(Model.create.id).to be_a(PassiveRecord::SecureRandomIdentifier)
      end
    end
  end
end
