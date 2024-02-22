class Form
  include ActiveModel::Model

  attr_accessor :single_required_checkbox, :single_optional_checkbox
  attr_reader :multiple_required_checkbox, :multiple_optional_checkbox

  validates :single_required_checkbox, presence: true, acceptance: true
  validates :multiple_required_checkbox, presence: true

  def multiple_required_checkbox=(value)
    @multiple_required_checkbox = Array(value).compact_blank
  end

  def multiple_optional_checkbox=(value)
    @multiple_optional_checkbox = Array(value).compact_blank
  end
end
