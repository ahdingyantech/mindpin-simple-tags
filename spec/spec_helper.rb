# -*- encoding : utf-8 -*-
require 'coveralls'
Coveralls.wear!

require 'config/db_init'
require 'mindpin-simple-tags'
require "pry"

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  simple_taggable

  field :name, :type => String
end

MindpinSimpleTags.set_user_model(User)

class Book
  include Mongoid::Document
  include Mongoid::Timestamps
  simple_taggable

  belongs_to :creator, :class_name => 'User'

  field :name, :type => String
end


RSpec.configure do |config|
  config.before(:all) do
    Mongoid.purge!
  end

  config.after(:each) do
    Mongoid.purge!
  end
end
