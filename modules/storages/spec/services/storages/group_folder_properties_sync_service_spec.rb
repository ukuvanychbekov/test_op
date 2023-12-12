# frozen_string_literal: true

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
require_module_spec_helper

RSpec.describe Storages::GroupFolderPropertiesSyncService, :webmock do
  # rubocop:disable RSpec/IndexedLet
  let(:group_users_response_body) do
    <<~XML
      <?xml version="1.0"?>
      <ocs>
        <meta>
          <status>ok</status>
          <statuscode>100</statuscode>
          <message>OK</message>
          <totalitems></totalitems>
          <itemsperpage></itemsperpage>
        </meta>
        <data>
          <users>
            <element>Darth Maul</element>
            <element>OpenProject</element>
          </users>
        </data>
      </ocs>
    XML
  end
  let(:root_folder_set_permissions_request_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:nc="http://nextcloud.org/ns">
        <d:set>
          <d:prop>
            <nc:acl-list>
              <nc:acl>
                <nc:acl-mapping-type>group</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>1</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
            </nc:acl-list>
          </d:prop>
        </d:set>
      </d:propertyupdate>
    XML
  end
  let(:root_folder_set_permissions_response_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:propfind_request_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns" xmlns:nc="http://nextcloud.org/ns">
        <d:prop>
          <oc:fileid/>
        </d:prop>
      </d:propfind>
    XML
  end
  let(:root_folder_propfind_response_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>349</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Lost%20Jedi%20Project%20Folder%20%232/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>783</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Lost%20Jedi%20Project%20Folder%20%233/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>123</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/NOT%20ACTIVE%20PROJECT/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>778</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/PUBLIC%20PROJECT%20%28#{project_public.id}%29/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>999</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Project3%20%28#{project3.id}%29/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>2600003</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:created_folder_propfind_response_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/%5bSample%5d%20Project%20Name%20%7c%20Ehuu%20(#{project1.id})/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>819</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:add_user_to_group_response_body) do
    <<~XML
      <?xml version="1.0"?>
      <ocs>
      <meta>
        <status>ok</status>
        <statuscode>100</statuscode>
        <message>OK</message>
        <totalitems></totalitems>
        <itemsperpage></itemsperpage>
      </meta>
      <data/>
      </ocs>
    XML
  end
  let(:created_folder_set_permissions_request_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:nc="http://nextcloud.org/ns">
        <d:set>
          <d:prop>
            <nc:acl-list>
              <nc:acl>
                <nc:acl-mapping-type>group</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>0</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>Darth Vader</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>Obi-Wan</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>3</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>Yoda</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>3</nc:acl-permissions>
              </nc:acl>
            </nc:acl-list>
          </d:prop>
        </d:set>
      </d:propertyupdate>
    XML
  end
  let(:created_folder_set_permissions_response_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/%5bSample%5d%20Project%20Name%20%7c%20Ehuu(#{project1.id})</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:remove_user_from_group_response) do
    <<~XML
      <?xml version="1.0"?>
      <ocs>
      <meta>
        <status>ok</status>
        <statuscode>100</statuscode>
        <message>OK</message>
        <totalitems></totalitems>
        <itemsperpage></itemsperpage>
      </meta>
      <data/>
      </ocs>
    XML
  end
  let(:hide_folder_set_permissions_request_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:nc="http://nextcloud.org/ns">
        <d:set>
          <d:prop>
            <nc:acl-list>
              <nc:acl>
                <nc:acl-mapping-type>group</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>0</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
            </nc:acl-list>
          </d:prop>
        </d:set>
      </d:propertyupdate>
    XML
  end
  let(:hide_folder_set_permissions_response_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Lost%20Jedi%20Project%20Folder%20%232</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:set_permissions_request_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:nc="http://nextcloud.org/ns">
        <d:set>
          <d:prop>
            <nc:acl-list>
              <nc:acl>
                <nc:acl-mapping-type>group</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>0</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>Darth Vader</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>Obi-Wan</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>3</nc:acl-permissions>
              </nc:acl>
            </nc:acl-list>
          </d:prop>
        </d:set>
      </d:propertyupdate>
    XML
  end
  let(:set_permissions_response_body) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Jedi%20Project%20Folder%20%7C%7C%7C%28#{project2.id}%29</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:set_permissions_request_body5) do
    <<~XML
      <?xml version="1.0"?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:nc="http://nextcloud.org/ns">
        <d:set>
          <d:prop>
            <nc:acl-list>
              <nc:acl>
                <nc:acl-mapping-type>group</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>0</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
            </nc:acl-list>
          </d:prop>
        </d:set>
      </d:propertyupdate>
    XML
  end
  let(:set_permissions_response_body5) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/NOT%20ACTIVE%20PROJECT</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:set_permissions_request_body6) do
    <<~XML
      <?xml version="1.0"?>
      <d:propertyupdate xmlns:d="DAV:" xmlns:nc="http://nextcloud.org/ns">
        <d:set>
          <d:prop>
            <nc:acl-list>
              <nc:acl>
                <nc:acl-mapping-type>group</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>0</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>OpenProject</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>Darth Vader</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>31</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>Obi-Wan</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>1</nc:acl-permissions>
              </nc:acl>
              <nc:acl>
                <nc:acl-mapping-type>user</nc:acl-mapping-type>
                <nc:acl-mapping-id>Yoda</nc:acl-mapping-id>
                <nc:acl-mask>31</nc:acl-mask>
                <nc:acl-permissions>1</nc:acl-permissions>
              </nc:acl>
            </nc:acl-list>
          </d:prop>
        </d:set>
      </d:propertyupdate>
    XML
  end
  let(:set_permissions_response_body6) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/PUBLIC%20PROJECT%20%28#{project_public.id}%29/</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:set_permissions_response_body7) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Project3%20%28#{project3.id}%29/</d:href>
          <d:propstat>
            <d:prop>
              <nc:acl-list/>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end
  let(:propfind_response_body3) do
    <<~XML
      <?xml version="1.0"?>
      <d:multistatus
        xmlns:d="DAV:"
        xmlns:s="http://sabredav.org/ns"
        xmlns:oc="http://owncloud.org/ns"
        xmlns:nc="http://nextcloud.org/ns">
        <d:response>
          <d:href>/remote.php/dav/files/OpenProject/OpenProject/Project3%20%28#{project3.id}%29/</d:href>
          <d:propstat>
            <d:prop>
              <oc:fileid>2600003</oc:fileid>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end

  let(:request_stubs) { [] }

  let(:project1) do
    create(:project,
           name: '[Sample] Project Name / Ehuu',
           members: { multiple_projects_user => ordinary_role, single_project_user => ordinary_role })
  end
  let(:project2) do
    create(:project,
           name: 'Jedi Project Folder ///',
           members: { multiple_projects_user => ordinary_role })
  end
  let(:project3) do
    create(:project,
           name: 'Project3',
           members: { multiple_projects_user => ordinary_role })
  end
  let(:project_not_active) do
    create(:project,
           name: 'NOT ACTIVE PROJECT',
           active: false,
           members: { multiple_projects_user => ordinary_role })
  end
  let(:project_public) do
    create(:public_project,
           name: 'PUBLIC PROJECT',
           active: true)
  end

  let(:single_project_user) { create(:user) }
  let(:multiple_projects_user) { create(:user) }
  let!(:admin) { create(:admin) }

  let(:ordinary_role) { create(:project_role, permissions: %w[read_files write_files]) }
  let!(:non_member_role) { create(:non_member, permissions: %w[read_files]) }

  let(:storage) { create(:nextcloud_storage, :with_oauth_client, :as_automatically_managed, password: '12345678') }

  let!(:project_storage1) do
    create(:project_storage,
           project_folder_mode: 'automatic',
           project: project1,
           storage:)
  end
  let!(:project_storage2) do
    create(:project_storage,
           project_folder_mode: 'automatic',
           project: project2,
           storage:,
           project_folder_id: '123')
  end
  let!(:project_storage3) do
    create(:project_storage,
           project_folder_mode: 'automatic',
           project: project3,
           storage:,
           project_folder_id: nil)
  end
  let!(:project_storage4) do
    create(:project_storage,
           project_folder_mode: 'automatic',
           project: project_not_active,
           storage:,
           project_folder_id: '778')
  end
  let!(:project_storage5) do
    create(:project_storage,
           project_folder_mode: 'automatic',
           project: project_public,
           storage:,
           project_folder_id: '999')
  end

  let(:oauth_client) { storage.oauth_client }
  # rubocop:enable RSpec/IndexedLet

  describe '#call' do
    before do
      create(:oauth_client_token, origin_user_id: 'Obi-Wan', user: multiple_projects_user, oauth_client:)
      create(:oauth_client_token, origin_user_id: 'Yoda', user: single_project_user, oauth_client:)
      create(:oauth_client_token, origin_user_id: 'Darth Vader', user: admin, oauth_client:)

      setup_request_stubs
    end

    it 'sets project folders properties' do
      described_class.new(storage).call

      expect(project_storage1.reload.project_folder_id).to eq('819')
      expect(project_storage2.reload.project_folder_id).to eq('123')
      expect(project_storage3.reload.project_folder_id).to eq('2600003')

      expect(request_stubs).to all have_been_requested
    end

    describe 'error handling and flow control' do
      context 'when getting the root folder properties fail' do
        context 'on a handled error case' do
          before do
            request_stubs[0] = stub_request(:propfind, "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject")
                                 .with(
                                   body: propfind_request_body,
                                   headers: {
                                     'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                                     'Depth' => '1'
                                   }
                                 ).to_return(status: 404, body: "", headers: {})
          end

          it 'stops the flow immediately if the response is anything but a success' do
            described_class.new(storage).call

            request_stubs[1..].each { |request| expect(request).not_to have_been_requested }
          end

          it "logs an error message" do
            allow(OpenProject.logger).to receive(:warn)
            described_class.new(storage).call

            expect(OpenProject.logger).to have_received(:warn) do |msg, _|
              expect(parse_error_msg(msg))
                .to eq({ command: 'Storages::Peripherals::StorageInteraction::Nextcloud::Internal::PropfindQuery',
                         folder: 'OpenProject',
                         message: 'Outbound request destination not found',
                         data: { status: "404", body: '' } })
            end
          end

          it 'returns a failure' do
            result = described_class.new(storage).call
            expect(result).to be_failure
          end
        end

        it 'raises an error when dealing with an unhandled error case' do
          request_stubs[0] = stub_request(:propfind, "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject")
                               .with(
                                 body: propfind_request_body,
                                 headers: {
                                   'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                                   'Depth' => '1'
                                 }
                               ).to_return(status: 500, body: "", headers: {})

          expect(described_class.new(storage).call).to be_failure
        end
      end

      context 'when setting the root folder permissions fail' do
        context 'on a handled error case' do
          before do
            request_stubs[1] = stub_request(:proppatch, "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject")
                                 .with(
                                   body: root_folder_set_permissions_request_body,
                                   headers: { 'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=' }
                                 ).to_return(status: 401, body: 'Heute nicht', headers: {})
          end

          it 'interrupts the flow' do
            described_class.new(storage).call

            expect(request_stubs[0..1]).to all(have_been_requested)
            request_stubs[2..].each { |request| expect(request).not_to have_been_requested }
          end

          it 'logs an error message' do
            allow(OpenProject.logger).to receive(:warn)
            described_class.new(storage).call

            expect(OpenProject.logger).to have_received(:warn) do |msg, _|
              expect(parse_error_msg(msg))
                .to eq({ command: 'Storages::Peripherals::StorageInteraction::Nextcloud::SetPermissionsCommand',
                         folder: 'OpenProject',
                         message: 'Outbound request not authorized',
                         data: { status: '401', body: 'Heute nicht' } })
            end
          end
        end
      end

      context 'when folder creation fails' do
        before do
          request_stubs[2] = stub_request(
            :mkcol,
            "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
            "%5BSample%5D%20Project%20Name%20%7C%20Ehuu%20(#{project1.id})/"
          ).with(
            headers: {
              'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
            }
          ).to_return(status: 404, body: "", headers: {})
        end

        it 'continues normally ignoring that folder' do
          expect { described_class.new(storage).call }.not_to change(project_storage1, :project_folder_id)

          expect(request_stubs.delete_at(5)).not_to have_been_requested
          expect(request_stubs.delete_at(3)).not_to have_been_requested
          expect(request_stubs).to all(have_been_requested)
        end

        it 'logs the occurrence' do
          allow(OpenProject.logger).to receive(:warn)
          described_class.new(storage).call

          expect(OpenProject.logger).to have_received(:warn) do |msg|
            expect(parse_error_msg(msg))
              .to eq({ command: 'Storages::Peripherals::StorageInteraction::Nextcloud::CreateFolderCommand',
                       message: 'Outbound request destination not found',
                       folder: "OpenProject/[Sample] Project Name | Ehuu (#{project1.id})/",
                       data: { status: '404', body: '' } })
          end
        end
      end

      context 'when renaming a folder fail' do
        before do
          request_stubs[4] = stub_request(:move,
                                          "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
                                          "Lost%20Jedi%20Project%20Folder%20%233/")
                               .with(headers: {
                                       'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                                       'Destination' => "/remote.php/dav/files/OpenProject/OpenProject/" \
                                                        "Jedi%20Project%20Folder%20%7C%7C%7C%20%28#{project2.id}%29/"
                                     })
                               .to_return(status: 404, body: "", headers: {})
        end

        it 'we stop processing to avoid issues with permissions' do
          described_class.new(storage).call
          request_stubs[5..].each { |request| expect(request).not_to have_been_requested }
        end

        it 'logs the occurrence' do
          allow(OpenProject.logger).to receive(:warn)
          described_class.new(storage).call

          expect(OpenProject.logger).to have_received(:warn) do |msg, _|
            expect(parse_error_msg(msg))
              .to eq({ command: 'Storages::Peripherals::StorageInteraction::Nextcloud::RenameFileCommand',
                       message: 'Outbound request destination not found',
                       source: "OpenProject/Lost Jedi Project Folder #3/",
                       target: project_storage2.project_folder_path,
                       data: { status: '404', body: '' } })
          end
        end
      end

      context 'when hiding a folder fail' do
        before do
          request_stubs[6] = stub_request(:proppatch,
                                          "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
                                          "Lost%20Jedi%20Project%20Folder%20%232/")
                               .with(body: hide_folder_set_permissions_request_body,
                                     headers: {
                                       'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
                                     })
                               .to_return(status: 500, body: 'A server error occurred', headers: {})
        end

        it 'does not interrupt the flow' do
          described_class.new(storage).call

          expect(request_stubs).to all(have_been_requested)
        end

        it 'logs the occurrence' do
          allow(OpenProject.logger).to receive(:warn)
          described_class.new(storage).call

          expect(OpenProject.logger).to have_received(:warn) do |msg|
            expect(parse_error_msg(msg))
              .to eq({ command: 'Storages::Peripherals::StorageInteraction::Nextcloud::SetPermissionsCommand',
                       context: 'hide_folder',
                       folder: 'OpenProject/Lost Jedi Project Folder #2/',
                       message: 'Outbound request failed',
                       data: { status: '500', body: 'A server error occurred' } })
          end
        end
      end

      context 'when setting project folder permissions fail' do
        before do
          request_stubs[8] = stub_request(:proppatch,
                                          "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
                                          "Jedi%20Project%20Folder%20%7C%7C%7C%20%28#{project2.id}%29/")
                               .with(body: set_permissions_request_body,
                                     headers: { 'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=' })
                               .to_return(status: 500,
                                          body: 'Divide by cucumber error. Please reinstall universe and reboot.',
                                          headers: {})
        end

        it 'does not interrupt the flow' do
          described_class.new(storage).call

          expect(request_stubs).to all(have_been_requested)
        end

        it 'logs the occurrence' do
          allow(OpenProject.logger).to receive(:warn)
          described_class.new(storage).call

          expect(OpenProject.logger).to have_received(:warn) do |msg|
            expect(parse_error_msg(msg))
              .to eq({ command: 'Storages::Peripherals::StorageInteraction::Nextcloud::SetPermissionsCommand',
                       folder: "OpenProject/Jedi Project Folder ||| (#{project2.id})/",
                       message: 'Outbound request failed',
                       data: { status: '500',
                               body: 'Divide by cucumber error. Please reinstall universe and reboot.' } })
          end
        end
      end

      context 'when adding a user to the group fails' do
        before do
          request_stubs[12] = stub_request(:post, "#{storage.host}/ocs/v1.php/cloud/users/Obi-Wan/groups")
                                .with(
                                  body: "groupid=OpenProject",
                                  headers: {
                                    'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                                    'Ocs-Apirequest' => 'true'
                                  }
                                ).to_return(status: 302, body: '', headers: {})
        end

        it 'does not interrupt te flow' do
          described_class.new(storage).call

          expect(request_stubs).to all have_been_requested
        end

        it 'logs the occurrence' do
          allow(OpenProject.logger).to receive(:warn)
          described_class.new(storage).call

          expect(OpenProject.logger).to have_received(:warn) do |msg|
            expect(parse_error_msg(msg))
              .to eq({ command: 'Storages::Peripherals::StorageInteraction::Nextcloud::AddUserToGroupCommand',
                       group: 'OpenProject',
                       user: 'Obi-Wan',
                       message: 'Outbound request failed',
                       data: { status: '302', body: '' } })
          end
        end
      end

      context 'when removing a user to the group fails' do
        let(:remove_user_from_group_response) do
          <<~XML
            <?xml version="1.0"?>
            <ocs>
                <meta>
                    <status>failure</status>
                    <statuscode>105</statuscode>
                    <message>Not viable to remove user from the last group you are SubAdmin of</message>
                </meta>
                <data/>
            </ocs>
          XML
        end

        it 'does not interrupt the flow' do
          described_class.new(storage).call

          expect(request_stubs).to all have_been_requested
        end

        it 'logs the occurrence and continues the flow' do
          allow(OpenProject.logger).to receive(:warn)
          described_class.new(storage).call

          expect(OpenProject.logger).to have_received(:warn) do |msg, _|
            expect(parse_error_msg(msg))
              .to eq({ command: 'Storages::Peripherals::StorageInteraction::Nextcloud::RemoveUserFromGroupCommand',
                       group: 'OpenProject',
                       user: 'Darth Maul',
                       message: "Failed to remove user Darth Maul from group OpenProject: " \
                                "Not viable to remove user from the last group you are SubAdmin of",
                       data: { status: '200', body: remove_user_from_group_response } })
          end
        end
      end
    end
  end

  private

  def setup_request_stubs
    # 0 - Root folder FileIds
    request_stubs << stub_request(:propfind, "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject")
                       .with(
                         body: propfind_request_body,
                         headers: {
                           'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                           'Depth' => '1'
                         }
                       ).to_return(status: 207, body: root_folder_propfind_response_body, headers: {})

    # 1 - Root folder SetPermissions
    request_stubs << stub_request(:proppatch, "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject")
                       .with(
                         body: root_folder_set_permissions_request_body,
                         headers: {
                           'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
                         }
                       ).to_return(status: 207, body: root_folder_set_permissions_response_body, headers: {})

    # 2 - OpenProject Project Folder Creation
    request_stubs << stub_request(
      :mkcol,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
      "%5BSample%5D%20Project%20Name%20%7C%20Ehuu%20(#{project1.id})/"
    ).with(
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
      }
    ).to_return(status: 201, body: "", headers: {})

    # 3 - OpenProject PropFind for folder ID
    request_stubs << stub_request(
      :propfind,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
      "%5BSample%5D%20Project%20Name%20%7C%20Ehuu%20(#{project1.id})/"
    ).with(
      body: propfind_request_body,
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
        'Depth' => '1'
      }
    ).to_return(status: 207, body: created_folder_propfind_response_body, headers: {})

    # 4 - Move/Rename Folder
    request_stubs << stub_request(
      :move,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
      "Lost%20Jedi%20Project%20Folder%20%233/"
    ).with(
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
        'Destination' => "/remote.php/dav/files/OpenProject/OpenProject/" \
                         "Jedi%20Project%20Folder%20%7C%7C%7C%20%28#{project2.id}%29/"
      }
    ).to_return(status: 201, body: "", headers: {})

    # 5 - Set Permissions for the Created Folder
    request_stubs << stub_request(
      :proppatch,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
      "%5BSample%5D%20Project%20Name%20%7C%20Ehuu%20(#{project1.id})/"
    ).with(
      body: created_folder_set_permissions_request_body,
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
      }
    ).to_return(status: 207, body: created_folder_set_permissions_response_body, headers: {})

    # 6 - Hide Unknown Inactive Folder
    request_stubs << stub_request(
      :proppatch,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
      "Lost%20Jedi%20Project%20Folder%20%232/"
    ).with(
      body: hide_folder_set_permissions_request_body,
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
      }
    ).to_return(status: 207, body: hide_folder_set_permissions_response_body, headers: {})

    # 7 - Hide Inactive Project Folder
    request_stubs << stub_request(
      :proppatch,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
      "NOT%20ACTIVE%20PROJECT/"
    ).with(
      body: set_permissions_request_body5,
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
      }
    ).to_return(status: 207, body: set_permissions_response_body5, headers: {})

    # 8 - Set folder Permissions
    request_stubs << stub_request(
      :proppatch,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
      "Jedi%20Project%20Folder%20%7C%7C%7C%20%28#{project2.id}%29/"
    ).with(
      body: set_permissions_request_body,
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
      }
    ).to_return(status: 207, body: set_permissions_response_body, headers: {})

    # 9 - Set public project folder permissions
    request_stubs << stub_request(
      :proppatch,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
      "PUBLIC%20PROJECT%20%28#{project_public.id}%29/"
    ).with(
      body: set_permissions_request_body6,
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
      }
    ).to_return(status: 207, body: set_permissions_response_body6, headers: {})

    request_stubs << stub_request(
      :proppatch,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/" \
      "Project3%20%28#{project3.id}%29/"
    ).with(
      body: set_permissions_request_body,
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
      }
    ).to_return(status: 207, body: set_permissions_response_body7, headers: {})

    # 11 - Get all user in the remote group
    request_stubs << stub_request(:get, "#{storage.host}/ocs/v1.php/cloud/groups/#{storage.group}")
                       .with(
                         headers: {
                           'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                           'OCS-APIRequest' => 'true'
                         }
                       ).to_return(status: 200, body: group_users_response_body, headers: {})

    # 12 - Add user to group
    request_stubs << stub_request(:post, "#{storage.host}/ocs/v1.php/cloud/users/Obi-Wan/groups")
                       .with(
                         body: "groupid=OpenProject",
                         headers: {
                           'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                           'Ocs-Apirequest' => 'true'
                         }
                       ).to_return(status: 200, body: add_user_to_group_response_body, headers: {})

    request_stubs << stub_request(:post, "#{storage.host}/ocs/v1.php/cloud/users/Yoda/groups")
                       .with(
                         body: "groupid=OpenProject",
                         headers: {
                           'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                           'Ocs-Apirequest' => 'true'
                         }
                       ).to_return(status: 200, body: add_user_to_group_response_body, headers: {})

    request_stubs << stub_request(:post, "#{storage.host}/ocs/v1.php/cloud/users/Darth%20Vader/groups")
                       .with(
                         body: "groupid=OpenProject",
                         headers: {
                           'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
                           'Ocs-Apirequest' => 'true'
                         }
                       ).to_return(status: 200, body: add_user_to_group_response_body, headers: {})

    # remove user from group
    request_stubs << stub_request(
      :delete,
      "#{storage.host}/ocs/v1.php/cloud/users/Darth%20Maul/groups?groupid=OpenProject"
    ).with(
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=',
        'Ocs-Apirequest' => 'true'
      }
    ).to_return(status: 200, body: remove_user_from_group_response, headers: {})

    # Create an already existing folder
    request_stubs << stub_request(
      :mkcol,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/Project3%20(#{project3.id})/"
    ).with(
      headers: {
        'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg='
      }
    ).to_return(status: 405, body: <<~XML, headers: {})
      <?xml version="1.0" encoding="utf-8"?>
      <d:error xmlns:d="DAV:" xmlns:s="http://sabredav.org/ns">
        <s:exception>Sabre\\DAV\\Exception\\MethodNotAllowed</s:exception>
        <s:message>The resource you tried to create already exists</s:message>
      </d:error>
    XML

    # Get the already existing folder id
    request_stubs << stub_request(
      :propfind,
      "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/Project3%20(#{project3.id})/"
    ).with(
      headers: { 'Authorization' => 'Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=' },
      body: propfind_request_body
    ).to_return(status: 200, body: propfind_response_body3, headers: {})
  end

  def parse_error_msg(msg)
    MultiJson.load(msg, symbolize_keys: true)
  end
end
