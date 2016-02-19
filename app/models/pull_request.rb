
# == Schema Information
#
# Table name: pull_requests
#
#  id                      :uuid             not null, primary key
#  base_repo_full_name     :string(255)
#  number                  :integer
#  user_id                 :uuid
#  created_at              :datetime
#  updated_at              :datetime
#  number_of_comments      :integer
#  number_of_commits       :integer
#  number_of_additions     :integer
#  number_of_deletions     :integer
#  number_of_changed_files :integer
#  merged_at               :datetime
#

class PullRequest < ActiveRecord::Base
  belongs_to :user
  has_many :pull_request_reviews, dependent: :destroy
  has_many :pairings, dependent: :destroy

  attr_accessor :data, :merged

  validates :user, presence: true
  validates :number, presence: true, numericality: true
  validates :base_repo_full_name, presence: true
  validates :body, presence: true
  validates :number_of_comments, presence: true, numericality: true
  validates :number_of_commits, presence: true, numericality: true
  validates :number_of_additions, presence: true, numericality: true
  validates :number_of_deletions, presence: true, numericality: true
  validates :number_of_changed_files, presence: true, numericality: true
  validates :merged_at, presence: true
  validate :must_be_merged

  after_create :create_pairings
  after_create :create_reviews

  def data=(data)
    self.user ||= User.where(nickname: data['user']['login']).first
    self.base_repo_full_name ||= data['base']['repo']['full_name']
    self.body ||= data['body']
    self.number ||= data['number']
    self.merged ||= data['merged']
    self.number_of_comments ||= data['comments']
    self.number_of_commits ||= data['commits']
    self.number_of_additions ||= data['additions']
    self.number_of_deletions ||= data['deletions']
    self.number_of_changed_files ||= data['changed_files']
    self.merged_at ||= Time.parse(data['merged_at']) if data['merged_at'].present?

    @data = data
  end

  def points
    if number_of_deletions > 2 * number_of_additions && number_of_deletions > 1000
      100
    elsif number_of_additions > 500
      50
    elsif number_of_deletions > 2 * number_of_additions && number_of_deletions > 100
      30
    elsif number_of_additions > 100
      15
    elsif number_of_additions < 10
      5
    else
      10
    end
  end

  def comments
    @comments ||= User.global_client
      .pull_request(base_repo_full_name, number)
      .rels[:comments].get.data
  end

  private

  def create_reviews
    comments.each do |c|
      PullRequestReview.create(user: User.where(nickname: c.user.login).first, body: c.body, pull_request: self)
    end
  end

  def create_pairings
    match = body.match(/paired[\s]*with[\s]*(?<names>[@\w+\s]+)/i)
    if match.present?
      pairs = match[:names].split(' ').select{ |p| p.include?('@') }
      pairs.each do |pair|
        pair_user = User.where(nickname: pair.delete('@')).first
        if pair_user.present?
          Pairing.create(user: pair_user, pull_request: self)
        end
      end
    end
    Pairing.create(user: user, pull_request: self)
  end

  def must_be_merged
    errors.add(:base, 'PR must be merged') unless merged == true
  end
end
