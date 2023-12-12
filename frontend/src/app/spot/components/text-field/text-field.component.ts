import {
  Component,
  ElementRef,
  ViewChild,
  forwardRef,
  HostBinding,
  HostListener,
  Input,
  Output,
  EventEmitter,
  ChangeDetectorRef,
} from '@angular/core';
import {
  ControlValueAccessor,
  NG_VALUE_ACCESSOR,
} from '@angular/forms';

@Component({
  selector: 'spot-text-field',
  templateUrl: './text-field.component.html',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => SpotTextFieldComponent),
    multi: true,
  }],
})
export class SpotTextFieldComponent implements ControlValueAccessor {
  @HostBinding('class.spot-text-field') public className = true;

  @HostBinding('class.spot-text-field_focused') public focused = false;

  @HostListener('click')
  public onParentClick():void {
    this.input.nativeElement.focus();
  }

  @ViewChild('input') public input:ElementRef;

  /**
   * The name of the input. Will be autogenerated if not given,
   * but especially useful to provide in a hybrid Rails <-> Angular context
   * where a submit of a form is handled without JS.
   */
  @Input() public name = `spot-text-field-${+(new Date())}`;

  /**
   * Whether the input should be disabled
   */
  @Input() @HostBinding('class.spot-text-field_disabled') public disabled = false;

  /**
   * By default, we show a small "x" inside the input on the right hand side if
   * some value has been set. This is a button that clears the input. Setting this option
   * to false will not show this clear button.
   */
  @Input() public showClearButton = true;

  /**
   * The placeholder text.
   * This should never be a label replacement, since placeholders are not properly accessible.
   */
  @Input() public placeholder = '';

  /**
   * If you're not using Angular Reactive Forms (Which you should be using!)
   * then you can manually set the value via this input.
   */
  @Input() public value = '';

  /**
   * Whether the field should be receive a [required] property.
   */
  @Input() public required:boolean = false;

  /**
   * The html input (Regexp) pattern to provide hints to keyboards what layout to use
   * and to aid in validation.
   */
  @Input() public pattern:string|undefined;

  /**
   * The html inputmode to hint virtual keyboard layouts.
   */
  @Input() public inputmode:'text'|'decimal'|'numeric'|'tel'|'search'|'email'|'url' = 'text';

  valueChanged(value:string):void {
    this.writeValue(value);
    this.onChange(value);
    this.onTouched(value);
  }

  @Output() public inputFocus = new EventEmitter<FocusEvent>();

  @Output() public inputBlur = new EventEmitter<FocusEvent>();

  constructor(
    private cdRef:ChangeDetectorRef,
  ) {}

  onInputFocus(event:FocusEvent):void {
    this.focused = true;
    this.inputFocus.next(event);
  }

  onInputBlur(event:FocusEvent):void {
    this.focused = false;
    this.inputBlur.next(event);
  }

  writeValue(value:string) {
    this.value = value || '';
    this.cdRef.markForCheck();
  }

  onChange = (_:string):void => {};

  onTouched = (_:string):void => {};

  registerOnChange(fn:(_:string) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:string) => void):void {
    this.onTouched = fn;
  }
}