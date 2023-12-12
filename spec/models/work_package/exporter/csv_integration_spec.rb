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

RSpec.describe WorkPackage::Exports::CSV, 'integration' do
  before do
    login_as current_user
  end

  let(:project) { create(:project) }

  let(:current_user) do
    create(:user,
           member_with_permissions: { project => %i(view_work_packages) })
  end
  let(:query) do
    Query.new_default.tap do |query|
      query.column_names = %i(subject assigned_to updated_at estimated_hours)
    end
  end
  let(:instance) do
    described_class.new(query)
  end

  ##
  # When Ruby tries to join the following work package's subject encoded in ISO-8859-1
  # and its description encoded in UTF-8 it will result in a CompatibilityError.
  # This would not happen if the description contained only letters covered by
  # ISO-8859-1. Since this can happen, though, it is more sensible to encode everything
  # in UTF-8 which gets rid of this problem altogether.
  let!(:work_package) do
    create(
      :work_package,
      subject: "Ruby encodes ß as '\\xDF' in ISO-8859-1.",
      description: "\u2022 requires unicode.",
      assigned_to: current_user,
      derived_estimated_hours: 15.0,
      project:
    )
  end

  it 'performs a successful export' do
    work_package.reload

    data = CSV.parse instance.export!.content

    expect(data.size).to eq(2)
    expect(data.last).to include(work_package.subject)
    expect(data.last).to include(work_package.description)
    expect(data.last).to include(current_user.name)
    expect(data.last).to include(work_package.updated_at.localtime.strftime("%m/%d/%Y %I:%M %p"))
    expect(data.last).to include('(15.0 h)')
  end
end
