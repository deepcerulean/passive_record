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
  before(:each) { PassiveRecord.drop_all }

  context "a simple model including PR" do
    let!(:model) { SimpleModel.create(foo: value) }
    let(:value) { 'foo_value' }

    describe "instance methods" do
      describe "#update" do
        it 'should update attrs' do
          expect {model.update(foo: '123')}.
            to change {model.foo}.from(value).to('123')
        end

        it 'should invoke callbacks' do
          model.update(foo: 'barbazquux')
          expect(model.updated_at).to be_a(Time)
        end
      end

      describe "#destroy" do
        it 'should remove the entity and freeze it' do
          doomed = SimpleModel.create
          doomed_id = doomed.id
          expect(SimpleModel.find(doomed_id)).to eq(doomed)
          doomed.destroy
          expect(SimpleModel.find(doomed_id)).to eq(nil)

          SimpleModel.destroy_all
          expect{10.times{SimpleModel.create}}.to change{SimpleModel.count}.by(10)
        end
      end

      describe "#inspect" do
        it 'should report attribute details' do
          expect(model.inspect).to eq("SimpleModel (id: #{model.id.inspect}, foo: \"foo_value\")")
        end

        it 'should report relations' do
          dog = Family::Dog.create
          expect(dog.inspect).
            to eq("Family::Dog (id: #{dog.id.inspect}, breed: \"#{dog.breed}\", created_at: #{dog.created_at}, sound: \"bark\", child_id: nil)")

          child = Family::Child.create
          child.dogs << dog
          expect(dog.inspect).
            to eq("Family::Dog (id: #{dog.id.inspect}, breed: \"#{dog.breed}\", created_at: #{dog.created_at}, sound: \"bark\", child_id: #{child.id.inspect})")

          expect(child.inspect).
            to eq("Family::Child (id: #{child.id.inspect}, created_at: #{child.created_at}, name: \"Alice\", parent_id: nil, toy_id: nil, toy_quality_ids: [], dog_ids: [#{dog.id.inspect}], secret_club_ids: [])")
        end
      end

      describe "#id" do
        it 'should be retrievable by id' do
          expect(SimpleModel.find_by(model.id)).to eq(model)
          expect(SimpleModel.find(model.id)).to eq(model)
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

        it 'should assign ids' do
          expect(SimpleModel.create(id: 'the_id').id).to eq('the_id')
        end
      end

      describe "#first_or_create" do
        it 'should assign attributes' do

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
          subject(:model) { SimpleModel.create(id: 'model_id') }
          it 'should lookup a record based on an identifier' do
            expect(SimpleModel.find(-1)).to eq(nil)
            expect(SimpleModel.find(model.id)).to eq(model)
            expect(SimpleModel.find('model_id')).to eq(model)
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

                expect{SimpleModel.where(id: 'another_id').first_or_create(foo: 'ack') }.not_to change{SimpleModel.count}
                expect(SimpleModel.find('another_id').foo).to eq('ack')
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
          let(:author) { Author.create }

          subject(:posts_with_comment_by_user) do
            Post.find_by comments: { author: author }
          end

          before do
            post.create_comment(author: author)
          end

          it 'should find a single record through a nested query' do
            expect(post).to eq(posts_with_comment_by_user)
          end

          it 'should find multiple records through a nested query' do
            another_post = Post.create
            another_post.create_comment(author: author)

            posts = Post.find_all_by comments: { author: author }
            expect(posts.count).to eq(2)
          end

          it 'should find records through a doubly-nested query' do
            feed = Feed.create
            blog = feed.create_blog
            post = blog.create_post

            # expect( Post.find_by(blog: { feed_id: feed.id }) ).to eq(post)
            expect( Post.find_by(blog: { feed: { id: feed.id }}) ).to eq(post)
          end
        end

        context 'queries with ranges' do
          let(:model) { Model.create }
          it 'should find where attribute value is in range' do
            model.created_at = 2.days.ago
            expect(Model.find_by(created_at: 3.days.ago..1.day.ago)).to eq(model)
          end
        end

        context 'queries with arrays (subset)' do
          it 'should find where attribute value is included in subset' do
            model_a = Model.create(id: 10)
            model_b = Model.create(id: 11)
            Model.create(id: 12)
            expect(Model.find_all_by(id: [10,11])).to eq([model_a, model_b])
          end
        end

        context 'queries with negations' do
          it 'should find where attribute value is NOT equal' do
            model_a = Model.create(id: 'alpha')
            model_b = Model.create(id: 'beta')

            expect(Model.where.not(id: 'alpha').first).to eq(model_b)
            expect(Model.where.not(id: 'beta').first).to eq(model_a)
          end
        end

        context 'queries with disjunctions' do
          let(:poms_or_pugs) do
            Family::Dog.
              where(breed: 'pom').or(Family::Dog.where(breed: 'pug'))
          end

          let(:poms_or_small_dogs) do
            Family::Dog.
              where(breed: 'pom').or(Family::Dog.where(size: %w[ tiny small ]))
          end

          before do
            @pom = Family::Dog.create(breed: 'pom', size: 'tiny')
            @pug = Family::Dog.create(breed: 'pug', size: 'big')

            Family::Dog.create(breed: 'mutt', size: 'medium')
            Family::Dog.create(breed: 'lab', size: 'large')

            @pap = Family::Dog.create(breed: 'papillon', size: 'small')
          end

          it 'should find where attributes match EITHER query' do
            expect(poms_or_pugs.all).to eq([@pom, @pug])
            expect(poms_or_small_dogs.all).to eq([@pom, @pap])
          end

          it 'should be able to refine a disjunction' do
            expect(
              poms_or_pugs.where(size: %w[ tiny small ]).all
            ).to eq([@pom])
          end
        end

        context 'query chaining' do
          it 'should handle conjoining scopes together' do
            Post.create published_at: 10.days.ago, active: true
            Post.create active: false
            recent_and_active = Post.create active: true

            expect(Post.active.recent.all).to eq([recent_and_active])
            expect(Post.recent.active.all).to eq([recent_and_active])
          end
        end

        context 'queries with scopes' do
          let!(:post) { Post.create(published_at: 10.days.ago) }
          let!(:another_post) {Post.create(published_at: 2.days.ago)}

          describe 'should restrict using class method' do
            it 'should use a class method as a scope' do
              expect(Post.recent).not_to include(post)
              expect(Post.recent).to include(another_post)
            end

            it 'should negate a nullary scope' do
              expect(Post.where.not.recent).to include(post)
              expect(Post.where.not.recent).not_to include(another_post)
            end

            it 'should use a class method with an argument as a scope' do
              expect(Post.where.published_within_days(3)).not_to include(post)
              expect(Post.where.published_within_days(3)).to include(another_post)
            end

            it 'should negate a scope with an argument' do
              expect(Post.where.not.published_within_days(3)).to include(post)
              expect(Post.where.not.published_within_days(3)).not_to include(another_post)
            end
          end
        end

        context 'querying with scopes through relationships' do
          let(:network) { Network.create }
          let(:stream) { network.create_stream }
          let(:channel) { stream.create_channel }
          let(:feed) { channel.create_feed }
          let(:a_blog) { feed.create_blog }

          let!(:not_recent_post) { a_blog.create_post(published_at: 10.days.ago) }
          let!(:recent_post) do
            a_blog.create_post(published_at: 1.day.ago)
          end

          let!(:special_category)   { recent_post.create_category(special: true) }
          let!(:unspecial_category) { recent_post.create_category(special: false) }

          let!(:approved_comment)   { recent_post.create_comment(approved: true) }
          let!(:unapproved_comment) { recent_post.create_comment(approved: false) }

          let!(:promoted_tag) { recent_post.create_tag(promoted: true) }
          let!(:unpromoted_tag) { recent_post.create_tag(promoted: false) }

          ###
          #
          let(:another_network) { Network.create }
          let(:another_stream) { another_network.create_stream }
          let(:another_channel) { another_stream.create_channel }
          let(:another_feed) { another_channel.create_feed }
          let(:another_blog) { another_feed.create_blog }


          let!(:post_from_unrelated_blog) { another_blog.create_post(published_at: 1.day.ago) }
          let!(:unrelated_comment) do
            post_from_unrelated_blog.create_comment(approved: true)
          end

          let!(:another_category) do
            post_from_unrelated_blog.create_category(special: true)
          end

          let!(:another_tag) { post_from_unrelated_blog.create_tag(promoted: true) }

          describe 'should find related models through a has many' do
            it 'should refine' do
              expect(a_blog.posts.recent).to include(recent_post)
              expect(a_blog.posts.recent).not_to include(not_recent_post)
            end

            it 'should restrict' do
              a_blog.posts.all.each do |post|
                expect(another_blog.posts.all.map(&:id)).not_to include(post.id)
              end
            end
          end

          describe 'should find related models on a has_many through' do
            it 'should refine' do
              expect(feed.posts.recent).to include(recent_post)
              expect(feed.posts.recent).not_to include(not_recent_post)
            end

            it 'should restrict' do
              feed.posts.each do |post|
                expect(another_feed.posts).not_to include(post)
              end
            end
          end

          describe 'should find related models on a nested has_many thru' do
            it 'should refine' do
              expect(channel.posts.recent).to include(recent_post)
              expect(channel.posts.recent).not_to include(not_recent_post)
            end

            it 'should restrict' do
              channel.posts.each do |post|
                expect(another_channel.posts).not_to include(post)
              end
            end
          end

          describe 'should find related models on a double-nested has_many thru' do
            it 'should refine' do
              expect(stream.posts.recent).to include(recent_post)
              expect(stream.posts.recent).not_to include(not_recent_post)
            end

            it 'should restrict' do
              expect(stream.posts.where.all).not_to be_empty
              stream.posts.where.all.each do |post|
                expect(another_stream.posts.where.all).not_to include(post)
              end
            end
          end

          describe 'should find related models on a deeply nested has_many thru' do
            it 'should refine' do
              expect(network.posts.recent).to include(recent_post)
              expect(network.posts.recent).not_to include(not_recent_post)
            end

            it 'should restrict' do
              network.posts.all.each do |post|
                expect(another_network.posts.all.map(&:id)).not_to include(post.id)
              end
            end
          end

          describe 'should find related models on a recursive has_many thru' do
            it 'should refine' do
              expect(network.comments.approved).to include(approved_comment)
              expect(network.comments.approved).not_to include(unapproved_comment)
            end

            it 'should restrict' do
              expect(network.comments.all).not_to be_empty
              network.comments.all.each do |comment|
                expect(another_network.comments).not_to include(comment)
              end
            end
          end

          describe 'should find related models a recursive has_many :thru a habtm' do

            it 'should refine' do
              expect(network.tags.promoted).to include(promoted_tag)
              expect(network.tags.promoted).not_to include(unpromoted_tag)
            end

            it 'should restrict' do
              expect(network.tags.all).not_to be_empty
              expect(another_network.tags.all).not_to be_empty
              network.tags.all.each do |tag|
                expect(another_network.tags.all).not_to include(tag)
              end
            end
          end

          describe 'should find related nested models through a manual habtm' do
            it 'should refine' do
              expect(network.categories.special).to include(special_category)
              expect(network.categories.special).not_to include(unspecial_category)
            end

            it 'should restrict' do
              expect(another_network.categories.all).not_to be_empty
              expect(network.categories.all).not_to be_empty
              another_network.categories.where.all.each do |category|
                expect(network.categories.where.all).not_to include(category)
              end
            end
          end
        end
      end
    end
  end

  context 'hooks' do
    context 'after create hooks' do
      it 'should use a symbol to invoke a method' do
        expect(Family::Child.create.name).to eq("Alice")
      end

      it 'should use a block' do
        expect(Family::Dog.create.sound).to eq("bark")
      end

      it 'should use an inherited block' do
        expect(Family::Parent.create.created_at).to be_a(Time)
      end
    end
  end

  context 'associations' do
    context 'one-to-one relationships' do
      let(:child) { Family::Child.create }
      let(:another_child) { Family::Child.create }

      it 'should create children' do
        expect { child.create_toy }.to change { Family::Toy.count }.by(1)
        expect(child.toy).to eq(Family::Toy.last)
      end

      it 'should have inverse relationships' do
        toy = child.create_toy
        expect(toy.child).to eq(child)

        another_toy = another_child.create_toy
        expect(another_toy.child).to eq(another_child)
      end

      it 'should assign parents' do
        toy = Family::Toy.create
        toy.child = child
        expect(child.toy).to eq(toy)

        child.toy = Family::Toy.create
        expect(child.toy).not_to eq(toy)
      end
    end

    context 'one-to-many relationships' do
      let(:parent) { Family::Parent.create }
      let(:another_parent) { Family::Parent.create(children: [another_child]) }
      let(:another_child) { Family::Child.create }

      describe "#xxx<<" do
        it 'should create children with <<' do
          child = Family::Child.create
          expect {parent.children << child}.to change{parent.children.count}.by(1)
          expect(parent.children).to include(child)
        end
      end

      describe "#create_xxx" do
        it 'should create children' do
          expect { parent.create_child }.to change{ Family::Child.count }.by(1)
          expect(parent.children).to all(be_a(Family::Child))
        end
      end

      it 'should assign children on creation' do
        expect(another_parent.children.all).to match_array([another_child])
      end

      it 'should create inverse relationships' do
        child = parent.create_child
        expect(child.parent).to eq(parent)

        another_child = parent.create_child
        expect(another_child.parent).to eq(parent)

        expect(child.id).not_to eq(another_child.id)
        expect(parent.children.all).to eq([child, another_child])
        expect(parent.child_ids).to eq([child.id, another_child.id])
      end

      it 'should provide arithmetic helpers' do
        parent.create_child(age: 10)
        parent.create_child(age: 10)
        parent.create_child(age: 40)

        expect(parent.children.pluck(:age)).to eq([10,10,40])
        expect(parent.children.sum(:age)).to eq(60)
        expect(parent.children.average(:age)).to eq(20)
        expect(parent.children.mode(:age)).to eq(10)

        expect(parent.children.where(:age => 10).pluck(:age)).to eq([10,10])
        expect(parent.children.where(:age => 10).sum(:age)).to eq(20)
      end
    end

    context 'one-to-many through relationships' do
      let(:parent) { Family::Parent.create }
      let(:child) { parent.create_child }

      it 'should collect children of children' do
        child.create_dog(breed: 'mutt')
        expect(parent.dogs.all).to all(be_a(Family::Dog))
        expect(parent.dogs.count).to eq(1)
        expect(parent.dogs.first).to eq(child.dogs.first)
        expect(parent.dog_ids).to eq([child.dogs.first.id])
      end

      it 'should chain where clauses' do
        mutt = child.create_dog(breed: 'mutt')
        pit = child.create_dog(breed: 'pit')

        # another mutt, not the same childs
        another_mutt = Family::Dog.create(breed: 'mutt')

        expect(Family::Dog.where(breed: 'mutt').all).to eq([mutt, another_mutt])
        expect(child.dogs.where(breed: 'mutt').all).to eq([mutt])
        expect(child.dogs.where.not(breed: 'mutt').all).to eq([pit])

        expect(
          child.dogs.
            where(breed: 'mutt').all
        ).to eq(
          Family::Dog.
            where(child_id: child.id).
            where(breed: 'mutt').all
        )
      end

      it 'should do the nested query example from the readme' do
        child.create_dog
        expect(Family::Dog.find_all_by(child: {parent: parent})).
          to eq(parent.dogs.all)
      end

      it 'should work for has-one intermediary relationships' do
        child.create_toy
        expect(parent.toys).to all(be_a(Family::Toy))
        expect(parent.toys.count).to eq(1)
        expect(parent.toys.first).to eq(child.toy)
      end

      it 'should attempt to construct intermediary relations' do
        expect { parent.create_toy(child: child) }.to change {Family::Toy.count}.by(1)
        expect(Family::Toy.last.child).to eq(child)
        expect(Family::Toy.last.child.parent).to eq(parent)
        expect { 3.times { parent.toys << Family::Toy.create } }.to change {Family::Toy.count}.by(3)
        expect { 3.times { parent.toys << Family::Toy.create } }.to change {parent.toys.count}.by(3)
        expect(parent.toys.last.child).not_to be_nil

        expect{parent.create_toy}.to change{Family::Toy.count}.by(1)
      end

      it 'should construct intermediary relations with many-through-many' do
        expect{parent.dogs << Family::Dog.create}.to change{parent.dogs.count}.by(1)

        expect{parent.create_dog}.to change{parent.dogs.count}.by(1)

        expect{parent.toys << Family::Toy.create}.to change{parent.toys.count}.by(1)
        expect{parent.create_dog(child: child)}.to change{child.dogs.count}.by(1)
        expect{parent.create_dog(child_id: child.id)}.to change{child.dogs.count}.by(1)
      end

      it 'should accept class name' do
        post = Post.create
        author = Author.create
        Comment.create(post: post, author: author)

        expect(post.commenters.all).to eq([author])
      end
    end

    context 'many-to-many' do
      let(:patient) { Patient.create }
      let(:doctor)  { Doctor.create }
      let!(:appointment) { Appointment.create(patient: patient, doctor: doctor) }

      it 'should manage many-to-many relations' do
        expect(appointment.doctor).to eq(doctor)
        expect(appointment.patient).to eq(patient)

        expect(patient.doctors.all).to eq([doctor])
        expect(doctor.patients.all).to eq([patient])
      end

      it 'should handle insertion' do
        expect{patient.doctors << Doctor.create}.to change{patient.doctors.count}.by(1)
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

        expect(user_a.friends.all).to eq([user_b])
        expect(user_b.friends.all).to eq([user_a])
      end
    end

    context 'manual habtm' do
      let!(:resource) { Resource.create }
      let!(:user) { User.create }

      it 'should permit relations' do
        expect(user.resources).to be_empty
        expect(resource.users).to be_empty

        ResourceAllocation.create(user: user, resource: resource)

        expect(user.resources).to include(resource)
        expect(resource.users).to include(user)
      end

      it 'should permit querying' do
        ResourceAllocation.create(user: user, resource: resource)
        expect(user.resources.where.all).to include(resource)
      end
    end

    context 'direct habtm' do
      before(:each) { PassiveRecord.drop_all }
      let!(:user) { User.create roles: [role] }
      let(:role) { Role.create }
      let(:another_user) { User.create }

      it 'should manage direct habtm relations' do
        expect(role.users).to include(user)
        expect(user.roles).to include(role)
        expect(role.user_ids).to eq([user.id])
        expect(user.role_ids).to eq([role.id])
        expect {role.users << another_user}.to change{role.users.count}.by(1)
      end

      it 'should handle inverse relations' do
        expect {role.users << another_user}.to change{another_user.roles.count}.by(1)
      end

      it 'should work inside modules' do
        child = Family::Child.create
        secret_club = child.create_secret_club

        expect(secret_club).to be_a(Family::SecretClub)
        expect(secret_club.children.all).to eq([child])
        expect(child.secret_clubs.first.create_child).to be_a(Family::Child)
      end
    end

    context 'has many through has one' do
      it 'should manage relationships' do
        child = Family::Child.create
        toy_quality = child.create_toy_quality(name: 'fun')
        child.create_toy_quality(name: 'cool')
        child.create_toy_quality(name: 'radical')

        expect(child.toy_qualities.all).to include(toy_quality)
        expect(child.toy_qualities.count).to eq(3)
        expect(child.toy_qualities.map(&:name)).to eq(%w[ fun cool radical ])
      end
    end
  end
end
