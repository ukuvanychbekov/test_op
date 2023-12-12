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

module OpenProject::TextFormatting::Filters::Macros
  module ChildPages
    HTML_CLASS = 'child_pages'.freeze

    module_function

    def identifier
      HTML_CLASS
    end

    def apply(macro, context:, **_args)
      insert_child_pages(macro, context) if is?(macro)
    end

    def insert_child_pages(macro, pipeline_context)
      context = ChildPagesContext.new(macro, pipeline_context)
      context.check

      macro.replace(render_tree(context.include_parent, context.page))
    end

    def is?(macro)
      macro['class'].include?(HTML_CLASS)
    end

    def render_tree(include_parent, page)
      pages = ([page] + page.descendants).group_by(&:parent_id)
      ApplicationController.helpers.render_page_hierarchy(pages, include_parent ? page.parent_id : page.id)
    end
  end
end
