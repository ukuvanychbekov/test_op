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

class API::V3::FileLinks::FileLinksOpenAPI < API::OpenProjectAPI
  helpers Storages::Peripherals::StorageErrorHelper

  using Storages::Peripherals::ServiceResultRefinements

  resources :open do
    get do
      Storages::Peripherals::Registry
        .resolve("queries.#{@file_link.storage.short_provider_type}.open_file_link")
        .call(
          storage: @file_link.storage,
          user: current_user,
          file_id: @file_link.origin_id,
          open_location: ActiveModel::Type::Boolean.new.cast(params[:location])
        )
        .match(
          on_success: ->(url) do
            redirect url, body: "The requested resource can be viewed at #{url}"
            status 303
          end,
          on_failure: ->(error) { raise_error(error) }
        )
    end
  end
end
