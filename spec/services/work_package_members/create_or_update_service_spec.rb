# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# ++

require 'spec_helper'

RSpec.describe WorkPackageMembers::CreateOrUpdateService do
  let(:user) { build_stubbed(:user) }
  let(:role) { build_stubbed(:view_work_package_role) }
  let(:work_package) { build_stubbed(:work_package) }
  let(:instance) { described_class.new(user:) }

  let(:params) { { user_id: user, roles: [role], entity: work_package } }
  let(:service_result) { instance_double(ServiceResult) }

  subject(:service_call) { instance.call(**params) }

  before do
    allow(Member)
      .to receive(:find_by)
            .with(entity: work_package, principal: user)
            .and_return(existing_member)
  end

  context 'when the user has no work_package_member for that work package' do
    let(:create_instance) { instance_double(WorkPackageMembers::CreateService) }
    let(:existing_member) { nil }

    it 'calls the WorkPackageMembers::CreateService' do
      allow(WorkPackageMembers::CreateService).to receive(:new).and_return(create_instance)
      allow(create_instance).to receive(:call).and_return(service_result)

      service_call

      expect(create_instance)
        .to have_received(:call)
              .with(**params)
    end
  end

  context 'when the user already has a work_package_member for that work package' do
    let(:update_instance) { instance_double(WorkPackageMembers::UpdateService) }
    let(:existing_member) { build_stubbed(:work_package_member) }

    it 'calls the WorkPackageMembers::UpdateService' do
      allow(WorkPackageMembers::UpdateService).to receive(:new).and_return(update_instance)
      allow(update_instance).to receive(:call).and_return(service_result)

      service_call

      expect(update_instance)
        .to have_received(:call)
              .with(**params)
    end
  end
end
