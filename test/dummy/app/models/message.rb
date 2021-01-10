class Message
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :content
  attribute :subject

  validates :content, length: {maximum: 280}
  validates :subject, presence: true, exclusion: {in: %w[forbidden]}
end
