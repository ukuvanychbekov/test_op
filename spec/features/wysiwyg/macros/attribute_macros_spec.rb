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

RSpec.describe 'Wysiwyg attribute macros', js: true do
  shared_let(:admin) { create(:admin) }
  let(:user) { admin }
  let!(:project) { create(:project, identifier: 'some-project', enabled_module_names: %w[wiki work_package_tracking]) }
  let!(:work_package) { create(:work_package, subject: "Foo Bar", project:) }
  let(:editor) { Components::WysiwygEditor.new }

  let(:markdown) do
    <<~MD
      # My headline

      <table>
        <thead>
        <tr>
          <th>Label</th>
          <th>Value</th>
        </tr>
        </thead>
        <tbody>
        <tr>
          <td>workPackageLabel:"Foo Bar":subject</td>
          <td>workPackageValue:"Foo Bar":subject</td>
        </tr>
        <tr>
          <td>projectLabel:identifier</td>
          <td>projectValue:identifier</td>
        </tr>
        <tr>
          <td>invalid subject workPackageValue:"Invalid":subject</td>
          <td>invalid project projectValue:"does not exist":identifier</td>
        </tr>
        </tbody>
      </table>
    MD
  end

  before do
    login_as(user)
  end

  describe 'creating a wiki page' do
    before do
      visit project_wiki_path(project, :wiki)
    end

    it 'can add and save multiple code blocks (Regression #28350)' do
      editor.in_editor do |container,|
        editor.set_markdown markdown
        expect(container).to have_table
      end

      click_on 'Save'

      expect(page).to have_selector('.op-toast.-success')

      # Expect output widget
      within('#content') do
        expect(page).to have_selector('td', text: 'Subject')
        expect(page).to have_selector('td', text: 'Foo Bar')
        expect(page).to have_selector('td', text: 'Identifier')
        expect(page).to have_selector('td', text: 'some-project')

        expect(page).to have_selector('td', text: 'invalid subject Cannot expand macro: Requested resource could not be found')
        expect(page).to have_selector('td', text: 'invalid project Cannot expand macro: Requested resource could not be found')
      end

      # Edit page again
      click_on 'Edit'

      editor.in_editor do |container,|
        expect(container).to have_selector('tbody td', count: 6)
      end
    end

    context 'with a multi-select CF' do
      let!(:type) { create(:type, projects: [project]) }
      let!(:custom_field) do
        create(
          :list_wp_custom_field,
          name: "Ingredients",
          multi_value: true,
          types: [type],
          projects: [project],
          possible_values: %w[A B C D E F G H]
        )
      end

      let!(:work_package) do
        wp = build(:work_package, subject: "Foo Bar", project:, type:)

        wp.custom_field_values = {
          custom_field.id => %w[A B C D E F].map { |s| custom_field.custom_options.find { |co| co.value == s }.id }
        }

        wp.save!
        wp
      end

      it 'expands all custom values (Regression #45538)' do
        editor.in_editor do |container,|
          editor.set_markdown 'workPackageValue:"Foo Bar":Ingredients'
          expect(container).to have_text 'workPackageValue'
        end

        click_on 'Save'

        expect(page).to have_selector('.op-toast.-success')

        within('#content') do
          expect(page).to have_selector('.custom-option', count: 6)
        end
      end
    end
  end
end
