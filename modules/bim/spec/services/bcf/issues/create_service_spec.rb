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
require 'services/base_services/behaves_like_create_service'

RSpec.describe Bim::Bcf::Issues::CreateService, type: :model do
  it_behaves_like 'BaseServices create service' do
    let(:model_class) { Bim::Bcf::Issue }
    let(:factory) { :bcf_issue }
    let(:work_package) { build_stubbed(:work_package) }
    let(:wp_call) { ServiceResult.success(result: work_package) }

    before do
      allow(instance)
        .to(receive(:create_work_package))
        .and_return(wp_call)
    end

    context 'when WP service call fails' do
      let(:wp_call) { ServiceResult.failure(result: work_package) }

      it 'returns with that call immediately' do
        expect(subject).to eq wp_call
      end
    end
  end
end
