import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { SingleRowBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/rows/single-row-builder';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { groupedRowClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-rows-helpers';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';

export class GroupSumsBuilder extends SingleRowBuilder {
  @InjectField() readonly querySpace:IsolatedQuerySpace;

  @InjectField() readonly schemaCache:SchemaCacheService;

  @InjectField() readonly displayFieldService:DisplayFieldService;

  public text = {
    sum: this.I18n.t('js.label_sum'),
  };

  public buildSumsRow(group:GroupObject) {
    const tr:HTMLTableRowElement = document.createElement('tr');
    tr.classList.add('wp-table--sums-row', 'wp-table--row', groupedRowClassName(group.index));

    this.renderColumns(group.sums, tr);

    return tr;
  }

  public renderColumns(sums:{ [key:string]:any }, tr:HTMLTableRowElement) {
    this.augmentedColumns.forEach((column, i:number) => {
      const td = document.createElement('td');
      const div = this.renderContent(sums, column.id, this.sumsSchema[column.id]);

      if (i === 0) {
        this.appendFirstLabel(div);
      }

      td.appendChild(div);
      tr.append(td);
    });
  }

  private appendFirstLabel(div:HTMLElement) {
    const span = document.createElement('span');
    span.textContent = `${this.text.sum}`;
    span.title = `${this.text.sum}`;
    div.prepend(span);
  }

  private get sumsSchema():SchemaResource {
    // The schema is ensured to be loaded by wpViewAdditionalElementsService
    const results = this.querySpace.results.value!;
    const href = results.sumsSchema!.href!;

    return this.schemaCache.state(href).value!;
  }

  private renderContent(sums:any, name:string, fieldSchema:IFieldSchema) {
    const div = document.createElement('div');
    div.classList.add('wp-table--sum-container', name);

    // The field schema for this element may be undefined
    // because it is not summable.
    if (!fieldSchema) {
      return div;
    }

    const field = this.displayFieldService.getField(
      sums,
      name,
      fieldSchema,
      { injector: this.injector, container: 'table', options: {} },
    );

    if (!field.isEmpty()) {
      field.render(div, field.valueString);
    }

    return div;
  }
}
