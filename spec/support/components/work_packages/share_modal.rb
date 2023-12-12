# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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

require 'support/components/common/modal'
require 'support/components/autocompleter/ng_select_autocomplete_helpers'

module Components
  module WorkPackages
    class ShareModal < Components::Common::Modal
      include Components::Autocompleter::NgSelectAutocompleteHelpers

      attr_reader :work_package, :title

      def initialize(work_package)
        super()

        @work_package = work_package
        @title = I18n.t('js.work_packages.sharing.title')
      end

      def expect_open
        super

        expect_title(title)
        wait_for_network_idle(timeout: 10)
      end

      def select_shares(*principals)
        within shares_list do
          principals.each do |principal|
            check principal.name
          end
        end
      end

      def deselect_shares(*principals)
        within shares_list do
          principals.each do |principal|
            uncheck principal.name
          end
        end
      end

      def expect_not_selectable(*principals)
        principals.each do |principal|
          within user_row(principal) do
            expect(page).not_to have_field(principal.name)
          end
        end
      end

      def toggle_select_all
        within shares_header do
          if page.find_field('toggle_all').checked?
            uncheck 'toggle_all'
          else
            check 'toggle_all'
          end
        end
      end

      def expect_selected(*principals)
        within shares_list do
          principals.each do |principal|
            expect(page).to have_checked_field(principal.name)
          end
        end
      end

      def expect_deselected(*principals)
        within shares_list do
          principals.each do |principal|
            expect(page).to have_unchecked_field(principal.name)
          end
        end
      end

      def expect_selected_count_of(count)
        expect(shares_header)
          .to have_text("#{count} selected")
      end

      def expect_select_all_available
        expect(shares_header)
          .to have_field('toggle_all')
      end

      def expect_select_all_not_available
        expect(shares_header)
          .not_to have_field('toggle_all', wait: 0)
      end

      def expect_select_all_toggled
        within shares_header do
          expect(page).to have_checked_field('toggle_all')
        end
      end

      def expect_select_all_untoggled
        within shares_header do
          expect(page).to have_unchecked_field('toggle_all')
        end
      end

      def expect_bulk_actions_available
        within shares_header do
          expect(page).to have_button 'Remove'
          expect(page).to have_test_selector('op-share-wp-bulk-update-role')
        end
      end

      def expect_bulk_actions_not_available
        within shares_header do
          expect(page).not_to have_button('Remove', wait: 0)
          expect(page).not_to have_test_selector('op-share-wp-bulk-update-role', wait: 0)
        end
      end

      def bulk_remove
        within shares_header do
          click_button 'Remove'
        end
      end

      def bulk_update(role_name)
        within shares_header do
          find('[data-test-selector="op-share-wp-bulk-update-role"]').click

          find('.ActionListContent', text: role_name).click
        end
      end

      def expect_bulk_update_label(label_text)
        within shares_header do
          expect(page)
            .to have_css('[data-test-selector="op-share-wp-bulk-update-role"] .Button-label',
                         text: label_text)
          if label_text == 'Mixed'
            %w[View Comment Edit].each do |permission_name|
              within bulk_update_form(permission_name) do
                expect(page)
                  .to have_css(unchecked_permission, visible: :all)
              end
            end
          else
            within bulk_update_form(label_text) do
              expect(page)
                .to have_css(checked_permission, visible: :all)
            end
          end
        end
      end

      def bulk_update_form(permission_name)
        find("[data-test-selector='op-share-wp-bulk-update-role-permission-#{permission_name}']", visible: :all)
      end

      def checked_permission
        'button[type=submit][aria-checked=true]'
      end

      def unchecked_permission
        'button[type=submit][aria-checked="false"]'
      end

      def expect_blankslate
        within_modal do
          expect(page).to have_text(I18n.t('work_package.sharing.text_empty_state_description'))
        end
      end

      def expect_empty_search_blankslate
        within_modal do
          expect(page).to have_text(I18n.t('work_package.sharing.text_empty_search_description'))
        end
      end

      def invite_user(users, role_name)
        Array(users).each do |user|
          case user
          when String
            select_not_existing_user_option(user)
          when Principal
            select_existing_user(user)
          end
        end

        select_invite_role(role_name)

        within_modal do
          click_button 'Share'
        end
      end

      alias_method :invite_users, :invite_user
      alias_method :invite_group, :invite_user

      def search_user(search_string)
        search_autocomplete page.find('[data-test-selector="op-share-wp-invite-autocomplete"]'),
                            query: search_string,
                            results_selector: 'body'
      end

      def remove_user(user)
        within user_row(user) do
          click_button 'Remove'
        end
      end

      def select_invite_role(role_name)
        within modal_element.find('[data-test-selector="op-share-wp-invite-role"]') do
          # Open the ActionMenu
          click_button 'View'

          find('.ActionListContent', text: role_name).click
        end
      end

      def change_role(user, role_name)
        within user_row(user) do
          find('[data-test-selector="op-share-wp-update-role"]').click

          within '.ActionListWrap' do
            click_button role_name
          end
        end
      end

      def filter(filter_name, value)
        within(shares_header) do
          retry_block do
            # The button's text changes dynamically based on the currently selected option
            # Hence the spec's readability is hindered by using something like
            # `click_button filter_name.capitalize`
            find("[data-test-selector='op-share-wp-filter-#{filter_name}-button']").click

            # Open the ActionMenu
            find('.ActionListContent', text: value).click
          end
        end

        wait_for_network_idle # Ensures filtering is done
      end

      def close
        within_modal do
          click_button 'Close'
        end
      end

      def click_share
        within_modal do
          click_button 'Share'
        end
      end

      def expect_shared_with(user, role_name = nil, position: nil, editable: true)
        within_modal do
          within shares_list do
            expect(page).to have_list_item(text: user.name, position:)
            within(:list_item, text: user.name, position:) do
              if role_name
                expect(page).to have_button(role_name),
                                "Expected share with #{user.name.inspect} to have button #{role_name}."
              end
              unless editable
                expect(page).not_to have_button,
                                    "Expected share with #{user.name.inspect} not to be editable (expected no buttons)."
              end
            end
          end
        end
      end

      def expect_not_shared_with(*principals)
        within shares_list do
          principals.each do |principal|
            expect(page)
              .not_to have_text(principal.name)
          end
        end
      end

      def expect_shared_count_of(count)
        expect(shares_header)
          .to have_text(I18n.t('work_package.sharing.count', count:))
      end

      def expect_no_invite_option
        within_modal do
          expect(page)
            .to have_text(I18n.t('work_package.sharing.permissions.denied'))
        end
      end

      def resend_invite(user)
        within user_row(user) do
          click_button I18n.t("work_package.sharing.user_details.resend_invite")
        end
      end

      def expect_invite_resent(user)
        within user_row(user) do
          expect(page)
            .to have_text(I18n.t("work_package.sharing.user_details.invite_resent"))
        end
      end

      def user_row(user)
        within_modal do
          find(:list_item, text: user.name)
        end
      end

      def active_list
        modal_element
          .find('[data-test-selector="op-share-wp-active-list"]')
      end

      def shares_header
        active_list.find('[data-test-selector="op-share-wp-header"]')
      end

      def shares_counter
        shares_header.find('[data-test-selector="op-share-wp-active-count"]')
      end

      def shares_list
        find_by_id('op-share-wp-active-shares')
      end

      def select_existing_user(user)
        select_autocomplete page.find('[data-test-selector="op-share-wp-invite-autocomplete"]'),
                            query: user.firstname,
                            select_text: user.name,
                            results_selector: 'body'
      end

      def select_not_existing_user_option(email)
        select_autocomplete page.find('[data-test-selector="op-share-wp-invite-autocomplete"]'),
                            query: email,
                            select_text: "Send invite to\"#{email}\"",
                            results_selector: 'body'
      end

      def expect_upsale_banner
        within_modal do
          expect(page)
            .to have_text(I18n.t(:label_enterprise_addon))
        end
      end

      def expect_no_user_limit_warning
        within modal_element do
          expect(page)
            .not_to have_text(I18n.t('work_package.sharing.warning_user_limit_reached'), wait: 0)
        end
      end

      def expect_user_limit_warning
        within modal_element do
          expect(page)
            .to have_text(I18n.t('work_package.sharing.warning_user_limit_reached'))
        end
      end

      def expect_select_a_user_hint
        within modal_element do
          expect(page)
            .to have_text(I18n.t("work_package.sharing.warning_no_selected_user"))
        end
      end

      def expect_no_select_a_user_hint
        within modal_element do
          expect(page)
            .not_to have_text(I18n.t("work_package.sharing.warning_no_selected_user"), wait: 0)
        end
      end
    end
  end
end
