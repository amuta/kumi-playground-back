class PublicShare < ApplicationRecord
  validates :uid, presence: true, uniqueness: true
  validates :blob, presence: true
end
