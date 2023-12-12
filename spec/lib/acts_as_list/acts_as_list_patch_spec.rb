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

RSpec.describe 'Models acting as list (acts_as_list)' do
  it 'includes the patch' do
    expect(ActiveRecord::Acts::List::InstanceMethods.included_modules).to include(OpenProject::Patches::ActsAsList)
  end

  describe '#move_to=' do
    let(:includer) do
      class ActsAsListPatchIncluder
        include OpenProject::Patches::ActsAsList
      end

      ActsAsListPatchIncluder.new
    end

    it 'moves to top when wanting to move highest' do
      expect(includer).to receive :move_to_top

      includer.move_to = 'highest'
    end

    it 'moves to bottom when wanting to move lowest' do
      expect(includer).to receive :move_to_bottom

      includer.move_to = 'lowest'
    end

    it 'moves higher when wanting to move higher' do
      expect(includer).to receive :move_higher

      includer.move_to = 'higher'
    end

    it 'moves lower when wanting to move lower' do
      expect(includer).to receive :move_lower

      includer.move_to = 'lower'
    end
  end
end
