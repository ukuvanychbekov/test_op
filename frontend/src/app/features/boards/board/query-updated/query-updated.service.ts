import { Injectable } from '@angular/core';
import { interval } from 'rxjs';
import { filter, startWith, switchMap } from 'rxjs/operators';
import { ActiveWindowService } from 'core-app/core/active-window/active-window.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

const POLLING_INTERVAL = 2000;

@Injectable()
export class QueryUpdatedService {
  constructor(readonly activeWindow:ActiveWindowService,
    readonly apiV3Service:ApiV3Service) {
  }

  public monitor(ids:string[]) {
    let time = new Date();

    return interval(POLLING_INTERVAL)
      .pipe(
        startWith(0),
        filter(() => ids.length > 0),
        filter(() => this.activeWindow.isActive),
        switchMap(() => {
          const result = this.queryForUpdates(ids, time);

          time = new Date();

          return result;
        }),
        filter((collection) => collection.count > 0),
      );
  }

  private queryForUpdates(ids:string[], updatedAfter:Date) {
    return this
      .apiV3Service
      .queries
      .list({
        filters: [['id', '=', ids],
          ['updatedAt', '<>d', [updatedAfter.toISOString()]]],
      });
  }
}
