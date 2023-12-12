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

require 'spec_helper'

RSpec.describe Projects::Activity, 'meeting' do
  shared_let(:project) do
    create(:project, :updated_a_long_time_ago)
  end

  let(:initial_time) { Time.current }

  let(:meeting) do
    create(:meeting,
           project:)
  end

  let(:meeting2) do
    create(:meeting,
           project:)
  end

  let(:work_package) do
    create(:work_package,
           project:)
  end

  def latest_activity
    Project.with_latest_activity.find(project.id).latest_activity_at
  end

  describe '.with_latest_activity' do
    it 'set project.latest_activity_at to the latest updated meeting time' do
      meeting.update(updated_at: initial_time - 10.seconds)
      meeting2.update(updated_at: initial_time - 20.seconds)

      # there is a loss of precision for timestamps stored in database
      expect(latest_activity).to be_within(0.00001).of(meeting.updated_at)
    end

    it 'takes the time stamp of the latest activity across models' do
      work_package.update(updated_at: initial_time - 10.seconds)
      meeting.update(updated_at: initial_time - 20.seconds)

      # Order:
      # work_package
      # meeting

      expect(latest_activity).to be_within(0.00001).of(work_package.updated_at)

      work_package.update(updated_at: meeting.updated_at - 10.seconds)

      # Order:
      # meeting
      # work_package

      expect(latest_activity).to be_within(0.00001).of(meeting.updated_at)
    end
  end
end
