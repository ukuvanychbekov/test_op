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

RSpec.describe 'Selecting cards in the card view (regression #31962)', js: true do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:cards) { Pages::WorkPackageCards.new(project) }
  let(:display_representation) { Components::WorkPackages::DisplayRepresentation.new }
  let!(:work_package1) { create(:work_package, project:) }
  let!(:work_package2) { create(:work_package, project:) }
  let!(:work_package3) { create(:work_package, project:) }

  before do
    work_package1
    work_package2
    work_package3

    login_as(user)
    wp_table.visit!
    display_representation.switch_to_card_layout
    cards.expect_work_package_listed work_package1, work_package2, work_package3
  end

  describe 'selecting cards' do
    it 'can select and deselect all cards' do
      # Select all
      cards.select_all_work_packages
      cards.expect_work_package_selected work_package1, true
      cards.expect_work_package_selected work_package2, true
      cards.expect_work_package_selected work_package3, true

      # Deselect all
      cards.deselect_all_work_packages
      cards.expect_work_package_selected work_package1, false
      cards.expect_work_package_selected work_package2, false
      cards.expect_work_package_selected work_package3, false
    end

    it 'can select and deselect single cards' do
      # Select a card
      cards.select_work_package work_package1
      cards.expect_work_package_selected work_package1, true
      cards.expect_work_package_selected work_package2, false
      cards.expect_work_package_selected work_package3, false

      # Selecting another card changes the selection
      cards.select_work_package work_package2
      cards.expect_work_package_selected work_package1, false
      cards.expect_work_package_selected work_package2, true
      cards.expect_work_package_selected work_package3, false

      # Deselect a card
      cards.deselect_work_package work_package2
      cards.expect_work_package_selected work_package1, false
      cards.expect_work_package_selected work_package2, false
      cards.expect_work_package_selected work_package3, false
    end

    it 'can select and deselect range of cards' do
      # Select the first WP
      cards.select_work_package work_package1
      cards.expect_work_package_selected work_package1, true
      cards.expect_work_package_selected work_package2, false
      cards.expect_work_package_selected work_package3, false

      # Select the third with Shift results in all WPs being selected
      cards.select_work_package_with_shift work_package3
      cards.expect_work_package_selected work_package1, true
      cards.expect_work_package_selected work_package2, true
      cards.expect_work_package_selected work_package3, true

      # The range can be changed
      cards.select_work_package_with_shift work_package2
      cards.expect_work_package_selected work_package1, true
      cards.expect_work_package_selected work_package2, true
      cards.expect_work_package_selected work_package3, false
    end
  end
end
