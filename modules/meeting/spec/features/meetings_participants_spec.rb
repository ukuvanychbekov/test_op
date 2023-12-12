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

require_relative '../support/pages/meetings/edit'

RSpec.describe 'Meetings participants' do
  let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  let!(:user) do
    create(:user,
           firstname: 'Current',
           member_with_permissions: { project => %i[view_meetings edit_meetings] })
  end
  let!(:viewer_user) do
    create(:user,
           firstname: 'Viewer',
           member_with_permissions: { project => %i[view_meetings] })
  end
  let!(:non_viewer_user) do
    create(:user,
           firstname: 'Nonviewer',
           member_with_permissions: { project => %i[] })
  end
  let(:edit_page) { Pages::Meetings::Edit.new(meeting) }
  let!(:meeting) { create(:meeting, project:, title: 'Awesome meeting!') }

  before do
    login_as(user)
  end

  it 'allows setting members to participants which are allowed to view the meeting' do
    edit_page.visit!

    edit_page.expect_available_participant(user)
    edit_page.expect_available_participant(viewer_user)

    edit_page.expect_not_available_participant(non_viewer_user)

    edit_page.invite(viewer_user)
    show_page = edit_page.click_save
    show_page.expect_toast(message: 'Successful update')

    show_page.expect_invited(viewer_user)

    show_page.click_edit

    edit_page.uninvite(viewer_user)
    show_page = edit_page.click_save
    show_page.expect_toast(message: 'Successful update')

    show_page.expect_uninvited(viewer_user)
  end

  context 'with an invalid user reference' do
    let(:show_page) { Pages::Meetings::Show.new(meeting) }
    let(:meeting_participant) { create(:meeting_participant, user: viewer_user, meeting:) }

    before do
      meeting_participant.update_column(:user_id, 12341234)
    end

    it 'still allows to view the meeting' do
      show_page.visit!

      show_page.expect_invited meeting.author
      show_page.expect_uninvited viewer_user
    end
  end
end
