import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthEventService {
  private tokenUpdateSubject = new Subject<string>();
  tokenUpdate$ = this.tokenUpdateSubject.asObservable();

  emitTokenUpdate(token: string) {
    this.tokenUpdateSubject.next(token);
  }
}
