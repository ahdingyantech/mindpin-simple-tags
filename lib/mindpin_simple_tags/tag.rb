# -*- encoding : utf-8 -*-
module MindpinSimpleTags
  class Tag < ActiveRecord::Base
    attr_accessible :name

    validates :name, :presence => true, 
                     :uniqueness => {:case_sensitive => false}

    has_many :taggings, :class_name => 'MindpinSimpleTags::Tagging'

    scope :by_name, lambda { |tag_name| {:conditions => "name = '#{tag_name}'"} }
  end
end
