# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        module InputMethods
          def autocompleter(**, &)
            add_input AutocompleterInput.new(builder: @builder, form: @form, **, &)
          end

          def user_autocompleter(**, &)
            add_input UserAutocompleterInput.new(builder: @builder, form: @form, **, &)
          end

          def rich_text_area(**)
            add_input RichTextAreaInput.new(builder: @builder, form: @form, **)
          end
        end
      end
    end
  end
end
