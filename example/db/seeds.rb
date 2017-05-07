Category.delete_all
Post.delete_all


category_names = [
  'Books',
  'Code',
  'Design',
  'Database',
  'Education',
  'Personal',
  'News',
  'Stuff',
  'Others'
]

categories = category_names.map do |name|
  Category.create! name: name
end

400.times do |i|
  Post.create!(
    category:       categories.sample,
    title:          "Example post #{i + 1}",
    body:           'Body text',
    views_count:    rand(1000),
    likes_count:    rand(1000),
    comments_count: rand(1000),
    published_at:   [rand(30).days.ago, rand(30).days.from_now].sample,
    created_at:     rand(30).days.ago
  )
  print '.'
end

puts ''
