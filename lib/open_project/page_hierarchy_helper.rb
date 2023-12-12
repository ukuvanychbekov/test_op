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

module OpenProject
  module PageHierarchyHelper
    def render_page_hierarchy(pages, node = nil, options = {})
      return '' unless pages[node]

      content_tag :ul, class: "pages-hierarchy -with-hierarchy" do
        chunks = pages[node].map do |page|
          content_tag :li, class: '-hierarchy-expanded' do
            is_parent = pages[page.id]
            concat render_hierarchy_item(page, is_parent, options)
            concat render_page_hierarchy(pages, page.id, options) if is_parent
          end
        end
        chunks.join.html_safe
      end
    end

    private

    def render_hierarchy_item(page, is_parent, options = {})
      content_tag(:span, class: 'tree-menu--item', slug: page.slug) do
        concat link_to(page.title,
                       url_helpers.project_wiki_path(page.project, page),
                       title: hierarchy_item_title(options, page),
                       class: "tree-menu--title ellipsis #{'-parent-node' if is_parent}") do
        end
        if is_parent
          concat content_tag(:span,
                             hierarchy_span_content(is_parent),
                             class: 'tree-menu--hierarchy-span')
        end
      end
    end

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticRouter.new.url_helpers
    end

    def hierarchy_span_content(is_parent)
      if is_parent
        render_hierarchy_indicator_icons
      else
        render_leaf_indicator
      end
    end

    def hierarchy_item_title(options, page)
      if options[:timestamp] && page.updated_at
        ::I18n.t(:label_updated_time, value: distance_of_time_in_words(Time.now, page.updated_at))
      end
    end

    def render_leaf_indicator
      content_tag(:span, tabindex: 0, class: 'tree-menu--leaf-indicator') do
        content_tag(:span,
                    ::I18n.t(:label_hierarchy_leaf),
                    class: 'hidden-for-sighted')
      end
    end

    def render_hierarchy_indicator_icons
      icon_spans = []
      icon_spans << content_tag(:span,
                                '',
                                'aria-hidden': true,
                                class: 'tree-menu--hierarchy-indicator-icon')
      icon_spans << content_tag(:span,
                                ::I18n.t(:label_expanded_click_to_collapse),
                                class: 'tree-menu--hierarchy-indicator-expanded hidden-for-sighted')
      icon_spans << content_tag(:span,
                                ::I18n.t(:label_collapsed_click_to_show),
                                class: 'tree-menu--hierarchy-indicator-collapsed hidden-for-sighted')
      content_tag(
        :a,
        safe_join(icon_spans),
        tabindex: 0,
        role: 'button',
        class: 'tree-menu--hierarchy-indicator',
        data: {
          action: 'menus--subtree#toggle'
        }
      )
    end
  end
end
