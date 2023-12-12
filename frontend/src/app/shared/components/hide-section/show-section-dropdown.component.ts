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

import { Component, ElementRef, OnInit } from '@angular/core';
import { HideSectionService } from './hide-section.service';

export const showSectionDropdownSelector = 'show-section-dropdown';

@Component({
  selector: showSectionDropdownSelector,
  template: '',
})
export class ShowSectionDropdownComponent implements OnInit {
  public optValue:string; // value of option for which hide-section should be visible

  public hideSecWithName:string; // section-name of hide-section

  constructor(private HideSection:HideSectionService,
    private elementRef:ElementRef) {
  }

  ngOnInit() {
    const element = jQuery(this.elementRef.nativeElement);
    this.optValue = element.data('optValue');
    this.hideSecWithName = element.data('hideSecWithName');

    const target = jQuery(this.elementRef.nativeElement).prev();
    target.on('change', (event) => {
      const selectedOption = jQuery('option:selected', event.target);

      if (selectedOption.val() !== this.optValue) {
        this.HideSection.hide(this.hideSecWithName);
      } else {
        this.HideSection.show(this.hideSecWithName);
      }
    });
  }
}
