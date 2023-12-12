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

RSpec.describe Query::Results, 'Sorting of custom field floats' do
  let(:query_results) do
    Query::Results.new query
  end
  let(:user) do
    create(:user,
           firstname: 'user',
           lastname: '1',
           member_with_permissions: { project => [:view_work_packages] })
  end

  let(:type) { create(:type_standard, custom_fields: [custom_field]) }
  let(:project) do
    create(:project,
           types: [type],
           work_package_custom_fields: [custom_field])
  end
  let(:work_package_with_float) do
    create(:work_package,
           type:,
           project:,
           custom_values: { custom_field.id => "6.25" })
  end

  let(:work_package_without_float) do
    create(:work_package,
           type:,
           project:)
  end

  let(:custom_field) do
    create(:float_wp_custom_field, name: 'MyFloat')
  end

  let(:query) do
    build(:query,
          user:,
          show_hierarchies: false,
          project:).tap do |q|
      q.filters.clear
      q.sort_criteria = sort_criteria
    end
  end

  before do
    login_as(user)
    work_package_with_float
    work_package_without_float
  end

  describe 'sorting ASC by float cf' do
    let(:sort_criteria) { [[custom_field.column_name, 'asc']] }

    it 'returns the correctly sorted result' do
      expect(query_results.work_packages.pluck(:id))
        .to match [work_package_without_float, work_package_with_float].map(&:id)
    end
  end

  describe 'sorting DESC by float cf' do
    let(:sort_criteria) { [[custom_field.column_name, 'desc']] }

    it 'returns the correctly sorted result' do
      expect(query_results.work_packages.pluck(:id))
        .to match [work_package_with_float, work_package_without_float].map(&:id)
    end
  end
end
