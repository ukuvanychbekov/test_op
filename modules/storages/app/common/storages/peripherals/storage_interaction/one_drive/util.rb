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

module Storages::Peripherals::StorageInteraction::OneDrive::Util
  using Storages::Peripherals::ServiceResultRefinements

  class << self
    def mime_type(json)
      json.dig(:file, :mimeType) || (json.key?(:folder) ? 'application/x-op-directory' : nil)
    end

    def using_user_token(storage, user, &)
      connection_manager = ::OAuthClients::ConnectionManager
                             .new(user:, configuration: storage.oauth_configuration)

      connection_manager
        .get_access_token
        .match(
          on_success: ->(token) do
            connection_manager.request_with_token_refresh(token) { yield token }
          end,
          on_failure: ->(_) do
            ServiceResult.failure(
              result: :unauthorized,
              errors: ::Storages::StorageError.new(
                code: :unauthorized,
                data: ::Storages::StorageErrorData.new(source: connection_manager),
                log_message: 'Query could not be created! No access token found!'
              )
            )
          end
        )
    end
  end
end
