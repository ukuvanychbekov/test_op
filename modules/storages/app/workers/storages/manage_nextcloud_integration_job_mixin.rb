# frozen_string_literal: true

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

module Storages
  module ManageNextcloudIntegrationJobMixin
    using Peripherals::ServiceResultRefinements

    def perform
      OpenProject::Mutex.with_advisory_lock(
        ::Storages::NextcloudStorage,
        'sync_all_group_folders',
        timeout_seconds: 0,
        transaction: false
      ) do
        ::Storages::NextcloudStorage.automatically_managed.includes(:oauth_client).find_each do |storage|
          result = GroupFolderPropertiesSyncService.call(storage)
          result.match(
            on_success: ->(_) do
              storage.mark_as_healthy
            end,
            on_failure: ->(errors) do
              storage.mark_as_unhealthy(reason: errors.to_s)
            end
          )
        end
        true
      end
    end
  end
end
