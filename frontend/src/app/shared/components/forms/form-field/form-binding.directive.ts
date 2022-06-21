import { Directive, forwardRef, Input } from '@angular/core';
import {
  UntypedFormArray, UntypedFormControl, UntypedFormGroup, NgControl,
} from '@angular/forms';

export const formControlBinding:any = {
  provide: NgControl,
  useExisting: forwardRef(() => OpFormBindingDirective),
};

@Directive({
  selector: '[opFormBinding]',
  providers: [formControlBinding],
  exportAs: 'ngForm',
})
export class OpFormBindingDirective extends NgControl {
  @Input('opFormBinding') form!:UntypedFormControl|UntypedFormGroup|UntypedFormArray;

  get control():UntypedFormControl|UntypedFormGroup|UntypedFormArray {
    return this.form;
  }

  viewToModelUpdate():void {}
}
