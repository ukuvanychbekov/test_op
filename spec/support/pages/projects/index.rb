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
  module Projects
    class Index < ::Pages::Page
      def path
        "/projects"
      end

      def expect_listed(*users)
        rows = page.all 'td.username'
        expect(rows.map(&:text)).to eq(users.map(&:login))
      end

      def expect_projects_listed(*projects, archived: false)
        within '#project-table' do
          projects.each do |project|
            displayed_name = if archived
                               "ARCHIVED #{project.name}"
                             else
                               project.name
                             end

            expect(page).to have_text(displayed_name)
          end
        end
      end

      def expect_projects_not_listed(*projects)
        within '#project-table' do
          projects.each do |project|
            expect(page).not_to have_text(project)
          end
        end
      end

      def set_sidebar_filter(filter_name)
        within '#main-menu' do
          click_link text: filter_name
        end
      end

      def expect_filters_container_toggled
        expect(page).to have_selector('form.project-filters')
      end

      def expect_filters_container_hidden
        expect(page).to have_selector('form.project-filters', visible: :hidden)
      end

      def expect_filter_set(filter_name)
        expect(page).to have_selector("li[filter-name='#{filter_name}']:not(.hidden)",
                                      visible: :hidden)
      end

      def filter_by_active(value)
        set_filter('active',
                   'Active',
                   'is',
                   [value])

        click_button 'Apply'
      end

      def filter_by_public(value)
        set_filter('public',
                   'Public',
                   'is',
                   [value])

        click_button 'Apply'
      end

      def filter_by_membership(value)
        set_filter('member_of',
                   'I am member',
                   'is',
                   [value])

        click_button 'Apply'
      end

      def set_filter(name, human_name, human_operator = nil, values = [])
        select human_name, from: 'add_filter_select'
        selected_filter = page.find("li[filter-name='#{name}']")

        select(human_operator, from: 'operator') unless boolean_filter?(name)

        within(selected_filter) do
          return unless values.any?

          if name == 'name_and_identifier'
            set_name_and_identifier_filter(values)
          elsif boolean_filter?(name)
            set_toggle_filter(values)
          elsif name == 'created_at'
            select(human_operator, from: 'operator')
            set_created_at_filter(human_operator, values)
          elsif /cf_\d+/.match?(name)
            select(human_operator, from: 'operator')
            set_custom_field_filter(selected_filter, human_operator, values)
          end
        end
      end

      def set_toggle_filter(values)
        should_active = values.first == 'yes'
        is_active = page.has_selector? '[data-test-selector="spot-switch-handle"][data-qa-active]'

        if should_active != is_active
          page.find('[data-test-selector="spot-switch-handle"]').click
        end

        if should_active
          expect(page).to have_selector('[data-test-selector="spot-switch-handle"][data-qa-active]')
        else
          expect(page).to have_selector('[data-test-selector="spot-switch-handle"]:not([data-qa-active])')
        end
      end

      def set_name_and_identifier_filter(values)
        fill_in 'value', with: values.first
      end

      def set_created_at_filter(human_operator, values)
        case human_operator
        when 'on', 'less than days ago', 'more than days ago', 'days ago'
          fill_in 'value', with: values.first
        when 'between'
          fill_in 'from_value', with: values.first
          fill_in 'to_value', with: values.second
        end
      end

      def set_custom_field_filter(selected_filter, human_operator, values)
        if selected_filter[:'filter-type'] == 'list_optional'
          if values.size == 1
            value_select = find('.single-select select[name="value"]')
            value_select.select values.first
          end
        elsif selected_filter[:'filter-type'] == 'date'
          if human_operator == 'on'
            fill_in 'value', with: values.first
          end
        end
      end

      def open_filters
        retry_block do
          click_button('Show/hide filters')
          page.find_field('Add filter', visible: true)
        end
      end

      def click_more_menu_item(item)
        page.find('[data-test-selector="project-more-dropdown-menu"]').click
        page.within('.menu-drop-down-container') do
          click_link(item)
        end
      end

      def click_menu_item_of(title, project)
        activate_menu_of(project) do
          click_link title
        end
      end

      def activate_menu_of(project)
        within_row(project) do |row|
          row.hover
          menu = find('ul.project-actions')
          menu.click
          wait_for_network_idle if using_cuprite?
          expect(page).to have_selector('.menu-drop-down-container')
          yield menu
        end
      end

      def navigate_to_new_project_page_from_global_sidebar
        within '#main-menu' do
          click_on 'New project'
        end
      end

      def navigate_to_new_project_page_from_toolbar_items
        within '.toolbar-items' do
          click_on 'New project'
        end
      end

      private

      def boolean_filter?(filter)
        %w[active member_of public templated].include?(filter.to_s)
      end

      def within_row(project)
        row = page.find('#project-table tr', text: project.name)

        within row do
          yield row
        end
      end
    end
  end
end
