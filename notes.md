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


