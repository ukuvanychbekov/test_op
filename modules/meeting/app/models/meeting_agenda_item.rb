#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
#

class MeetingAgendaItem < ApplicationRecord
  ITEM_TYPES = {
    simple: 0,
    work_package: 1
  }.freeze

  enum item_type: ITEM_TYPES

  belongs_to :meeting, foreign_key: 'meeting_id', class_name: 'StructuredMeeting'
  belongs_to :work_package, class_name: '::WorkPackage'
  has_one :project, through: :meeting
  belongs_to :author, class_name: 'User', optional: false

  acts_as_list scope: :meeting
  default_scope { order(:position) }

  scope :with_includes_to_render, -> { includes(:author, :meeting) }

  validates :meeting_id, presence: true
  validates :title, presence: true, if: Proc.new { |item| item.simple? }
  validates :work_package_id, presence: true, if: Proc.new { |item| item.work_package? }, on: :create
  validates :work_package_id,
            presence: true,
            if: Proc.new { |item| item.work_package? && item.work_package_id_changed? },
            on: :update
  validates :duration_in_minutes,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 },
            allow_nil: true

  after_create :trigger_meeting_agenda_item_time_slots_calculation
  after_save :trigger_meeting_agenda_item_time_slots_calculation, if: Proc.new { |item|
    item.duration_in_minutes_previously_changed? || item.position_previously_changed?
  }
  after_destroy :trigger_meeting_agenda_item_time_slots_calculation

  def trigger_meeting_agenda_item_time_slots_calculation
    meeting.calculate_agenda_item_time_slots
  end

  def linked_work_package?
    item_type == "work_package" && work_package.present?
  end

  def visible_work_package?
    linked_work_package? && work_package.visible?(User.current)
  end

  def deleted_work_package?
    persisted? && item_type == "work_package" && work_package_id_was.nil?
  end

  def editable?
    !(meeting&.closed? || deleted_work_package?)
  end

  def modifiable?
    !(meeting&.closed? || (deleted_work_package? && work_package_id.present?))
  end
end
