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

RSpec.describe OpenProject::Acts::Watchable::Routes do
  let(:request) do
    Struct.new(:type, :id) do
      def path_parameters
        { object_id: id, object_type: type }
      end
    end.new(type, id)
  end

  describe 'matches?' do
    shared_examples_for 'watched model' do
      describe 'for a valid id string' do
        let(:id) { '1' }

        it 'is true' do
          expect(OpenProject::Acts::Watchable::Routes.matches?(request)).to be_truthy
        end
      end

      describe 'for an invalid id string' do
        let(:id) { 'schmu' }

        it 'is false' do
          expect(OpenProject::Acts::Watchable::Routes.matches?(request)).to be_falsey
        end
      end
    end

    ['work_packages', 'news', 'forums', 'messages', 'wikis', 'wiki_pages'].each do |type|
      describe "routing #{type} watches" do
        let(:type) { type }

        it_behaves_like 'watched model'
      end
    end

    describe 'for a non watched model' do
      let(:type) { 'schmu' }
      let(:id) { '4' }

      it 'is false' do
        expect(OpenProject::Acts::Watchable::Routes.matches?(request)).to be_falsey
      end
    end
  end
end
