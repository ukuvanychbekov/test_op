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

module Queries
  class CopyService < ::BaseServices::Copy
    def self.copy_dependencies
      [
        ::Queries::Copy::ViewsDependentService,
        ::Queries::Copy::OrderedWorkPackagesDependentService
      ]
    end

    protected

    def set_attributes(_params)
      new_query = copied_query
      new_query.sort_criteria = source.sort_criteria if source.sort_criteria

      ::Queries::Copy::FiltersMapper
        .new(state, new_query.filters)
        .map_filters!

      ServiceResult.new(success: new_query.valid?, result: new_query)
    end

    def copied_query
      ::Query.new source.attributes.dup.except(*skipped_attributes).merge(project: state.project || source.project)
    end

    def skipped_attributes
      %w[id created_at updated_at project_id sort_criteria]
    end
  end
end
