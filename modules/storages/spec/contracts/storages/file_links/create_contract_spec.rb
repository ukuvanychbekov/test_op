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
require_module_spec_helper
require_relative 'shared_contract_examples'

RSpec.describe Storages::FileLinks::CreateContract do
  it_behaves_like 'file_link contract' do
    let(:contract) { described_class.new(file_link, current_user) }

    context 'when creator is not the current user' do
      let(:file_link_creator) { build_stubbed(:user) }

      include_examples 'contract is invalid', creator: :invalid
    end

    context 'with one drive storage and missing ee token', with_ee: false do
      let(:storage) { create(:one_drive_storage) }

      include_examples 'contract is invalid', base: I18n.t('api_v3.errors.code_500_missing_enterprise_token')
    end

    context 'with one drive storage and valid ee token', with_ee: %i[one_drive_sharepoint_file_storage] do
      let(:storage) { create(:one_drive_storage) }

      include_examples 'contract is valid'
    end
  end
end
