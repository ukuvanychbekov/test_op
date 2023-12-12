/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import { renderStreamMessage } from '@hotwired/turbo';
import { ModalDialogElement } from '@openproject/primer-view-components/app/components/primer/alpha/modal_dialog';

export default class OpenProjectStorageModalController extends Controller<ModalDialogElement> {
  static values = {
    projectStorageOpenUrl: String,
    redirectUrl: String,
  };

  interval:number;
  projectStorageOpenUrlValue:string;
  redirectUrlValue:string;

  connect() {
    this.element.open = true;
    this.interval = 0;
    this.load();
    this.element.addEventListener('close', () => { this.disconnect(); });
    this.element.addEventListener('cancel', () => { this.disconnect(); });
  }

  disconnect() {
    clearInterval(this.interval);
  }

  load() {
    this.interval = setTimeout(
      async () => {
        const response = await fetch(
          this.projectStorageOpenUrlValue,
          {
            headers: {
              Accept: 'text/vnd.turbo-stream.html',
            },
          },
        );
        if (response.status === 200) {
          const streamActionHTML = await response.text();
          renderStreamMessage(streamActionHTML);
          setTimeout(
            () => { window.location.href = this.redirectUrlValue; },
            2000,
          );
        } else {
          this.load();
        }
      },
      3000,
);
  }
}
