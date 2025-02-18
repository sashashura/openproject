import {
  Component,
  ElementRef,
  EventEmitter,
  forwardRef,
  HostBinding,
  Input,
  Output,
  ViewChild,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
} from '@angular/core';
import {
  ControlValueAccessor,
  NG_VALUE_ACCESSOR,
} from '@angular/forms';

export type SpotCheckboxState = true|false|null;

@Component({
  selector: 'spot-checkbox',
  templateUrl: './checkbox.component.html',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => SpotCheckboxComponent),
    multi: true,
  }],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SpotCheckboxComponent implements ControlValueAccessor {
  @HostBinding('class.spot-checkbox') public className = true;

  @ViewChild('input') public input:ElementRef;

  @Input() tabindex = 0;

  @Input() disabled = false;

  @Input() name = `spot-checkbox-${+(new Date())}`;

  @Output() checkedChange = new EventEmitter<boolean>();

  @Input() public checked = false;

  constructor(
    readonly cdRef:ChangeDetectorRef,
  ) {}

  onStateChange():void {
    const value = (this.input.nativeElement as HTMLInputElement).checked;
    this.checkedChange.emit(value);
    this.onChange(value);
    this.onTouched(value);
  }

  writeValue(value:SpotCheckboxState):void {
    // This is set in a timeout because the initial value is set before the template is ready,
    // which causes the input nativeElement to not be available yet.
    setTimeout(() => {
      const input = this.input.nativeElement as HTMLInputElement;
      input.indeterminate = value === null;

      this.checked = !!value;
      this.cdRef.detectChanges();
    });
  }

  onChange = (_:SpotCheckboxState):void => {};

  onTouched = (_:SpotCheckboxState):void => {};

  registerOnChange(fn:(_:SpotCheckboxState) => void):void {
    this.onChange = fn;
  }

  registerOnTouched(fn:(_:SpotCheckboxState) => void):void {
    this.onTouched = fn;
  }
}
