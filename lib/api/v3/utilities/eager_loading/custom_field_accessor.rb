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

module API
  module V3
    module Utilities
      module EagerLoading
        module CustomFieldAccessor
          extend ActiveSupport::Concern

          included do
            # Because of the ruby method lookup,
            # wrapping the object here and define the
            # available_custom_fields methods on the wrapper does not suffice.
            # We thus extend each object (e.g. work package).
            def initialize(object)
              super
              object.extend(CustomFieldAccessorPatch)
            end

            module CustomFieldAccessorPatch
              def available_custom_fields
                @available_custom_fields
              end

              def available_custom_fields=(fields)
                @available_custom_fields = fields
              end
            end
          end
        end
      end
    end
  end
end
