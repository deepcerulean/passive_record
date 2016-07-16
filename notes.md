                  (channel spec)               (stream spec)

    Stream ->                                  [parent]
    Channel ->    [from parent model]          [intermed]
    Feed ->       [intermediary relation]      [from nested...]
    (*) Blog ->   [ from nested assn...? ]
    Post

   we need a process that starts the other way, and 'completes' the through
   like a belongs_to :through ... ?

for stream spec:

  - nested assn is (channel has_many posts through feeds)
    if we could get at (feed has_many posts through blogs)
    i think we could recurse?
    note: it should be the 'nested assn' for (channels has_many posts)...

  - intermediray relation is (stream has many channels...) # through
    can we get at channels has many posts?

    in this context Channel is 

      `intermediary_relation.child_class_name.to_s.singularize.constantize' [ ugh! ]
     



Post.where(blog_id: 1)

Post.where(blog: { feed_id: 234 })

Post.where(blog: { feed: { channel_id: 567 }})

Post.where(blog: { feed: { channel: { stream: 890 }}})


# network.posts.recent

Post.where(published_at: 1.day.ago...Time.now, blog: { feed: { channel: { stream: { network_id: 1234 }}}})


---------



Okay, so in this case we are trying to do `feed.posts.recent` ....

=> #<struct PassiveRecord::Associations::HasManyThroughAssociation
 parent_class=Feed,
 child_class_name="Post",
 target_name_symbol=:posts,
 through_class=:blogs,
 base_association=#<struct PassiveRecord::Associations::HasManyAssociation parent_class=Feed, child_class_name="Blog", children_name_sym=:blogs>,
 habtm=false>

We are constructing a query on `Post`, and want to say {blog: {feed_id: ...}} ...

The through_class is :blogs which needs to be singularized

---

In the other case we are just trying to do `user.resources.where ...` ...

=> #<struct PassiveRecord::Associations::HasManyThroughAssociation
 parent_class=User,
 child_class_name="Resource",
 target_name_symbol=:resources,
 through_class=:resource_allocations,
 base_association=#<struct PassiveRecord::Associations::HasManyAssociation parent_class=User, child_class_name="ResourceAllocation", children_name_sym=:resource_allocations>,
 habtm=false>

We are constructing a query on `Resource` ...

We need to check from the perspective of `Resource` what the relation is to allocations...?

