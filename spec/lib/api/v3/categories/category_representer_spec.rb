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

RSpec.describe API::V3::Categories::CategoryRepresenter do
  let(:category) { build_stubbed(:category) }
  let(:user) { build(:user) }
  let(:representer) { described_class.new(category, current_user: double('current_user')) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    shared_examples_for 'category has core values' do
      it { is_expected.to include_json('Category'.to_json).at_path('_type') }

      it { is_expected.to have_json_type(Object).at_path('_links') }

      it 'links to self' do
        expect(subject).to have_json_path('_links/self/href')
      end

      it 'displays its name as title in self' do
        expect(subject).to have_json_path('_links/self/title')
      end

      it 'links to its project' do
        expect(subject).to have_json_path('_links/project/href')
      end

      it 'displays its project title' do
        expect(subject).to have_json_path('_links/project/title')
      end

      it { is_expected.to have_json_path('id') }
      it { is_expected.to have_json_path('name') }
    end

    context 'default assignee not set' do
      it_behaves_like 'category has core values'

      it 'does not link to an assignee' do
        expect(subject).not_to have_json_path('_links/defaultAssignee')
      end
    end

    context 'default assignee set' do
      let(:category) do
        build_stubbed(:category, assigned_to: user)
      end

      it_behaves_like 'category has core values'

      it 'links to its default assignee' do
        expect(subject).to have_json_path('_links/defaultAssignee/href')
      end

      it 'displays the name of its default assignee' do
        expect(subject).to have_json_path('_links/defaultAssignee/title')
      end
    end

    describe 'caching' do
      it 'is based on the representer\'s cache_key' do
        expect(OpenProject::Cache)
          .to receive(:fetch)
          .with(representer.json_cache_key)
          .and_call_original

        representer.to_json
      end

      describe '#json_cache_key' do
        let(:assigned_to) { build_stubbed(:user) }
        let!(:former_cache_key) { representer.json_cache_key }

        before do
          category.assigned_to = assigned_to
        end

        it 'includes the name of the representer class' do
          expect(representer.json_cache_key)
            .to include('API', 'V3', 'Categories', 'CategoryRepresenter')
        end

        it 'changes when the locale changes' do
          I18n.with_locale(:fr) do
            expect(representer.json_cache_key)
              .not_to eql former_cache_key
          end
        end

        it 'changes when the category is updated' do
          category.updated_at = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end

        it 'changes when the category\'s project is updated' do
          category.project.updated_at = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end

        it 'changes when the category\'s assigned_to is updated' do
          category.assigned_to.updated_at = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end
    end
  end
end
