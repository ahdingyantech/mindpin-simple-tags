require 'mindpin_simple_tags/tag'
require 'mindpin_simple_tags/tagging'

module MindpinSimpleTags
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def simple_taggable
        send(:include, MindpinSimpleTags::Tagging::TaggableMethods)
      end
    end
  end
end


ActiveRecord::Base.send :include, MindpinSimpleTags::Base