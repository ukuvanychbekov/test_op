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

class AddForeignKeysToCustomFieldsProjects < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      DELETE FROM custom_fields_projects
        WHERE custom_field_id NOT IN (SELECT id FROM custom_fields) OR
              project_id NOT IN (SELECT id FROM projects)
    SQL
    add_foreign_key :custom_fields_projects, :custom_fields, on_delete: :cascade, on_update: :cascade
    add_foreign_key :custom_fields_projects, :projects, on_delete: :cascade, on_update: :cascade
  end

  def down
    remove_foreign_key :custom_fields_projects, :custom_fields
    remove_foreign_key :custom_fields_projects, :projects
  end
end
