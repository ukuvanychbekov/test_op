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
  module Utilities
    module Endpoints
      class Modify < Bodied
        def default_instance_generator(model)
          ->(_params, _current_user) do
            instance_variable_get("@#{model.name.demodulize.underscore}")
          end
        end

        private

        def present_success(_request, _call)
          raise NotImplementedError
        end

        def present_error(call)
          api_errors = [::API::Errors::ErrorBase.create_and_merge_errors(postprocess_errors(call))]

          fail(::API::Errors::MultipleErrors
                 .create_if_many(api_errors))
        end

        def postprocess_errors(call)
          errors = call.errors
          errors = merge_dependent_errors call if errors.empty?
          errors
        end

        def merge_dependent_errors(call)
          errors = ActiveModel::Errors.new call.all_results.first

          call.dependent_results.each do |dr|
            dr.errors.full_messages.each do |full_message|
              errors.add :base, :dependent_invalid, message: dependent_error_message(dr.result, full_message)
            end
          end

          errors
        end

        def dependent_error_message(result, full_message)
          key =
            if result.id.blank?
              :error_in_new_dependent
            else
              :error_in_dependent
            end

          I18n.t(
            key,
            dependent_class: result.model_name.human,
            related_id: result.id,
            # TODO: Make it more robust, as not every model has a 'name' attribute (e.g. fall back to collection index?)
            related_subject: result.name,
            error: full_message
          )
        end

        def deduce_process_service
          lookup_namespaced_class("#{update_or_create}Service")
        end

        def deduce_process_contract
          nil
        end
      end
    end
  end
end
