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

require 'support/pages/page'

module Pages
  class WorkPackageCard < Page
    attr_reader :project, :work_package

    def initialize(work_package, project = nil)
      @work_package = work_package
      @project = project || work_package.project
    end

    def card_element
      page.find(card_selector)
    end

    def card_selector
      ".op-wp-single-card-#{work_package.id}"
    end

    def expect_selected(selected: true)
      expect(page).to have_conditional_selector(selected, "#{card_selector}[data-qa-selected='true']")
    end

    def expect_type(name)
      page.within(card_element) do
        expect(page).to have_selector('[data-test-selector="op-wp-single-card--content-type"]', text: name.upcase)
      end
    end

    def expect_subject(subject)
      page.within(card_element) do
        expect(page).to have_selector('[data-test-selector="op-wp-single-card--content-subject"]', text: subject)
      end
    end

    def open_details_view
      card_element.hover
      card_element.find('[data-test-selector="op-wp-single-card--details-button"]').click

      ::Pages::SplitWorkPackage.new work_package
    end
  end
end
