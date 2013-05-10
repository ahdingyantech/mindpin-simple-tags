mindpin-simple-tags
===================

define simpe tags logic for mindpin products


# 使用说明

### 引入 gem

```
# Gemfile
  gem 'mindpin-simple-tags',
      :git => 'git://github.com/mindpin/mindpin-simple-tags.git',
      :tag => '0.0.1'
```

### 增加 migration

```ruby
  create_table :tags do |t|
    t.string :name
    t.timestamps
  end

  create_table :taggings do |t|
    t.integer :tag_id
    t.integer :taggable_id
    t.string  :taggable_type
    t.integer :user_id
    t.timestamps
  end

  add_index :taggings, :tag_id
  add_index :taggings, [:taggable_id, :taggable_type]
```

### 增加声明

```
class Book < ActiveRecord::Base
  simple_taggable
end
```

### 私有 tag
```
book.set_tag_list('编程,java，api 教程')
book.private_tags(book.creator).map(&:name)  # => ['编程','java','api','教程']

book.set_tag_list('编程,java，api 教程', :user => user)
book.private_tags(user).map(&:name)          # => ['编程','java','api','教程']
```

### 两个或两个以上私有 tag,自动变为公有 tag
```
book.set_tag_list('java', :user => user_1)
book.public_tags.map(&:name)     # => []
book.set_tag_list('java', :user => user_2)
book.public_tags.map(&:name)     # => ['java']
```


### 创建者创建的 私有 tag,自动变为公有 tag
```
book.set_tag_list('java')
book.public_tags.map(&:name)    # => ['java']
```

### 设置私有tag,并强制设置为公共tag
```
# 通过 force_public 设置的公共tag,不会因为少于两人设置为私有tag,而被干掉
book.set_tag_list('java',:user => user_1, :force_public => true)
book.public_tags.map(&:name)   # => ['java']
```

### 删除公共tag
```
book.remove_public_tag('编程 api java')
```

### 根据私有 tag 查询
```
Book.by_tag('java', :user => @user_1)
```

### 根据公有 tag 查询
```
Book.by_tag('java')
```
