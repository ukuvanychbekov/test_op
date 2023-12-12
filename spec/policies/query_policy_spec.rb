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

RSpec.describe QueryPolicy, type: :controller do
  let(:user)    { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:query)   { build_stubbed(:query, project:, user:) }

  describe '#allowed?' do
    let(:subject) { described_class.new(user) }

    shared_examples 'viewing queries' do |global|
      context (global ? 'in global context' : 'in project context').to_s do
        let(:other_user) { build_stubbed(:user) }

        if global
          let(:project) { nil }
        end

        before do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :view_work_packages, project: global ? build_stubbed(:project) : project
          end
        end

        it 'is true if the query is public and another user views it' do
          query.public = true
          query.user = other_user
          expect(subject.allowed?(query, :show)).to be_truthy
        end

        context 'query belongs to a different user' do
          let(:query) do
            build_stubbed(:query,
                          project:,
                          user:,
                          public: false)
          end

          it 'is true if the query is private and the owner views it' do
            expect(subject.allowed?(query, :show)).to be_truthy
          end

          it 'is false if the query is private and another user views it' do
            query.user = other_user
            expect(subject.allowed?(query, :show)).to be_falsy
          end
        end
      end
    end

    shared_examples 'action on persisted' do |action, global|
      context "for #{action} #{global ? 'in global context' : 'in project context'}" do
        if global
          let(:project) { nil }
        end

        before do
          allow(query).to receive(:new_record?).and_return false
          allow(query).to receive(:persisted?).and_return true
        end

        it 'is false if the user has no permission in the project' do
          mock_permissions_for(user, &:forbid_everything)

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is false if the user has the save_query permission in the project AND the query is not persisted' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :save_queries, project: global ? build_stubbed(:project) : project
          end
          allow(query).to receive(:persisted?).and_return false

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is true if the user has the save_query permission in the project AND it is his query' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :save_queries, project: global ? build_stubbed(:project) : project
          end
          query.user = user

          expect(subject.allowed?(query, action)).to be_truthy
        end

        it 'is false if the user has the save_query permission in the project AND it is not his query' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :save_queries, project: global ? build_stubbed(:project) : project
          end
          query.user = build_stubbed(:user)

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is false if the user lacks the save_query permission in the project AND it is his query' do
          mock_permissions_for(user) do |mock|
            mock.forbid_everything
          end

          query.user = user

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is true if the user has the manage_public_query permission in the project ' +
           'AND it is anothers query ' +
           'AND the query is public' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :manage_public_queries, project: global ? build_stubbed(:project) : project
          end
          query.user = build_stubbed(:user)
          query.public = true

          expect(subject.allowed?(query, action)).to be_truthy
        end

        it 'is false if the user lacks the manage_public_query permission in the project ' +
           'AND it is anothers query ' +
           'AND the query is public' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :save_queries, project: global ? build_stubbed(:project) : project
          end
          query.user = build_stubbed(:user)
          query.public = true

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is false if the user has the manage_public_query permission in the project ' +
           'AND it is anothers query ' +
           'AND the query is not public' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :manage_public_queries, project: global ? build_stubbed(:project) : project
          end
          query.user = build_stubbed(:user)
          query.public = false

          expect(subject.allowed?(query, action)).to be_falsy
        end
      end
    end

    shared_examples 'action on unpersisted' do |action, global|
      context "for #{action} #{global ? 'in global context' : 'in project context'}" do
        if global
          let(:project) { nil }
        end

        before do
          allow(query).to receive(:new_record?).and_return true
          allow(query).to receive(:persisted?).and_return false
        end

        it 'is false if the user has no permission in the project' do
          mock_permissions_for(user) do |mock|
            mock.forbid_everything
          end

          expect(subject.allowed?(query, action)).to be_falsy
        end

        it 'is true if the user has the save_query permission in the project' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :save_queries, project: global ? build_stubbed(:project) : project
          end

          expect(subject.allowed?(query, action)).to be_truthy
        end

        it 'is false if the user has the save_query permission in the project ' +
           'AND the query is persisted' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :save_queries, project: global ? build_stubbed(:project) : project
          end

          allow(query).to receive(:new_record?).and_return false

          expect(subject.allowed?(query, action)).to be_falsy
        end
      end
    end

    shared_examples 'publicize' do |global|
      context (global ? 'in global context' : 'in project context').to_s do
        if global
          let(:project) { nil }
        end

        it 'is false if the user has no permission in the project' do
          mock_permissions_for(user) do |mock|
            mock.forbid_everything
          end

          expect(subject.allowed?(query, :publicize)).to be_falsy
        end

        it 'is true if the user has the manage_public_query permission in the project ' +
           'AND it is his query' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :manage_public_queries, project: global ? build_stubbed(:project) : project
          end

          expect(subject.allowed?(query, :publicize)).to be_truthy
        end

        it 'is false if the user has the manage_public_query permission in the project ' +
           'AND the query is not public ' +
           'AND it is not his query' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :manage_public_queries, project: global ? build_stubbed(:project) : project
          end
          query.user = build_stubbed(:user)
          query.public = false

          expect(subject.allowed?(query, :publicize)).to be_falsy
        end
      end
    end

    shared_examples 'depublicize' do |global|
      context (global ? 'in global context' : 'in project context').to_s do
        if global
          let(:project) { nil }
        end

        it 'is false if the user has no permission in the project' do
          mock_permissions_for(user) do |mock|
            mock.forbid_everything
          end

          expect(subject.allowed?(query, :depublicize)).to be_falsy
        end

        it 'is true if the user has the manage_public_query permission in the project ' +
           'AND the query belongs to another user' +
           'AND the query is public' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :manage_public_queries, project: global ? build_stubbed(:project) : project
          end

          query.user = build_stubbed(:user)
          query.public = true

          expect(subject.allowed?(query, :depublicize)).to be_truthy
        end

        it 'is false if the user has the manage_public_query permission in the project ' +
           'AND the query is not public' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :manage_public_queries, project: global ? build_stubbed(:project) : project
          end
          query.public = false

          expect(subject.allowed?(query, :depublicize)).to be_falsy
        end
      end
    end

    shared_examples 'star' do |global|
      context (global ? 'in global context' : 'in project context').to_s do
        if global
          let(:project) { nil }
        end

        it 'is false if the user has no permission in the project' do
          mock_permissions_for(user) do |mock|
            mock.forbid_everything
          end

          expect(subject.allowed?(query, :star)).to be_falsy
        end
      end
    end

    shared_examples 'update ordered_work_packages' do |global|
      context (global ? 'in global context' : 'in project context').to_s do
        if global
          let(:project) { nil }
        end

        it 'is false if the user has no permission in the project' do
          mock_permissions_for(user) do |mock|
            mock.forbid_everything
          end

          expect(subject.allowed?(query, :reorder_work_packages)).to be_falsy
        end

        it 'is true if the user has the edit_work_packages permission in the project AND it public' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :edit_work_packages, project: global ? build_stubbed(:project) : project
          end

          query.public = true
          expect(subject.allowed?(query, :reorder_work_packages)).to be_truthy
        end

        it 'is false if the user has the edit_work_packages permission in the project AND it is not his' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :edit_work_packages, project: global ? build_stubbed(:project) : project
          end

          query.user = build_stubbed(:user)
          query.public = false
          expect(subject.allowed?(query, :reorder_work_packages)).to be_falsey
        end

        it 'is true if the user has the save_queries permission in the project AND it is his query' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :save_queries, project: global ? build_stubbed(:project) : project
          end

          expect(subject.allowed?(query, :reorder_work_packages)).to be_truthy
        end

        it 'is true if the user has the manage_public_query permission in the project ' +
           'AND it is a public query' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :manage_public_queries, project: global ? build_stubbed(:project) : project
          end

          query.public = true
          expect(subject.allowed?(query, :reorder_work_packages)).to be_truthy
        end

        it 'is false if the user has the manage_public_query permission in the project ' +
           'AND the query is not public ' +
           'AND it is not his query' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :manage_public_queries, project: global ? build_stubbed(:project) : project
          end
          query.user = build_stubbed(:user)
          query.public = false

          expect(subject.allowed?(query, :reorder_work_packages)).to be_falsey
        end
      end
    end

    shared_examples 'share via ical' do |global|
      context (global ? 'in global context' : 'in project context').to_s do
        if global
          let(:project) { nil }
        end

        it 'is false if the user has no permission in the project' do
          mock_permissions_for(user) do |mock|
            mock.forbid_everything
          end

          expect(subject.allowed?(query, :share_via_ical)).to be_falsy
        end

        it 'is true if the user has permission in the project' do
          mock_permissions_for(user) do |mock|
            mock.allow_in_project :share_calendars, project: global ? build_stubbed(:project) : project
          end

          expect(subject.allowed?(query, :share_via_ical)).to be_truthy
        end
      end
    end

    it_behaves_like 'action on persisted', :update, global: true
    it_behaves_like 'action on persisted', :update, global: false
    it_behaves_like 'action on persisted', :destroy, global: true
    it_behaves_like 'action on persisted', :destroy, global: false
    it_behaves_like 'action on unpersisted', :create, global: true
    it_behaves_like 'action on unpersisted', :create, global: false
    it_behaves_like 'publicize', global: false
    it_behaves_like 'publicize', global: true
    it_behaves_like 'depublicize', global: false
    it_behaves_like 'depublicize', global: true
    it_behaves_like 'action on persisted', :star, global: false
    it_behaves_like 'action on persisted', :star, global: true
    it_behaves_like 'action on persisted', :unstar, global: false
    it_behaves_like 'action on persisted', :unstar, global: true
    it_behaves_like 'viewing queries', global: true
    it_behaves_like 'viewing queries', global: false
    # TODO: should this be better done in 'action on persisted' context?
    # I'm not sure if the action on persisted perrmission dependecies apply to the share via ical context
    it_behaves_like 'share via ical', global: true
    it_behaves_like 'share via ical', global: false
  end
end
