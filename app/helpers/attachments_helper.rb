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

module AttachmentsHelper
  def to_utf8_for_attachments(str)
    forced_str = str.dup
    forced_str.force_encoding('UTF-8')
    return forced_str if forced_str.valid_encoding?

    str.encode('UTF-8', invalid: :replace, undef: :replace, replace: '') # better replace: '?'
  end

  ##
  # List attachments outside the edit form
  # allowing immediate removal or addition of attachments
  #
  # Within ckeditor-augmented-textarea-form, this attachment list is added automatically
  # when a resource is added.
  def list_attachments(resource, options = {})
    content_tag 'op-attachments',
                '',
                'data-resource': resource.to_json,
                'data-allow-uploading': false,
                'data-destroy-immediately': true,
                **options
  end
end
