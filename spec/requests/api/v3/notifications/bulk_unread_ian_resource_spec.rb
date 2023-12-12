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

require 'spec_helper'

RSpec.describe API::V3::Notifications::NotificationsAPI,
               'bulk unset read status',
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }

  shared_let(:recipient) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:other_recipient) { create(:user) }
  shared_let(:notification1) do
    create(:notification, recipient:, project:, resource: work_package, read_ian: true)
  end
  shared_let(:notification2) do
    create(:notification, recipient:, project:, resource: work_package, read_ian: true)
  end
  shared_let(:notification3) do
    create(:notification, recipient:, project:, resource: work_package, read_ian: true)
  end
  shared_let(:other_user_notification) do
    create(:notification,
           recipient: other_recipient,
           read_ian: true,
           project:,
           resource: work_package)
  end

  let(:filters) { nil }

  let(:read_path) do
    api_v3_paths.path_for :notification_bulk_unread_ian, filters:
  end

  let(:parsed_response) { JSON.parse(last_response.body) }

  before do
    login_as current_user

    post read_path
  end

  describe 'POST /api/v3/notifications/unread_ian' do
    let(:current_user) { recipient }

    it 'returns 204' do
      expect(last_response.status)
        .to be(204)
    end

    it 'sets all the current users`s notifications to read' do
      expect(Notification.where(id: [notification1.id, notification2.id, notification3.id]).pluck(:read_ian))
        .to all(be_falsey)

      expect(Notification.where(id: [other_user_notification]).pluck(:read_ian))
        .to all(be_truthy)
    end

    context 'with a filter for id' do
      let(:filters) do
        [
          {
            'id' => {
              'operator' => '=',
              'values' => [notification1.id.to_s, notification2.id.to_s]

            }
          }
        ]
      end

      it 'sets the current users`s notifications matching the filter to read' do
        expect(Notification.where(id: [notification1.id, notification2.id]).order(id: :asc).pluck(:read_ian))
          .to all(be_falsey)

        expect(Notification.where(id: [other_user_notification.id, notification3.id]).order(id: :asc).pluck(:read_ian))
          .to all(be_truthy)
      end
    end

    context 'with an invalid filter' do
      let(:filters) do
        [
          {
            'bogus' => {
              'operator' => '=',
              'values' => []

            }
          }
        ]
      end

      it 'returns 400' do
        expect(last_response.status)
          .to be(400)
      end
    end
  end
end
