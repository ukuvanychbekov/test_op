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

import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';

export class ProgressDisplayField extends DisplayField {
  public get value() {
    if (this.schema) {
      return this.resource[this.name] || 0;
    }
    return null;
  }

  public get percentLabel() {
    return `${this.roundedProgress}%`;
  }

  public get roundedProgress() {
    return Math.round(Number(this.value)) || 0;
  }

  public render(element:HTMLElement, displayText:string):void {
    element.setAttribute('title', displayText);
    element.innerHTML = `
      <span>
        <span style="width: 80px" class="progress-bar">
          <span style="width: ${this.roundedProgress}%" class="inner-progress closed"></span>
          <span style="width: 0%" class="inner-progress done"></span>
        </span>
        <span class="progress-bar-legend">${this.percentLabel}</span>
      </span>
    `;
  }
}
