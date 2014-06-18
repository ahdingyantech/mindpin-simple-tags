# -*- encoding : utf-8 -*-
module MindpinSimpleTags
  class Tag
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name, :type => String

    validates :name, :presence => true,
                     :uniqueness => {:case_sensitive => false}

    has_many :taggings, :class_name => 'MindpinSimpleTags::Tagging'

    scope :by_name, lambda {|tag_name|
      where :name => tag_name
    }
  end
end
