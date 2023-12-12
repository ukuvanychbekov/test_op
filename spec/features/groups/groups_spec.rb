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

RSpec.describe 'group memberships through groups page', :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  let!(:group) { create(:group, lastname: "Bob's Team") }

  let(:groups_page) { Pages::Groups.new }

  context 'as an admin' do
    before do
      allow(User).to receive(:current).and_return admin
    end

    it 'I can delete a group' do
      groups_page.visit!
      expect(groups_page).to have_group "Bob's Team"

      groups_page.delete_group! "Bob's Team"

      expect(page).to have_selector('.op-toast.-info', text: I18n.t(:notice_deletion_scheduled))
      expect(groups_page).to have_group "Bob's Team"

      perform_enqueued_jobs

      groups_page.visit!
      expect(groups_page).not_to have_group "Bob's Team"
    end
  end
end
