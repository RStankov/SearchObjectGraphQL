# frozen_string_literal: true

class Post < ApplicationRecord
  validates :title, presence: true, uniqueness: true
  validates :body, presence: true
  validates :category_id, presence: true

  belongs_to :category, inverse_of: :posts

  scope :published, -> { where "published_at <= date('now')" }
  scope :unpublished, -> { where "published_at IS NULL OR published_at > date('now')" }

  def published?
    published_at.present? && published_at < Time.current
  end
end
