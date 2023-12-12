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

RSpec.describe 'admin/settings/authentication_settings/show' do
  context 'with password login enabled' do
    before do
      allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)
      render
    end

    it 'shows password settings' do
      expect(rendered).to have_text I18n.t('label_password_lost')
    end

    it 'shows automated user blocking options' do
      expect(rendered).to have_text I18n.t('settings.brute_force_prevention')
    end
  end

  context 'with password login disabled' do
    before do
      allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
      render
    end

    it 'does not show password settings' do
      expect(rendered).not_to have_text I18n.t('label_password_lost')
    end

    it 'does not show automated user blocking options' do
      expect(rendered).not_to have_text I18n.t('settings.brute_force_prevention')
    end
  end
end
