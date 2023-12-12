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

module API::V3::Days
  class NonWorkingDaysAPI < ::API::OpenProjectAPI
    helpers ::API::Utilities::UrlPropsParsingHelper

    resources :non_working do
      get &::API::V3::Utilities::Endpoints::Index.new(
        api_name: "Day",
        model: NonWorkingDay,
        render_representer: NonWorkingDayCollectionRepresenter,
        self_path: -> { api_v3_paths.days_non_working }
      ).mount

      route_param :date, type: Date, desc: 'NonWorkingDay DATE' do
        after_validation do
          @non_working_day = NonWorkingDay.find_by!(date: declared_params[:date])
        end

        get &::API::V3::Utilities::Endpoints::Show.new(model: NonWorkingDay,
                                                       render_representer: NonWorkingDayRepresenter)
                                                  .mount
      end
    end
  end
end
