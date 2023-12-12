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

RSpec.describe Queries::Users::UserQuery do
  let(:instance) { described_class.new }
  let(:base_scope) { User.user.order(id: :desc) }

  context 'without a filter' do
    describe '#results' do
      it 'is the same as getting all the users' do
        expect(instance.results.to_sql).to eql base_scope.to_sql
      end
    end
  end

  context 'with a name filter' do
    before do
      instance.where('name', '~', ['a user'])
    end

    describe '#results' do
      it 'is the same as handwriting the query' do
        expected = base_scope
                   .merge(User
                          .user
                          .where(["LOWER(CONCAT(users.firstname, CONCAT(' ', users.lastname))) LIKE ?",
                                  "%a user%"]))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe '#valid?' do
      it 'is true' do
        expect(instance).to be_valid
      end

      it 'is invalid if the filter is invalid' do
        instance.where('name', '=', [''])
        expect(instance).to be_invalid
      end
    end
  end

  context 'with a status filter' do
    before do
      instance.where('status', '=', ['active'])
    end

    describe '#results' do
      it 'is the same as handwriting the query' do
        expected = base_scope.merge(User.user.where("users.status IN (1)"))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe '#valid?' do
      it 'is true' do
        expect(instance).to be_valid
      end

      it 'is invalid if the filter is invalid' do
        instance.where('status', '=', [''])
        expect(instance).to be_invalid
      end
    end
  end

  context 'with a group filter' do
    let(:group_1) { build_stubbed(:group) }

    before do
      allow(Group)
        .to receive(:exists?)
        .and_return(true)

      allow(Group)
        .to receive(:all)
        .and_return([group_1])

      instance.where('group', '=', [group_1.id])
    end

    describe '#results' do
      it 'is the same as handwriting the query' do
        expected = base_scope
                     .merge(User
                              .user
                              .where(["users.id IN (#{User.in_group([group_1.id.to_s]).select(:id).to_sql})"]))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe '#valid?' do
      it 'is true' do
        expect(instance).to be_valid
      end

      it 'is invalid if the filter is invalid' do
        instance.where('group', '=', [''])
        expect(instance).to be_invalid
      end
    end
  end

  context 'with a non existent filter' do
    before do
      instance.where('not_supposed_to_exist', '=', ['bogus'])
    end

    describe '#results' do
      it 'returns a query not returning anything' do
        expected = User.where(Arel::Nodes::Equality.new(1, 0))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe 'valid?' do
      it 'is false' do
        expect(instance).to be_invalid
      end

      it 'returns the error on the filter' do
        instance.valid?

        expect(instance.errors[:filters]).to eql ["Not supposed to exist filter does not exist."]
      end
    end
  end

  context 'with an id sortation' do
    before do
      instance.order(id: :asc)
    end

    describe '#results' do
      it 'is the same as handwriting the query' do
        expected = User.user.merge(User.order(id: :asc))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context 'with a name sortation' do
    before do
      instance.order(name: :desc)
    end

    describe '#results', with_settings: { user_format: :firstname_lastname } do
      let(:order_sql) do
        <<~SQL
          CASE
          WHEN users.type = 'User' THEN LOWER(concat_ws(' ', users.firstname, users.lastname))
          WHEN users.type != 'User' THEN LOWER(users.lastname)
          END DESC
        SQL
      end

      it 'is the same as handwriting the query' do
        expected = User
            .user
            .order(Arel.sql(order_sql))
            .order(id: :desc)

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context 'with a group sortation' do
    before do
      instance.order(group: :desc)
    end

    describe '#results' do
      it 'is the same as handwriting the query' do
        expected = User.user.merge(User.joins(:groups).order("groups_users.lastname DESC")).order(id: :desc)

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context 'with a non existing sortation' do
    # this is a field protected from sortation
    before do
      instance.order(password: :desc)
    end

    describe '#results' do
      it 'returns a query not returning anything' do
        expected = User.where(Arel::Nodes::Equality.new(1, 0))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe 'valid?' do
      it 'is false' do
        expect(instance).to be_invalid
      end
    end
  end
end
