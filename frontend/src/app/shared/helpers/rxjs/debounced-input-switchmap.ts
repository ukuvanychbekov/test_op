import {
  concat, Observable, of, Subject,
} from 'rxjs';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  filter,
  shareReplay,
  switchMap,
  takeUntil,
  tap,
} from 'rxjs/operators';
import { RequestSwitchmapHandler } from 'core-app/shared/helpers/rxjs/request-switchmap';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export type RequestErrorHandler = (error:unknown) => void;

export function errorNotificationHandler(service:HalResourceNotificationService):RequestErrorHandler {
  return (error:unknown) => service.handleRawError(error);
}

export class DebouncedRequestSwitchmap<T, R = HalResource> {
  /** Input request state */
  public input$ = new Subject<T>();

  /** Output results observable */
  public output$:Observable<R[]>;

  /** Loading flag */
  public loading$ = new Subject<boolean>();

  /** Whether results were returned */
  public lastResult:R[] = [];

  /** Last requested value */
  public lastRequestedValue:T|undefined;

  /**
   * @param handler switch map handler function to output a response observable
   * @param debounceTime {number} Time to debounce in ms.
   * @param preFilterNull {boolean} Whether to exclude null and undefined searches
   * @param emptyValue {R} The empty fall back value before first response or on errors
   */
  constructor(
    readonly requestHandler:RequestSwitchmapHandler<T, R[]>,
    readonly errorHandler:RequestErrorHandler,
    readonly preFilterNull:boolean = false,
    readonly debounceMs = 250,
  ) {
    /** Output switchmap observable */
    this.output$ = concat(
      of([]),
      this.input$.pipe(
        filter((val) => !preFilterNull || (val !== undefined && val !== null)),
        distinctUntilChanged(),
        debounceTime(debounceMs),
        tap((val:T) => {
          this.lastRequestedValue = val;
          this.lastResult = [];
          this.loading$.next(true);
        }),
        switchMap((term) => this.requestHandler(term)
          .pipe(
            catchError((error) => {
              this.errorHandler(error);
              return of([]);
            }),
            tap((results) => {
              this.loading$.next(false);
              this.lastResult = results;
            }),
          )),
        shareReplay(1),
      ),
    );
  }

  /**
   * Append a new request for the given request value and pass
   * that to the switchmap handler
   * @param newValue
   */
  public request(newValue:T) {
    this.input$.next(newValue);
  }

  /**
   * Returns whether the last results returned anything
   */
  public get hasResults() {
    return this.lastResult.length > 0;
  }

  /**
   * Observe the switched response
   */
  public observe(until:Observable<unknown>) {
    return this
      .output$
      .pipe(
        takeUntil(until),
      );
  }
}
