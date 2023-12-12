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

RSpec.describe Queries::WorkPackages::Filter::SubjectOrIdFilter do
  let(:value) { 'bogus' }
  let(:operator) { '**' }
  let(:subject) { 'Some subject' }
  let(:work_package) { create(:work_package, subject:) }
  let(:current_user) do
    create(:user, member_with_permissions: { work_package.project => %i[view_work_packages edit_work_packages] })
  end
  let(:query) { build_stubbed(:global_query, user: current_user) }
  let(:instance) do
    described_class.create!(name: :search, context: query, operator:, values: [value])
  end

  before do
    login_as current_user
  end

  it 'finds in subject' do
    instance.values = ['Some subject']
    expect(WorkPackage.eager_load(instance.includes).where(instance.where))
      .to contain_exactly(work_package)
  end

  it 'finds in ID' do
    instance.values = [work_package.id.to_s]
    expect(WorkPackage.eager_load(instance.includes).where(instance.where))
      .to contain_exactly(work_package)
  end
end
