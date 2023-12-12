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
#

require 'spec_helper'

RSpec.describe 'Global menu item for boards', :js, :with_cuprite do
  let(:boards_label) { I18n.t('boards.label_boards') }

  before do
    login_as current_user
    visit root_path
  end

  context 'with permissions' do
    let(:current_user) { create(:admin) }

    it "sends the user to the boards overview when clicked" do
      within '#main-menu' do
        click_on boards_label
      end

      expect(page).to have_current_path(work_package_boards_path)
      expect(page).to have_content(boards_label)
      expect(page).to have_content(I18n.t(:no_results_title_text))
    end
  end

  context 'without permissions' do
    let(:current_user) { create(:user) }

    it 'is not rendered' do
      within '#main-menu' do
        expect(page).not_to have_content(boards_label)
      end
    end
  end
end
