# == Schema Information
#
# Table name: petition_plugin_details
#
#  id                 :integer          not null, primary key
#  plugin_relation_id :integer          not null
#  call_to_action     :string           not null
#  sinatures_required :integer          not null
#  presentation       :string           not null
#  deleted_at         :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

require_dependency "../petition_plugin"

class PetitionPlugin::Detail < ActiveRecord::Base
  acts_as_paranoid

  include PetitionPlugin

  belongs_to :plugin_relation
  has_many :petition_detail_versions, class_name: 'PetitionPlugin::DetailVersion', dependent: :destroy, foreign_key: "petition_plugin_detail_id"

  validates :call_to_action, presence: true
  validates :signatures_required, presence: true
  validates :presentation, presence: true

  validate :plugin_type_petition

  def past_versions
    return PetitionPlugin::DetailVersion.none unless published_version.present?
    petition_detail_versions.where "created_at < ?", published_version.created_at
  end

  def current_version
    petition_detail_versions.last
  end

  def published_version
    petition_detail_versions.where(published: true).last
  end
end
