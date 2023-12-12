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
        class EagerLoadingWrapper < SimpleDelegator
          private_class_method :new

          ##
          # Workaround against warnings in flatten
          # delegator does not forward private method #to_ary
          def to_ary
            __getobj__.send(:to_ary)
          end

          def inspect
            __getobj__.inspect.gsub(/#<(.+)>/m, "#<#{self.class.name} \\1>")
          end

          class << self
            def wrap(objects)
              objects
                .map { |object| new(object) }
            end
          end
        end
      end
    end
  end
end
