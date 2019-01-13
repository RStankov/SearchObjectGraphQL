# frozen_string_literal: true

class Category < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :posts, inverse_of: :category, dependent: :destroy
end
