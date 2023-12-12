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

class Storages::FileLinkSyncService
  using Storages::Peripherals::ServiceResultRefinements

  def initialize(user:)
    @user = user
  end

  def call(file_links)
    resulting_file_links = file_links
      .group_by(&:storage_id)
      .map { |storage_id, storage_file_links| sync_storage_data(storage_id, storage_file_links) }
      .reduce([]) do |state, sync_result|
        sync_result.match(
          on_success: ->(sr) { state + sr },
          on_failure: ->(_) { state }
        )
      end

    ServiceResult.success(result: resulting_file_links)
  end

  private

  def sync_storage_data(storage_id, file_links)
    storage = ::Storages::Storage.find(storage_id)
    ::Storages::Peripherals::Registry
      .resolve("queries.#{storage.short_provider_type}.files_info")
      .call(storage:, user: @user, file_ids: file_links.map(&:origin_id))
      .map { |file_infos| to_hash(file_infos) }
      .match(
        on_success: set_file_link_permissions(file_links),
        on_failure: ->(_) {
          ServiceResult.success(result: file_links.map do |file_link|
            file_link.origin_permission = :error
            file_link
          end)
        }
      )
  end

  def to_hash(file_infos)
    file_infos.index_by { |file_info| file_info.id.to_s }.to_h
  end

  def set_file_link_permissions(file_links)
    ->(file_infos) do
      resulting_file_links = []

      file_links.each do |file_link|
        file_info = file_infos[file_link.origin_id]

        case file_info.status_code
        when 200
          next if file_info.trashed

          update_file_link(file_link, file_info)

          file_link.origin_permission = :view
        when 403
          file_link.origin_permission = :not_allowed
        when 404
          file_link.destroy
          next
        else
          file_link.origin_permission = :error
        end

        resulting_file_links << file_link
        file_link.save
      end

      ServiceResult.success(result: resulting_file_links)
    end
  end

  def update_file_link(file_link, file_info)
    file_link.origin_mime_type = file_info.mime_type
    file_link.origin_created_by_name = file_info.owner_name
    file_link.origin_last_modified_by_name = file_info.last_modified_by_name
    file_link.origin_name = file_info.name
    file_link.origin_created_at = file_info.created_at
    file_link.origin_updated_at = file_info.last_modified_at

    file_link
  end
end
