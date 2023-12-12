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

module MockCarrierwave
  extend self

  def apply
    Fog.mock!
    Fog.credentials = credentials

    CarrierWave::Configuration.configure_fog!(directory: bucket, credentials:)

    connection = Fog::Storage.new provider: credentials[:provider]
    connection.directories.create key: bucket
  end

  def bucket
    'test-bucket'
  end

  def credentials
    {
      provider: 'AWS',
      aws_access_key_id: 'someaccesskeyid',
      aws_secret_access_key: 'someprivateaccesskey',
      region: 'us-east-1'
    }
  end
end

MockCarrierwave.apply
