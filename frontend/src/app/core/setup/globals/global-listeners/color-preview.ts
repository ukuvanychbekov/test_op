// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

/**
 * Moved from app/assets/javascripts/colors.js
 *
 * Make this a component instead of modifying it the next time
 * this needs changes
 */
export function makeColorPreviews() {
  jQuery('.color--preview').each(function () {
    const preview = jQuery(this);
    let input:any;
    const target = preview.data('target');

    if (target) {
      input = jQuery(target);
    } else {
      input = preview.next('input');
    }

    if (input.length === 0) {
      return;
    }

    const func = function () {
      let previewColor = '';

      if (input.val() && input.val().length > 0) {
        previewColor = input.val();
      } else if (input.attr('placeholder')
        && input.attr('placeholder').length > 0) {
        previewColor = input.attr('placeholder');
      }

      preview.css('background-color', previewColor);
    };

    input.keyup(func).change(func).focus(func);
    func();
  });
}
