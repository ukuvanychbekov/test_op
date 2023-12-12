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

RSpec.describe 'Projects', 'creation',
               :js,
               :with_cuprite do
  shared_let(:name_field) { FormFields::InputFormField.new :name }

  current_user { create(:admin) }

  shared_let(:project) { create(:project, name: 'Foo project', identifier: 'foo-project') }

  let(:projects_page) { Pages::Projects::Index.new }

  before do
    projects_page.visit!
  end

  context 'within the button on the global sidebar' do
    it 'can navigate to the create project page' do
      projects_page.navigate_to_new_project_page_from_global_sidebar

      expect(page).to have_current_path(new_project_path)
    end
  end

  context 'with the button on the toolbar items' do
    it 'can navigate to the create project page' do
      projects_page.navigate_to_new_project_page_from_toolbar_items

      expect(page).to have_current_path(new_project_path)
    end
  end

  it 'can create a project' do
    projects_page.navigate_to_new_project_page_from_toolbar_items

    name_field.set_value 'Foo bar'
    click_button 'Save'

    expect(page).to have_current_path /\/projects\/foo-bar\/?/
    expect(page).to have_content 'Foo bar'
  end

  it 'does not create a project with an already existing identifier' do
    projects_page.navigate_to_new_project_page_from_toolbar_items

    name_field.set_value 'Foo project'
    click_on 'Save'

    expect(page).to have_current_path /\/projects\/foo-project-1\/?/

    project = Project.last
    expect(project.identifier).to eq 'foo-project-1'
  end

  context 'with a multi-select custom field' do
    let!(:list_custom_field) { create(:list_project_custom_field, name: 'List CF', multi_value: true) }
    let(:list_field) { FormFields::SelectFormField.new list_custom_field }

    it 'can create a project' do
      projects_page.navigate_to_new_project_page_from_toolbar_items

      name_field.set_value 'Foo bar'

      find('.op-fieldset--toggle', text: 'ADVANCED SETTINGS').click

      list_field.select_option 'A', 'B'

      click_button 'Save'

      expect(page).to have_current_path /\/projects\/foo-bar\/?/
      expect(page).to have_content 'Foo bar'

      project = Project.last
      expect(project.name).to eq 'Foo bar'
      cvs = project.custom_value_for(list_custom_field)
      expect(cvs.count).to eq 2
      expect(cvs.map(&:typed_value)).to contain_exactly 'A', 'B'
    end
  end

  it 'hides the active field and the identifier' do
    visit new_project_path

    find('.op-fieldset--toggle', text: 'ADVANCED SETTINGS').click

    expect(page).not_to have_content 'Active'
    expect(page).not_to have_content 'Identifier'
  end

  context 'with optional and required custom fields' do
    let!(:optional_custom_field) do
      create(:custom_field, name: 'Optional Foo',
                            type: ProjectCustomField,
                            is_for_all: true)
    end
    let!(:required_custom_field) do
      create(:custom_field, name: 'Required Foo',
                            type: ProjectCustomField,
                            is_for_all: true,
                            is_required: true)
    end

    it 'separates optional and required custom fields for new' do
      visit new_project_path

      expect(page).to have_content 'Required Foo'

      click_on 'Advanced settings'

      within('.op-fieldset') do
        expect(page).to have_text 'Optional Foo'
        expect(page).not_to have_text 'Required Foo'
      end
    end
  end
end
