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

module API
  module V3
    module WorkPackages
      class WorkPackagesByProjectAPI < ::API::OpenProjectAPI
        resources :work_packages do
          helpers ::API::V3::WorkPackages::WorkPackagesSharedHelpers

          get do
            authorize_in_any_work_package(:view_work_packages, in_project: @project)

            service = raise_invalid_query_on_service_failure do
              WorkPackageCollectionFromQueryParamsService
                .new(current_user)
                .call(params.merge(project: @project))
            end

            service.result
          end

          post &::API::V3::Utilities::Endpoints::Create.new(model: WorkPackage,
                                                            parse_service: WorkPackages::ParseParamsService,
                                                            params_modifier: ->(attributes) {
                                                              attributes[:project_id] = @project.id
                                                              attributes[:send_notifications] = notify_according_to_params
                                                              attributes
                                                            })
                                                       .mount

          mount ::API::V3::WorkPackages::CreateProjectFormAPI
        end
      end
    end
  end
end
