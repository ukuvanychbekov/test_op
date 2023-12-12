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

module Users
  module Sessions
    class TableComponent < ::TableComponent
      columns :is_current, :browser, :device, :updated_at
      sortable_columns :updated_at
      options :current_session

      def initial_sort
        %i[updated_at desc]
      end

      def headers
        [
          [:is_current, { caption: I18n.t('users.sessions.current') }],
          [:browser, { caption: I18n.t('users.sessions.browser') }],
          [:device, { caption: I18n.t('users.sessions.device') }],
          [:updated_at, { caption: I18n.t('attributes.updated_at') }]
        ]
      end
    end
  end
end
