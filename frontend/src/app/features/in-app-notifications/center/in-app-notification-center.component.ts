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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  filter,
  map,
} from 'rxjs/operators';
import { StateService } from '@uirouter/angular';
import { UIRouterGlobals } from '@uirouter/core';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import {
  INotification,
  NOTIFICATIONS_MAX_SIZE,
} from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import { imagePath } from 'core-app/shared/helpers/images/path-helper';

@Component({
  selector: 'op-in-app-notification-center',
  templateUrl: './in-app-notification-center.component.html',
  styleUrls: ['./in-app-notification-center.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InAppNotificationCenterComponent implements OnInit {
  maxSize = NOTIFICATIONS_MAX_SIZE;

  hasMoreThanPageSize$ = this.storeService.hasMoreThanPageSize$;

  hasNotifications$ = this.storeService.hasNotifications$;

  notifications$ = this.storeService.notifications$;

  loading$ = this.storeService.loading$;

  totalCount$ = this.bellService.unread$;

  totalCountWarning$ = this
    .storeService
    .notLoaded$
    .pipe(
      filter((notLoaded) => notLoaded > 0),
      map((notLoaded:number) => this.I18n.t(
        'js.notifications.center.total_count_warning',
        { newest_count: this.maxSize, more_count: notLoaded },
      )),
    );

  stateChanged$ = this.storeService.stateChanged$;

  reasonMenuItems = [
    {
      key: 'mentioned',
      title: this.I18n.t('js.notifications.menu.mentioned'),
    },
    {
      key: 'assigned',
      title: this.I18n.t('js.label_assignee'),
    },
    {
      key: 'responsible',
      title: this.I18n.t('js.notifications.menu.accountable'),
    },
    {
      key: 'watched',
      title: this.I18n.t('js.notifications.menu.watched'),
    },
    {
      key: 'dateAlert',
      title: this.I18n.t('js.notifications.menu.date_alert'),
    },
    {
      key: 'shared',
      title: this.I18n.t('js.notifications.menu.shared'),
    },
  ];

  selectedFilter = this.reasonMenuItems.find((item) => item.key === this.uiRouterGlobals.params.name)?.title;

  image = {
    no_notification: imagePath('notification-center/empty-state-no-notification.svg'),
    no_selection: imagePath('notification-center/empty-state-no-selection.svg'),
    loading: imagePath('notification-center/notification_loading.gif'),
  };

  trackNotificationGroups = (i:number, item:INotification[]):string => item
    .map((el) => `${el.id}@${el.updatedAt}`)
    .join(',');

  text = {
    no_notification: this.I18n.t('js.notifications.center.empty_state.no_notification'),
    no_notification_with_current_filter_project: this.I18n.t('js.notifications.center.empty_state.no_notification_with_current_project_filter'),
    no_notification_with_current_filter: this.I18n.t('js.notifications.center.empty_state.no_notification_with_current_filter', { filter: this.selectedFilter }),
    no_selection: this.I18n.t('js.notifications.center.empty_state.no_selection'),
    change_notification_settings: this.I18n.t(
      'js.notifications.settings.change_notification_settings',
      { url: this.pathService.myNotificationsSettingsPath() },
    ),
    title: this.I18n.t('js.notifications.title'),
    button_close: this.I18n.t('js.button_close'),
    no_results: {
      at_all: this.I18n.t(
        'js.notifications.center.no_results.at_all',
        { url: this.pathService.myNotificationsSettingsPath() },
      ),
      with_current_filter: this.I18n.t('js.notifications.center.no_results.with_current_filter'),
    },
  };

  constructor(
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
    readonly I18n:I18nService,
    readonly storeService:IanCenterService,
    readonly bellService:IanBellService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly state:StateService,
    readonly apiV3:ApiV3Service,
    readonly pathService:PathHelperService,
  ) {
  }

  ngOnInit():void {
    this.storeService.setFacet('unread');
    this.storeService.setFilters({
      filter: this.uiRouterGlobals.params.filter, // eslint-disable-line @typescript-eslint/no-unsafe-assignment
      name: this.uiRouterGlobals.params.name, // eslint-disable-line @typescript-eslint/no-unsafe-assignment
    });
  }

  noNotificationText(hasNotifications:boolean):string {
    if (!hasNotifications) {
      return this.text.no_notification;
    }
    return (this.uiRouterGlobals.params.filter === 'project' ? this.text.no_notification_with_current_filter_project : this.text.no_notification_with_current_filter);
  }
}
