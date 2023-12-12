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
#
require_relative '../../spec_helper'

RSpec.describe Storages::ProjectStorages::RowComponent,
               type: :component do
  describe '#button_links' do
    context 'with non-automatic project storage' do
      it 'renders edit and delete buttons' do
        project_storage = build_stubbed(:project_storage)
        expect(project_storage).not_to be_project_folder_automatic

        table = instance_double(Storages::ProjectStorages::TableComponent, columns: [])
        component = described_class.new(row: project_storage, table:)

        render_inline(component)

        expect(page).not_to have_css('a.icon.icon-group')
        expect(page).to have_css('a.icon.icon-edit')
        expect(page).to have_css('a.icon.icon-delete')
      end
    end

    context 'with automatic project storage' do
      it 'renders members connection status, edit and delete buttons' do
        project_storage = build_stubbed(:project_storage, :as_automatically_managed)
        expect(project_storage).to be_project_folder_automatic

        table = instance_double(Storages::ProjectStorages::TableComponent, columns: [])
        component = described_class.new(row: project_storage, table:)

        render_inline(component)

        expect(page).to have_css('a.icon.icon-group')
        expect(page).to have_css('a.icon.icon-edit')
        expect(page).to have_css('a.icon.icon-delete')
      end
    end
  end
end
