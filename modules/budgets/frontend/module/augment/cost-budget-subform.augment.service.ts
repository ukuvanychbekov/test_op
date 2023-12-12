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

import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { finalize } from 'rxjs/operators';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';

@Injectable()
export class CostBudgetSubformAugmentService {
  constructor(private halNotification:HalResourceNotificationService,
    private http:HttpClient) {
  }

  listen():void {
    jQuery('costs-budget-subform').each((i, match) => {
      const el = jQuery(match);

      const container = el.find('.budget-item-container');
      const templateEl = el.find('.budget-row-template');
      templateEl.detach();
      const template = templateEl[0].outerHTML;
      let rowIndex = parseInt(el.attr('item-count') as string, 10);

      // Refresh row on changes
      el.on('change', '.budget-item-value', (evt) => {
        const row = jQuery(evt.target).closest('.cost_entry');
        this.refreshRow(el, row.attr('id') as string);
      });

      el.on('click', '.delete-budget-item', (evt) => {
        evt.preventDefault();
        jQuery(evt.target).closest('.cost_entry').remove();
        return false;
      });

      // Add new row handler
      el.find('.budget-add-row').on('click', (evt) => {
        evt.preventDefault();
        const row = jQuery(template.replace(/INDEX/g, rowIndex.toString()));
        row.show();
        row.removeClass('budget-row-template');
        container.append(row);
        rowIndex += 1;
        return false;
      });
    });
  }

  /**
   * Refreshes the given row after updating values
   */
  public refreshRow(el:JQuery, row_identifier:string):void {
    const form = el.parents('form').first();
    form.find(':submit').attr('disabled', 'disabled');

    const row = el.find(`#${row_identifier}`);
    const request = this.buildRefreshRequest(row, row_identifier);

    this.http
      .post(
        el.attr('update-url') as string,
        request,
        {
          headers: { Accept: 'application/json' },
          withCredentials: true,
        },
      )
      .pipe(
        finalize(() => {
          form.find(':submit').attr('disabled', null);
        }),
      )
      .subscribe(
        (data:any) => {
          _.each(data, (val:string, selector:string) => {
            const element = document.getElementById(selector) as HTMLElement|HTMLInputElement|undefined;
            if (element instanceof HTMLInputElement) {
              element.disabled = false;
              element.value = val;
            } else if (element) {
              element.textContent = val;
            }
          });
        },
        (error:any) => this.halNotification.handleRawError(error),
      );
  }

  /**
   * Returns the params for the update request
   */
  private buildRefreshRequest(row:JQuery, row_identifier:string) {
    const request:Record<string, unknown> = {
      element_id: row_identifier,
      fixed_date: jQuery('#budget_fixed_date').val(),
    };

    // Augment common values with specific values for this type
    row.find('.budget-item-value').each((i:number, el:Element) => {
      const field = jQuery(el);
      request[field.data('requestKey') as string] = field.val() || '0';
    });

    return request;
  }
}
