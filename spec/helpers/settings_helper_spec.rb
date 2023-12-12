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
require 'ostruct'

RSpec.describe SettingsHelper do
  include Capybara::RSpecMatchers

  let(:options) { { class: 'custom-class' } }

  before do
    allow(Setting)
      .to receive(:field_writable?)
            .and_return true
  end

  shared_examples_for 'field disabled if non writable' do
    context 'when the setting is writable' do
      it 'is enabled' do
        expect(output)
          .to have_field 'settings_field', disabled: false
      end
    end

    context 'when the setting isn`t writable' do
      before do
        allow(Setting)
          .to receive(:field_writable?)
                .and_return false
      end

      it 'is disabled' do
        expect(output)
          .to have_field 'settings_field', disabled: true
      end
    end
  end

  describe '#setting_select' do
    subject(:output) do
      helper.setting_select :field, [['Popsickle', '1'], ['Jello', '2'], ['Ice Cream', '3']], options
    end

    before do
      allow(Setting).to receive(:field).and_return('2')
    end

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'select-container'
    it_behaves_like 'field disabled if non writable'

    it 'outputs element' do
      expect(output).to have_selector 'select.form--select > option', count: 3
      expect(output).to have_select 'settings_field', selected: 'Jello'
    end
  end

  describe '#setting_multiselect' do
    subject(:output) do
      helper.setting_multiselect :field, [['Popsickle', '1'], ['Jello', '2'], ['Ice Cream', '3']], options
    end

    before do
      allow(Setting).to receive(:field).at_least(:once).and_return('1')
    end

    it_behaves_like 'wrapped in container' do
      let(:container_count) { 3 }
    end

    it 'has checkboxes wrapped in checkbox-container' do
      expect(output).to have_selector 'span.form--check-box-container', count: 3
    end

    it 'has three labels' do
      expect(output).to have_selector 'label.form--label-with-check-box', count: 3
    end

    it 'outputs element' do
      expect(output).to have_selector 'input[type="checkbox"].form--check-box', count: 3
    end

    context 'when the setting isn`t writable' do
      before do
        allow(Setting)
          .to receive(:field_writable?)
                .and_return false
      end

      it 'is disabled and has no hidden field' do
        expect(output).not_to have_selector 'input[type="hidden"][value=""]', visible: :all
        expect(output).to have_selector 'input[type="checkbox"][disabled="disabled"].form--check-box', count: 3
      end
    end
  end

  describe '#settings_matrix' do
    subject(:output) do
      settings = %i[field_a field_b]
      choices = [
        {
          caption: 'Popsickle',
          value: '1'
        },
        {
          caption: 'Jello',
          value: '2'
        },
        {
          caption: 'Ice Cream',
          value: '3'
        },
        {
          value: 'Quarkspeise'
        }
      ]
      helper.settings_matrix settings, choices
    end

    before do
      allow(Setting).to receive(:field_a).at_least(:once).and_return('2')
      allow(Setting).to receive(:field_b).at_least(:once).and_return('3')
      allow(Setting).to receive(:field_a_writable?).and_return true
      allow(Setting).to receive(:field_b_writable?).and_return true
    end

    it_behaves_like 'not wrapped in container'

    it 'is structured as a table' do
      expect(output).to have_selector 'table.form--matrix'
    end

    it 'has table headers' do
      expect(output).to have_selector 'thead th.form--matrix-header-cell', count: 3
    end

    it 'has three table rows' do
      expect(output).to have_selector 'tbody > tr.form--matrix-row', count: 4
    end

    it 'has cells with text labels' do
      expect(output).to be_html_eql(%{
        <td class="form--matrix-cell">Popsickle</td>
      }).at_path('tr:first-child > td:first-child')
    end

    it 'has cells with styled checkboxes' do
      expect(output).to be_html_eql(%{
        <td class="form--matrix-checkbox-cell">
          <span class="form--check-box-container">
            <input class="form--check-box" id="field_a_1"
              name="settings[field_a][]" type="checkbox" value="1">
          </span>
        </td>
      }).at_path('tr.form--matrix-row:first-child > td:nth-of-type(2)')

      expect(output).to be_html_eql(%{
        <td class="form--matrix-checkbox-cell">
          <span class="form--check-box-container">
            <input class="form--check-box" id="field_a_Quarkspeise"
              name="settings[field_a][]" type="checkbox" value="Quarkspeise">
          </span>
        </td>
      }).at_path('tr.form--matrix-row:last-child > td:nth-of-type(2)')
    end

    it 'has the correct fields checked' do
      expect(output).to have_checked_field 'field_a_2'
      expect(output).to have_checked_field 'field_b_3'
    end

    context 'when the setting isn`t writable' do
      before do
        allow(Setting)
          .to receive(:field_a_writable?)
                .and_return false
      end

      it 'is disabled' do
        expect(output).to be_html_eql(%{
        <td class="form--matrix-checkbox-cell">
          <span class="form--check-box-container">
            <input class="form--check-box" id="field_a_1"
              name="settings[field_a][]" type="checkbox" disabled="disabled" value="1">
          </span>
        </td>
      }).at_path('tr.form--matrix-row:first-child > td:nth-of-type(2)')
      end
    end
  end

  describe '#setting_text_field' do
    subject(:output) do
      helper.setting_text_field :field, options
    end

    before do
      allow(Setting).to receive(:field).and_return('important value')
    end

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-field-container'
    it_behaves_like 'field disabled if non writable'

    it 'outputs element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field"
          id="settings_field" name="settings[field]" type="text" value="important value" />
      }).at_path('input')
    end
  end

  describe '#setting_text_area' do
    subject(:output) do
      helper.setting_text_area :field, options
    end

    before do
      allow(Setting).to receive(:field).and_return('important text')
    end

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-area-container'
    it_behaves_like 'field disabled if non writable'

    it 'outputs element' do
      expect(output).to be_html_eql(%{
        <textarea class="custom-class form--text-area" id="settings_field" name="settings[field]">
important text</textarea>
      }).at_path('textarea')
    end
  end

  describe '#setting_check_box' do
    subject(:output) do
      helper.setting_check_box :field, options
    end

    context 'when setting is true' do
      before do
        allow(Setting).to receive(:field?).and_return(true)
      end

      it_behaves_like 'labelled by default'
      it_behaves_like 'wrapped in field-container by default'
      it_behaves_like 'wrapped in container', 'check-box-container'
      it_behaves_like 'field disabled if non writable'

      it 'outputs element' do
        expect(output).to have_selector 'input[type="hidden"][value=0]', visible: :hidden
        expect(output).to have_selector 'input[type="checkbox"].custom-class.form--check-box'
        expect(output).to have_checked_field 'settings_field'
      end

      context 'when the setting isn`t writable' do
        before do
          allow(Setting)
            .to receive(:field_writable?)
                  .and_return false
        end

        it 'does not output a hidden field' do
          expect(output).not_to have_selector 'input[type="hidden"][value=0]', visible: :hidden
        end
      end
    end

    context 'when setting is false' do
      before do
        allow(Setting).to receive(:field?).and_return(false)
      end

      it_behaves_like 'labelled by default'
      it_behaves_like 'wrapped in field-container by default'
      it_behaves_like 'wrapped in container', 'check-box-container'
      it_behaves_like 'field disabled if non writable'

      it 'outputs element' do
        expect(output).to have_selector 'input[type="hidden"][value=0]', visible: :hidden
        expect(output).to have_selector 'input[type="checkbox"].custom-class.form--check-box'
        expect(output).to have_unchecked_field 'settings_field'
      end

      context 'when the setting isn`t writable' do
        before do
          allow(Setting)
            .to receive(:field_writable?)
                  .and_return false
        end

        it 'does not output a hidden field' do
          expect(output).not_to have_selector 'input[type="hidden"][value=0]', visible: :hidden
        end
      end
    end
  end

  describe '#setting_time_field' do
    subject(:output) do
      helper.setting_time_field :field, options
    end

    before do
      allow(Setting).to receive(:field).and_return('16:00')
    end

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-field-container'

    it 'outputs element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field -time"
          id="settings_field" name="settings[field]" type="time" value="16:00" />
      }).at_path('input')
    end
  end

  describe '#setting_label' do
    subject(:output) do
      helper.setting_label :field
    end

    it_behaves_like 'labelled'
    it_behaves_like 'not wrapped in container'
  end
end
