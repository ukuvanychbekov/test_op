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

RSpec.describe Watcher do
  let(:project) { watchable.project }
  let(:user) { build(:user, admin: true) }
  let(:watcher) do
    build(:watcher,
          watchable:,
          user:)
  end
  let(:watchable) { build(:news) }
  let(:other_watcher) do
    build(:watcher,
          watchable:,
          user: other_user)
  end
  let(:other_project) { create(:project) }
  let(:other_user) { create(:user, admin: true) }
  let(:notification_settings) { [] }
  let(:saved_user) do
    create(:user,
           member_with_permissions: { saved_watchable.project => [] },
           notification_settings:)
  end
  let(:saved_watchable) { create(:news) }

  describe '#valid' do
    it 'is valid for an active user' do
      expect(watcher).to be_valid
    end

    it 'is valid for an invited user' do
      user.status = Principal.statuses[:invited]
      expect(watcher).to be_valid
    end

    it 'is valid for a registered user' do
      user.status = Principal.statuses[:registered]
      expect(watcher).to be_valid
    end
  end

  describe '.prune' do
    shared_examples_for 'a pruned watchable' do
      before do
        watcher.save!
        other_watcher.save!
        user.update_attribute(:admin, false)
        user.reload
      end

      context 'with a matching user scope' do
        it 'removes the watcher' do
          Watcher.prune(user:)

          expect(Watcher.find_by(id: watcher.id)).to be_nil
        end

        it 'leaves the other watcher' do
          Watcher.prune(user:)

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end

      context 'without a scope' do
        it 'removes the watcher' do
          Watcher.prune

          expect(Watcher.find_by(id: watcher.id)).to be_nil
        end

        it 'leaves the other watcher' do
          Watcher.prune

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end

      context 'with a non matching user scope' do
        let(:other_other_user) { create(:user) }

        it 'leaves the watcher' do
          Watcher.prune(user: other_other_user)

          expect(Watcher.find_by(id: watcher.id)).to eql watcher
        end

        it 'leaves the other watcher' do
          Watcher.prune(user: other_other_user)

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end

      context 'with a matching user and project_id scope' do
        it 'removes the watcher' do
          Watcher.prune(user:, project_id: project.id)

          expect(Watcher.find_by(id: watcher.id)).to be_nil
        end

        it 'leaves the other watcher' do
          Watcher.prune(user:, project_id: project.id)

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end

      context 'with a matching project_id scope' do
        it 'removes the watcher' do
          Watcher.prune(project_id: project.id)

          expect(Watcher.find_by(id: watcher.id)).to be_nil
        end

        it 'leaves the other watcher' do
          Watcher.prune(project_id: project.id)

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end

      context 'with a non matching project_id scope' do
        it 'leaves the watcher' do
          Watcher.prune(project_id: other_project.id)

          expect(Watcher.find_by(id: watcher.id)).to eql watcher
        end

        it 'leaves the other watcher' do
          Watcher.prune(project_id: other_project.id)

          expect(Watcher.find_by(id: other_watcher.id)).to eql other_watcher
        end
      end
    end

    shared_examples_for 'no watcher exists' do
      before do
        watchable.save!
      end

      it 'is robust' do
        expect { Watcher.prune }.not_to raise_error
      end
    end

    context 'for a work package' do
      it_behaves_like 'a pruned watchable'
      it_behaves_like 'no watcher exists'
    end

    context 'for a message' do
      let(:forum) { build(:forum) }
      let(:watchable) do
        forum.save!
        build(:message, forum:)
      end
      let(:project) { forum.project }

      it_behaves_like 'a pruned watchable'
      it_behaves_like 'no watcher exists'
    end
  end

  describe '#add_watcher' do
    it 'returns true when the watcher is added' do
      expect(saved_watchable.add_watcher(saved_user))
        .to be_truthy
    end

    it 'adds the user to watchers' do
      saved_watchable.add_watcher(saved_user)

      expect(saved_watchable.watchers.map(&:user))
        .to match_array(saved_user)
    end

    it 'will not add the same user when called twice' do
      saved_watchable.add_watcher(saved_user)
      saved_watchable.add_watcher(saved_user)

      expect(saved_watchable.watchers.map(&:user))
        .to match_array(saved_user)
    end
  end

  describe '#remove_watcher' do
    before do
      saved_watchable.watchers.create(user: saved_user)
    end

    it 'removes the watcher' do
      saved_watchable.remove_watcher(saved_user)

      expect(saved_watchable.watchers)
        .to be_empty
    end
  end

  describe '#watched_by' do
    context 'for a watcher user' do
      before do
        saved_watchable.watchers.create!(user: saved_user)
      end

      it 'is truthy' do
        expect(saved_watchable.watched_by?(saved_user))
          .to be_truthy
      end
    end

    context 'for a non watcher user' do
      it 'is falsey' do
        expect(saved_watchable.watched_by?(saved_user))
          .to be_falsey
      end
    end
  end

  describe '#watcher_user_ids' do
    it 'only adds unique users' do
      saved_watchable.watcher_user_ids = [saved_user.id, saved_user.id]
      expect(saved_watchable)
        .to be_valid
      expect(saved_watchable.watchers.map(&:user))
        .to match_array([saved_user])
    end
  end
end
