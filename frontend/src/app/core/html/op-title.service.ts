import { Title } from '@angular/platform-browser';
import { Injectable } from '@angular/core';

const titlePartsSeparator = ' | ';

@Injectable({ providedIn: 'root' })
export class OpTitleService {
  constructor(private titleService:Title) {

  }

  public get current():string {
    return this.titleService.getTitle();
  }

  public get titleParts():string[] {
    return this.current.split(titlePartsSeparator);
  }

  public setFirstPart(value:string) {
    const parts = this.titleParts;
    parts[0] = value;

    this.titleService.setTitle(parts.join(titlePartsSeparator));
  }

  public prependFirstPart(value:string):void {
    const parts = this.titleParts;
    parts.unshift(value);

    this.titleService.setTitle(parts.join(titlePartsSeparator));
  }
}
