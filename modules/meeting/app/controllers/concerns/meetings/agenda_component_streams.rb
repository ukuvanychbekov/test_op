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

module Meetings
  module AgendaComponentStreams
    extend ActiveSupport::Concern

    included do
      def update_header_component_via_turbo_stream(meeting: @meeting, state: :show)
        update_via_turbo_stream(
          component: Meetings::HeaderComponent.new(
            meeting:,
            state:
          )
        )
      end

      def update_sidebar_component_via_turbo_stream(meeting: @meeting)
        update_via_turbo_stream(
          component: Meetings::SidebarComponent.new(
            meeting:
          )
        )
      end

      def update_sidebar_details_component_via_turbo_stream(meeting: @meeting)
        update_via_turbo_stream(
          component: Meetings::Sidebar::DetailsComponent.new(
            meeting:
          )
        )
      end

      def update_sidebar_state_component_via_turbo_stream(meeting: @meeting)
        update_via_turbo_stream(
          component: Meetings::Sidebar::StateComponent.new(
            meeting:
          )
        )
      end

      def update_sidebar_details_form_component_via_turbo_stream(meeting: @meeting, status: :bad_request)
        update_via_turbo_stream(
          component: Meetings::Sidebar::DetailsFormComponent.new(
            meeting:
          ),
          status:
        )
      end

      def update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)
        update_via_turbo_stream(
          component: Meetings::Sidebar::ParticipantsComponent.new(
            meeting:
          )
        )
      end

      def update_sidebar_participants_form_component_via_turbo_stream(meeting: @meeting)
        update_via_turbo_stream(
          component: Meetings::Sidebar::ParticipantsFormComponent.new(
            meeting:
          ),
          status: :bad_request
        )
      end

      def update_show_items_via_turbo_stream(meeting: @meeting)
        agenda_items = meeting.agenda_items.with_includes_to_render
        first_and_last = [agenda_items.first, agenda_items.last]

        agenda_items.each do |meeting_agenda_item|
          update_via_turbo_stream(
            component: MeetingAgendaItems::ItemComponent::ShowComponent.new(meeting_agenda_item:, first_and_last:)
          )
        end
      end

      def update_new_component_via_turbo_stream(hidden: false, meeting_agenda_item: nil, meeting: @meeting, type: :simple)
        update_via_turbo_stream(
          component: MeetingAgendaItems::NewComponent.new(
            hidden:,
            meeting:,
            meeting_agenda_item:,
            type:
          )
        )
      end

      def update_new_button_via_turbo_stream(disabled: false, meeting_agenda_item: nil, meeting: @meeting)
        update_via_turbo_stream(
          component: MeetingAgendaItems::NewButtonComponent.new(
            disabled:,
            meeting:,
            meeting_agenda_item:
          )
        )
      end

      def update_list_via_turbo_stream(meeting: @meeting, form_hidden: true, form_type: :simple)
        # replace needs to be called in order to mount the drag and drop handlers again
        # update would not do that and drag and drop would stop working after the first update
        replace_via_turbo_stream(
          component: MeetingAgendaItems::ListComponent.new(
            meeting:,
            form_hidden:,
            form_type:
          )
        )
        # as the list is updated without displaying the form, the new button needs to be enabled again
        # the new button might be in a disabled state
        update_new_button_via_turbo_stream(disabled: false) if form_hidden == true
      end

      def update_item_via_turbo_stream(state: :show, meeting_agenda_item: @meeting_agenda_item, display_notes_input: nil)
        replace_via_turbo_stream(
          component: MeetingAgendaItems::ItemComponent.new(
            state:,
            meeting_agenda_item:,
            display_notes_input:
          )
        )
        update_show_items_via_turbo_stream
      end

      def add_item_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item, clear_slate: false)
        if clear_slate
          update_list_via_turbo_stream(form_hidden: false, form_type: @agenda_item_type)
        else
          add_before_via_turbo_stream(
            component: MeetingAgendaItems::ItemComponent.new(
              state: :show,
              meeting_agenda_item:
            ),
            target_component: MeetingAgendaItems::ListComponent.new(meeting: @meeting)
          )
          update_new_component_via_turbo_stream(hidden: false, type: @agenda_item_type)
          update_show_items_via_turbo_stream
        end
      end

      def remove_item_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item, clear_slate: false)
        if clear_slate
          update_list_via_turbo_stream
        else
          update_show_items_via_turbo_stream
          remove_via_turbo_stream(
            component: MeetingAgendaItems::ItemComponent.new(
              state: :show,
              meeting_agenda_item:,
              display_notes_input: nil
            )
          )
        end
      end

      def move_item_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item)
        # Note: The `remove_component` and the `component` are pointing to the same
        # component, but we still need to instantiate them separately, otherwise re-adding
        # of the item will render and empty component.
        remove_component = MeetingAgendaItems::ItemComponent.new(state: :show, meeting_agenda_item:)
        remove_via_turbo_stream(component: remove_component)

        component = MeetingAgendaItems::ItemComponent.new(state: :show, meeting_agenda_item:)
        target_component =
          if @meeting_agenda_item.lower_item
            MeetingAgendaItems::ItemComponent.new(
              state: :show,
              meeting_agenda_item: @meeting_agenda_item.lower_item
            )
          else
            MeetingAgendaItems::ListComponent.new(meeting: @meeting)
          end
        add_before_via_turbo_stream(component:, target_component:)
        update_show_items_via_turbo_stream
      end

      def render_base_error_in_flash_message_via_turbo_stream(errors)
        if errors[:base].present?
          render_error_flash_message_via_turbo_stream(message: errors[:base].to_sentence)
        end
      end

      def update_all_via_turbo_stream
        update_header_component_via_turbo_stream
        update_sidebar_component_via_turbo_stream
        update_new_button_via_turbo_stream
        update_list_via_turbo_stream
      end
    end
  end
end
