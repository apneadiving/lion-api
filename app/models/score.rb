class Score < ActiveRecord::Base
  include Pusherable

  attr_accessor :time

  belongs_to :user

  validates :user, presence: true
  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time_span, inclusion: { in: %w(all_time weekly) }

  scope :all_time, -> { where(time_span: 'all_time') }
  scope :weekly, -> { where(time_span: 'weekly') }

  def self.give(time: nil, user: nil, points: nil)
    # all_time
    where(user: user).all_time.first_or_create.increment_points_by(points)

    # weekly
    if time > 1.week.ago
      where(user: user).weekly.first_or_create.increment_points_by(points)
    end
  end

  def self.take(user: nil, points: nil)
    # we assume revoking points will be done within one week of giving points
    # that is, a task will be unmarked as completed only short after it was marked as completed
    where(user: user).each { |s| s.decrement_points_by(points) }
  end

  def self.reset
    update_all(points: 0)
  end

  def increment_points_by(points_to_add)
    transaction do
      update(points: points + points_to_add)
    end
  end

  def decrement_points_by(points_to_remove)
    transaction do
      update(points: points - points_to_remove)
    end
  end
end