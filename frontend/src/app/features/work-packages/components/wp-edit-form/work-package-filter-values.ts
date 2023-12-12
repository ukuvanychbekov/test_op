import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { Injector } from '@angular/core';
import { compareByHrefOrString } from 'core-app/shared/helpers/angular/tracking-functions';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

export class WorkPackageFilterValues {
  @InjectField() currentUser:CurrentUserService;

  @InjectField() halResourceService:HalResourceService;

  @InjectField() currentProject:CurrentProjectService;

  handlers:Partial<Record<FilterOperator, (change:WorkPackageChangeset|{ [id:string]:unknown }, filter:QueryFilterInstanceResource) => void>> = {
    '=': this.applyFirstValue.bind(this),
    '!*': this.setToNull.bind(this),
  };

  constructor(
    public injector:Injector,
    private filters:QueryFilterInstanceResource[],
    private excluded:string[] = [],
  ) {}

  applyDefaultsFromFilters(change:WorkPackageChangeset|{ [id:string]:unknown }):void {
    _.each(this.filters, (filter) => {
      // Exclude filters specified in constructor
      if (this.excluded.indexOf(filter.id) !== -1) {
        return;
      }
      const operator = filter.operator.id as FilterOperator;

      // Special case due to the introduction of the project include dropdown
      // If we are in a project, we want the create wp to be part of that project.
      // Only for embedded tables, there might be different filter values necessary.
      if (filter.id === 'project') {
        if (operator !== '=') return;

        const projectFilter = _.find(filter.values, (resource:HalResource|string) => {
          return ((resource instanceof HalResource) ? resource.href : resource) === this.currentProject.apiv3Path;
        });
        this.setValue(change, 'project', projectFilter || filter.values[0]);

        return;
      }

      // ID filters should never be taken over
      if (filter.id === 'id') {
        return;
      }

      // Look for a handler with the filter's operator
      const handler = this.handlers[operator];

      // Apply the filter if there is any
      handler?.call(this, change, filter);
    });
  }

  /**
   * Apply a positive value from a '=' [value] filter
   *
   * @param filter A positive '=' filter with at least one value
   * @private
   */
  private applyFirstValue(change:WorkPackageChangeset|{ [id:string]:unknown }, filter:QueryFilterInstanceResource):void {
    // Avoid setting a value if current value is in filter list
    // and more than one value selected
    if (this.filterAlreadyApplied(change, filter)) {
      return;
    }

    // Select the first value
    const value = filter.values[0];

    // Avoid empty values
    if (value) {
      const attributeName = this.mapFilterToAttribute(filter);
      this.setValueFor(change, attributeName, value);
    }
  }

  /**
   * Set a value no null for a none type filter (!*)
   *
   * @param change changeset or resource
   * @param filter A none '!*' filter
   * @private
   */
  private setToNull(change:WorkPackageChangeset|{ [id:string]:unknown }, filter:QueryFilterInstanceResource):void {
    const attributeName = this.mapFilterToAttribute(filter);

    this.setValue(change, attributeName, { href: null });
  }

  private setValueFor(change:WorkPackageChangeset|{ [id:string]:unknown }, field:string, value:string|HalResource):void {
    const newValue = this.findSpecialValue(value, field) || value;

    if (newValue) {
      this.setValue(change, field, newValue);
    }
  }

  private setValue(change:WorkPackageChangeset|{ [id:string]:unknown }, field:string, value:unknown):void {
    if (change instanceof WorkPackageChangeset) {
      change.setValue(field, value);
    } else {
      change[field] = value;
    }
  }

  /**
   * Returns special values for which no allowed values exist (e.g., parent ID in embedded queries)
   * @param {string | HalResource} value
   * @param {string} field
   */
  private findSpecialValue(value:string|HalResource, field:string):string|HalResource|undefined {
    if (field === 'parent') {
      return value;
    }

    if (value instanceof HalResource && value.href === '/api/v3/users/me' && this.currentUser.isLoggedIn) {
      return this.halResourceService.fromSelfLink(`/api/v3/users/${this.currentUser.userId}`);
    }

    return undefined;
  }

  /**
   * Avoid applying filter values when changeset already matches one of the selected values
   * @param filter
   */
  private filterAlreadyApplied(change:WorkPackageChangeset|{ [id:string]:unknown }, filter:{ id:string, values:unknown[] }):boolean {
    const value:unknown = change instanceof WorkPackageChangeset ? change.projectedResource[filter.id] : change[filter.id];
    const current = _.castArray(value);

    for (let i = 0; i < filter.values.length; i++) {
      for (let j = 0; j < current.length; j++) {
        if (compareByHrefOrString(current[j], filter.values[i])) {
          return true;
        }
      }
    }

    return false;
  }

  /**
   * Some filter ids need to be mapped to a different attribute name
   * in order to be processed correctly.
   *
   * @param filter The filter to map
   * @returns An attribute name string to set
   * @private
   */
  private mapFilterToAttribute(filter:any):string {
    if (filter.id === 'onlySubproject') {
      return 'project';
    }

    // Default to returning the filter id
    return filter.id;
  }
}
