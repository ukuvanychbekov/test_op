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

require 'rbconfig'
require 'support/pages/page'

module Pages
  class GitHubTab < Page
    attr_reader :work_package_id

    def initialize(work_package_id)
      super()
      @work_package_id = work_package_id
    end

    def path
      "/work_packages/#{work_package_id}/tabs/github"
    end

    def git_actions_menu_button
      find('.github-git-copy:not([disabled])', text: 'Git')
    end

    def git_actions_copy_branch_name_button
      find('.git-actions-menu .copy-button:not([disabled])', match: :first)
    end

    def paste_clipboard_content
      meta_key = osx? ? :command : :control
      page.send_keys(meta_key, 'v')
    end

    def expect_tab_not_present
      expect(page).not_to have_selector('.op-tab-row--link', text: 'GITHUB')
    end

    private

    def osx?
      RbConfig::CONFIG['host_os'].include?('darwin')
    end
  end
end
