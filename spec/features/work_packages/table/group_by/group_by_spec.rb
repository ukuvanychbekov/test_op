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

require 'spec_helper'

RSpec.describe 'Work Package group by progress', :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:group_by) { Components::WorkPackages::GroupBy.new }

  current_user { user }

  before do
    create_list(:work_package, 3, project:, author: user)
  end

  it 'switches to grouped view when selecting "group by" option' do
    visit work_packages_path(project:)

    # Activate group by option
    group_by.enable

    # Expect table to be grouped into 1 group
    group_by.expect_number_of_groups 1
    group_by.expect_grouped_by_value '0%', 3
  end
end
