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

module Redmine::MenuManager::TopMenuHelper
  include Redmine::MenuManager::TopMenu::HelpMenu
  include Redmine::MenuManager::TopMenu::ProjectsMenu
  include Redmine::MenuManager::TopMenu::QuickAddMenu

  def render_top_menu_left
    content_tag :ul, class: 'op-app-menu op-app-menu_drop-left' do
      safe_join top_menu_left_menu_items
    end
  end

  def top_menu_left_menu_items
    [render_main_top_menu_nodes,
     render_projects_top_menu_node,
     render_quick_add_menu]
  end

  def render_top_menu_center
    content_tag :div, class: 'op-logo' do
      link_to(I18n.t('label_home'), configurable_home_url, class: 'op-logo--link')
    end
  end

  def render_top_menu_search
    content_tag :div, class: 'op-app-search' do
      render_global_search_input
    end
  end

  def render_global_search_input
    angular_component_tag 'opce-global-search',
                          inputs: {
                            placeholder: I18n.t('global_search.placeholder', app_title: Setting.app_title)
                          }
  end

  def render_top_menu_right
    capture do
      concat render_top_menu_search
      concat top_menu_right_node
    end
  end

  def top_menu_right_node
    content_tag(:ul, class: 'op-app-menu') do
      safe_join top_menu_right_menu_items
    end
  end

  def top_menu_right_menu_items
    [render_module_top_menu_node,
     render_notification_top_menu_node,
     render_help_top_menu_node,
     render_user_top_menu_node]
  end

  private

  def render_notification_top_menu_node
    return ''.html_safe unless User.current.logged?

    content_tag('li', class: 'op-app-menu--item', title: I18n.t('mail.notification.center')) do
      tag('op-in-app-notification-bell')
    end
  end

  def render_user_top_menu_node(items = first_level_menu_items_for(:account_menu))
    if User.current.logged?
      render_user_drop_down items
    elsif omniauth_direct_login?
      render_direct_login
    else
      render_login_drop_down
    end
  end

  def render_login_drop_down
    url = { controller: '/account', action: 'login' }
    link = link_to url,
                   class: 'op-app-menu--item-action',
                   title: I18n.t(:label_login) do
      concat content_tag(:span, I18n.t(:label_login), class: 'op-app-menu--item-title hidden-for-mobile')
      concat content_tag(:i, '', class: 'op-app-menu--item-dropdown-indicator button--dropdown-indicator hidden-for-mobile')
      concat content_tag(:i, '', class: 'icon2 icon-user hidden-for-desktop')
    end

    render_menu_dropdown(link, menu_item_class: '') do
      render_login_partial
    end
  end

  def render_direct_login
    link = link_to signin_path,
                   class: 'op-app-menu--item-action login',
                   title: I18n.t(:label_login) do
      concat content_tag(:span, I18n.t(:label_login), class: 'op-app-menu--item-title hidden-for-mobile')
      concat content_tag(:i, '', class: 'icon2 icon-user hidden-for-desktop')
    end

    content_tag :li, class: "" do
      concat link
    end
  end

  def render_user_drop_down(items)
    avatar = avatar(User.current, class: 'op-top-menu-user-avatar')
    render_menu_dropdown_with_items(
      label: avatar.presence || '',
      label_options: {
        title: User.current.name,
        class: 'op-top-menu-user',
        icon: (avatar.present? ? 'overridden-by-avatar' : 'icon-user')
      },
      items:,
      options: { drop_down_id: 'user-menu', menu_item_class: 'last-child' }
    )
  end

  def render_login_partial
    partial =
      if OpenProject::Configuration.disable_password_login?
        'account/omniauth_login'
      else
        'account/login'
      end

    render partial:
  end

  def render_module_top_menu_node(items = more_top_menu_items)
    unless items.empty?
      render_menu_dropdown_with_items(
        label: '',
        label_options: { icon: 'icon-menu', title: I18n.t('label_modules') },
        items:,
        options: { drop_down_id: 'more-menu', drop_down_class: 'drop-down--modules ', menu_item_class: 'hidden-for-mobile' }
      )
    end
  end

  def render_main_top_menu_nodes(items = main_top_menu_items)
    items.map do |item|
      render_menu_node(item)
    end.join(' ')
  end

  # Menu items for the main top menu
  def main_top_menu_items
    split_top_menu_into_main_or_more_menus[:base]
  end

  # Menu items for the modules top menu
  def more_top_menu_items
    split_top_menu_into_main_or_more_menus[:modules]
  end

  def project_menu_items
    split_top_menu_into_main_or_more_menus[:projects]
  end

  def help_menu_item
    split_top_menu_into_main_or_more_menus[:help]
  end

  # Split the :top_menu into separate :main and :modules items
  def split_top_menu_into_main_or_more_menus
    @top_menu_split ||= begin
      items = Hash.new { |h, k| h[k] = [] }
      first_level_menu_items_for(:top_menu) do |item|
        if item.name == :help
          items[:help] = item
        else
          context = item.context || :modules
          items[context] << item
        end
      end
      items
    end
  end
end
