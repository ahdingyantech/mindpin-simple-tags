# -*- encoding : utf-8 -*-
module MindpinSimpleTags
  class Tagging
    include Mongoid::Document
    include Mongoid::Timestamps

    field :is_force_public, :type => String

    belongs_to :tag, :class_name => 'MindpinSimpleTags::Tag'
    belongs_to :taggable, :polymorphic => true

    validates :tag, :taggable, :presence => true

    scope :without_user, proc {
      where :user_id => nil
    }

    scope :with_user, proc {
      where :user_id.ne => nil
    }

    scope :without_force_public, proc {
      where :is_force_public.ne => true
    }

    scope :by_user, lambda {|user|
      where :user_id => user.id
    }

    scope :by_tag,  lambda {|tag|
      where :tag_id => tag.id
    }

    scope :by_tags, lambda {|tags|
      where :tag_id.in => tags.map(&:id)
    }

    after_save :update_public_tags
    after_destroy :update_public_tags

    def update_public_tags
      return if self.user_id.blank?

      count  = taggable.private_tagged_count tag
      tagged = taggable.tagged_with_creator? tag

      if tagged || count > 1
        _add_public_tag(taggable, tag)
        return true
      end

      _remove_public_tag(taggable, tag)
    end

    private
      def _add_public_tag(taggable, tag)
        return if taggable.public_tags.include?(tag)
        taggable.taggings.create(:tag => tag)
      end

      def _remove_public_tag(taggable, tag)
        return unless taggable.public_tags.include?(tag)
        taggable.taggings.by_tag(tag).without_user.without_force_public.destroy_all
      end

    module TaggableMethods
      extend ActiveSupport::Concern

      included do
        self.has_many :taggings,
                      :class_name => 'MindpinSimpleTags::Tagging',
                      :as         => :taggable
      end

      def public_tags
        tag_ids = Tagging.where(
          :user_id       => nil,
          :taggable_type => self.class.name,
          :taggable_id   => self.id
        ).pluck(:tag_id).uniq

        Tag.where(:id.in => tag_ids)
      end

      def private_tags(user)
        tag_ids = Tagging.where(
          :user_id       => user.id,
          :taggable_type => self.class.name,
          :taggable_id   => self.id
        ).pluck(:tag_id).uniq

        Tag.where(:id.in => tag_ids)
      end

      def set_tag_list(str, options = {})
        user = options[:user] || (
          self.is_a?(User) ? self : self.creator
        )
        after_tags = _get_by_str(str)

        _set_private_tags(after_tags, user)

        if options[:force_public]
          _set_force_public_tags(after_tags)
        end

        after_tags
      end

      def remove_public_tag(str)
        tags = _get_by_str(str)

        tags.each do |tag|
          self.taggings.by_tag(tag).without_user.destroy_all
        end
      end

      def private_tagged_count(tag)
        taggings.by_tag(tag).with_user.count
      end

      def tagged_with_creator?(tag)
        user = self.is_a?(User) ? self : self.creator
        taggings.by_tag(tag).by_user(user).present?
      end

      private

        def _set_private_tags(after_tags, user)
          before_tags  = self.private_tags(user)
          removed_tags = before_tags - after_tags
          added_tags   = after_tags  - before_tags

          if removed_tags.present?
            self.taggings.by_user(user).by_tags(removed_tags).destroy_all
          end

          added_tags.each do |tag|
            self.taggings.create(:tag => tag, :user => user)
          end
        end

        def _get_by_str(str)
          tag_names = str.downcase.split(/\s|,|，/).compact.uniq
          tag_names.map do |name|
            Tag.find_or_create_by(:name => name)
          end
        end

        def _set_force_public_tags(tags)
          tags.each do |tag|
            tagging = self.taggings.by_tag(tag).without_user.first
            if tagging.blank?
              self.taggings.create(:tag => tag, :is_force_public => true)
            else
              tagging.update_attributes(:is_force_public => true)
            end
          end
        end

      module ClassMethods
        def by_tag(tag_name, options = {})
          tag = Tag.by_name(tag_name).first
          return self.where(:id => -1) if tag.blank?

          user = options[:user]
          user_id_params = user.blank? ? nil : [nil, user.id]

          taggable_ids = Tagging.where(
            :user_id       => user_id_params,
            :tag_id        => tag.id,
            :taggable_type => self.class.name
          ).pluck(:taggable_id).uniq

          self.where(:id.in => taggable_ids)
        end
      end

    end
  end
end
