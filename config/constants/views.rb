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

module Constants
  module Views
    class << self
      def add(type,
              contract_strategy: nil)
        @registered ||= {}

        @registered[canonical_type(type)] = { contract_strategy: contract_strategy }
      end

      def registered_types
        registered.keys
      end

      def registered?(type)
        type && registered_types.include?(canonical_type(type))
      end

      def type(type)
        searched_type = canonical_type(type)

        registered_types.find { |registered_type| registered_type == searched_type }
      end

      def contract_strategy(type)
        if registered?(type)
          registered[canonical_type(type)][:contract_strategy]&.constantize
        end
      end

      attr_reader :registered

      private

      def canonical_type(type)
        type.to_s.camelize.to_sym
      end
    end
  end
end
