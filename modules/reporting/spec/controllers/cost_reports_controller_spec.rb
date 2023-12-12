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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.describe CostReportsController do
  include OpenProject::Reporting::PluginSpecHelper

  let(:user) { build(:user) }
  let(:project) { build(:valid_project) }

  describe "GET show" do
    before do
      is_member project, user, [:view_cost_entries]
      allow(User).to receive(:current).and_return(user)
    end

    describe "WHEN providing invalid units
              WHEN having the view_cost_entries permission" do
      before do
        get :show, params: { id: 1, unit: -1 }
      end

      it "responds with a 404 error" do
        expect(response.code).to eql("404")
      end
    end
  end
end
