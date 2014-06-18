# -*- encoding : utf-8 -*-
require "mongoid"
require "active_support/concern"
require 'mindpin_simple_tags/tag'
require 'mindpin_simple_tags/tagging'

module MindpinSimpleTags
  extend ActiveSupport::Concern

  included do
    extend ClassMethods
  end

  class << self
    def set_user_model(klass)
      Tagging.belongs_to :user,
                         :foreign_key => :user_id,
                         :class_name  => klass.to_s
    end
  end

  module ClassMethods
    def simple_taggable
      include Tagging::TaggableMethods
    end
  end

  Mongoid::Document.send :include, self
end
