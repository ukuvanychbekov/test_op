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

RSpec.describe API::V3::WorkPackageCollectionFromQueryService,
               type: :model do
  include API::V3::Utilities::PathHelper

  let(:query) do
    build_stubbed(:query).tap do |query|
      allow(query)
        .to receive(:results)
        .and_return(results)

      allow(query)
        .to receive(:manually_sorted?)
        .and_return(query_manually_sorted)
    end
  end
  let(:query_manually_sorted) { false }

  let(:results) do
    results = double('results')

    allow(results)
      .to receive(:work_packages)
      .and_return([work_package])

    allow(results)
      .to receive(:all_total_sums)
      .and_return(OpenStruct.new(name: :estimated_hours) => 0.0)

    allow(results)
      .to receive(:work_package_count_by_group)
      .and_return(1 => 5, 2 => 10)

    allow(results)
      .to receive(:all_group_sums)
      .and_return(1 => { OpenStruct.new(name: :status_id) => 50 },
                  2 => { OpenStruct.new(name: :status_id) => 100 })

    allow(results)
      .to receive(:query)
      .and_return(double('query'))

    results
  end

  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:mock_wp_representer) do
    Struct.new(:work_packages,
               :self_link,
               :query_params,
               :project,
               :groups,
               :total_sums,
               :page,
               :per_page,
               :embed_schemas,
               :current_user,
               :timestamps,
               :query) do
      def initialize(work_packages,
                     self_link:,
                     query_params:,
                     project:,
                     groups:,
                     total_sums:,
                     page:,
                     per_page:,
                     embed_schemas:,
                     current_user:,
                     timestamps:,
                     query:)
        super(work_packages,
              self_link,
              query_params,
              project,
              groups,
              total_sums,
              page,
              per_page,
              embed_schemas,
              current_user,
              timestamps,
              query)
      end
    end
  end

  let(:mock_aggregation_representer) do
    Struct.new(:group,
               :count,
               :query,
               :sums,
               :current_user) do
      def initialize(group,
                     count,
                     query:,
                     sums:,
                     current_user:)
        super(group,
              count,
              query,
              sums,
              current_user)
      end
    end
  end

  let(:params) { {} }

  let(:mock_update_query_service) do
    mock = double('UpdateQueryFromV3ParamsService')

    allow(mock)
      .to receive(:call)
      .with(params, valid_subset: false)
      .and_return(mock_update_query_service_response)

    mock
  end

  let(:mock_update_query_service_response) do
    ServiceResult.new(success: update_query_service_success,
                      errors: update_query_service_errors,
                      result: update_query_service_result)
  end

  let(:update_query_service_success) { true }
  let(:update_query_service_errors) { nil }
  let(:update_query_service_result) { query }

  let(:work_package) { build_stubbed(:work_package) }

  let(:instance) { described_class.new(query, user) }

  describe '#call' do
    subject { instance.call(params) }

    before do
      stub_const('::API::V3::WorkPackages::WorkPackageCollectionRepresenter', mock_wp_representer)
      stub_const('::API::V3::WorkPackages::WorkPackageAggregationGroup', mock_aggregation_representer)

      allow(API::V3::UpdateQueryFromV3ParamsService)
        .to receive(:new)
        .with(query, user)
        .and_return(mock_update_query_service)
    end

    it 'is successful' do
      expect(subject).to be_success
    end

    context 'result' do
      subject { instance.call(params).result }

      it 'is a WorkPackageCollectionRepresenter' do
        expect(subject)
          .to be_a(API::V3::WorkPackages::WorkPackageCollectionRepresenter)
      end

      context 'work_packages' do
        it "has the query's work_package results set" do
          expect(subject.work_packages)
            .to contain_exactly(work_package)
        end
      end

      context 'current_user' do
        it 'has the provided user set' do
          expect(subject.current_user)
            .to eq(user)
        end
      end

      context 'project' do
        it 'has the queries project set' do
          expect(subject.project)
            .to eq(query.project)
        end
      end

      context 'self_link' do
        context 'if the project is nil' do
          let(:query) { build_stubbed(:query, project: nil) }

          it 'is the global work_package link' do
            expect(subject.self_link)
              .to eq(api_v3_paths.work_packages)
          end
        end

        context 'if the project is set' do
          let(:query) { build_stubbed(:query, project:) }

          it 'is the global work_package link' do
            expect(subject.self_link)
              .to eq(api_v3_paths.work_packages_by_project(project.id))
          end
        end
      end

      context 'embed_schemas' do
        it 'is true' do
          expect(subject.embed_schemas)
            .to be_truthy
        end
      end

      context 'when timestamps are given' do
        let(:timestamps) { [Timestamp.parse("P-1Y"), Timestamp.parse("oneWeekAgo@12:00+00:00"), Timestamp.now] }
        let(:query) { build_stubbed(:query, timestamps:) }

        it 'has the query timestamps' do
          expect(subject.timestamps)
            .to match_array(timestamps)
        end
      end

      context 'when a _query object is given' do
        it 'has the query' do
          expect(subject.query)
            .to eq(query)
        end
      end

      context 'total_sums' do
        context 'with query.display_sums? being false' do
          it 'is nil' do
            query.display_sums = false

            expect(subject.total_sums)
              .to be_nil
          end
        end

        context 'with query.display_sums? being true' do
          it 'has a struct containing the sums and the available custom fields' do
            query.display_sums = true

            custom_fields = [build_stubbed(:text_wp_custom_field),
                             build_stubbed(:integer_wp_custom_field)]

            allow(WorkPackageCustomField)
              .to receive(:summable)
              .and_return(custom_fields)

            expected = API::ParserStruct.new(estimated_hours: 0.0, available_custom_fields: custom_fields)

            expect(subject.total_sums)
              .to eq(expected)
          end
        end
      end

      context 'groups' do
        context 'with query.grouped? being false' do
          it 'is nil' do
            query.group_by = nil

            expect(subject.groups)
              .to be_nil
          end
        end

        context 'with query.group_by being empty' do
          it 'is nil' do
            query.group_by = ''

            expect(subject.groups)
              .to be_nil
          end
        end

        context 'with query.grouped? being true' do
          it 'has the groups' do
            query.group_by = 'status'

            expect(subject.groups[0].group)
              .to eq(1)
            expect(subject.groups[0].count)
              .to eq(5)
            expect(subject.groups[1].group)
              .to eq(2)
            expect(subject.groups[1].count)
              .to eq(10)
          end
        end
      end

      context 'query (in the url)' do
        context 'when displaying sums' do
          it 'is represented' do
            query.display_sums = true

            expect(subject.query_params[:showSums])
              .to be(true)
          end
        end

        context 'when displaying hierarchies' do
          it 'is represented' do
            query.show_hierarchies = true

            expect(subject.query_params[:showHierarchies])
              .to be(true)
          end
        end

        context 'when grouping' do
          it 'is represented' do
            query.group_by = 'status_id'

            expect(subject.query_params[:groupBy])
              .to eq('status_id')
          end
        end

        context 'when sorting' do
          it 'is represented' do
            query.sort_criteria = [['status_id', 'desc']]

            expected_sort = JSON::dump [['status', 'desc']]

            expect(subject.query_params[:sortBy])
              .to eq(expected_sort)
          end
        end

        context 'filters' do
          it 'is represented' do
            query.add_filter('status_id', '=', ['1', '2'])
            query.add_filter('subproject_id', '=', ['3', '4'])

            expected_filters = JSON::dump([
                                            { status: { operator: '=', values: ['1', '2'] } },
                                            { subprojectId: { operator: '=', values: ['3', '4'] } }
                                          ])

            expect(subject.query_params[:filters])
              .to eq(expected_filters)
          end

          it 'represents no filters' do
            expected_filters = JSON::dump([])

            expect(subject.query_params[:filters])
              .to eq(expected_filters)
          end
        end
      end

      context 'offset' do
        it 'is 1 as default' do
          expect(subject.query_params[:offset])
            .to be(1)
        end

        context 'with a provided value' do
          # It is imporant for the keys to be strings
          # as that is what will come from the client
          let(:params) { { 'offset' => 3 } }

          it 'is that value' do
            expect(subject.query_params[:offset])
              .to be(3)
          end
        end
      end

      context 'pageSize' do
        before do
          allow(Setting)
            .to receive(:per_page_options_array)
            .and_return([25, 50])
        end

        it 'is nil' do
          expect(subject.query_params[:pageSize])
            .to be(25)
        end

        context 'with a provided value' do
          # It is imporant for the keys to be strings
          # as that is what will come from the client
          let(:params) { { 'pageSize' => 100 } }

          it 'is that value' do
            expect(subject.query_params[:pageSize])
              .to be(100)
          end
        end

        context 'with the query sorted manually', with_settings: { forced_single_page_size: 42 } do
          let(:query_manually_sorted) { true }

          it 'is the setting value' do
            expect(subject.query_params[:pageSize])
              .to be(42)
          end

          context 'with a provided value' do
            let(:params) { { 'pageSize' => 100 } }

            it 'is the setting value' do
              expect(subject.query_params[:pageSize])
                .to be(42)
            end
          end

          context 'with a provided value of 0' do
            let(:params) { { 'pageSize' => 0 } }

            it 'is the provided value' do
              expect(subject.query_params[:pageSize])
                .to be(0)
            end
          end
        end
      end
    end

    context 'when the update query service fails' do
      let(:update_query_service_success) { false }
      let(:update_query_service_errors) { double('errors') }
      let(:update_query_service_result) { nil }

      it 'returns the update service response' do
        expect(subject)
          .to eql(mock_update_query_service_response)
      end
    end
  end
end
