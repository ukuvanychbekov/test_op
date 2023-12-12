#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module TeamPlanner
  module Overview
    class TableComponent < ::TableComponent
      options :current_user
      columns :name, :project_name, :created_at
      sortable_columns :name, :project_name, :created_at

      def initial_sort_correlation
        ['queries.name', 'asc']
      end

      def sortable_columns_correlation
        super.merge(name: 'queries.name',
                    project_name: 'projects.name',
                    created_at: 'queries.created_at')
      end

      def paginated?
        true
      end

      def headers
        [
          [:name, { caption: I18n.t(:label_name) }],
          [:project_name, { caption: Query.human_attribute_name(:project) }],
          [:created_at, { caption: Query.human_attribute_name(:created_at) }]
        ]
      end
    end
  end
end
