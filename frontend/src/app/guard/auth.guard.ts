import { inject } from '@angular/core';
import { CanActivateFn, Router, UrlTree } from '@angular/router';
import { AuthService } from '../service/auth.service';

export const AuthGuard: CanActivateFn = (route, state): boolean | UrlTree=> {
  const router = inject(Router);
  const authService = inject(AuthService);

  const roles = route.data['roles'] as Array<string>;
  if(!authService.isLoggedIn()) {
    // Store the attempted URL for redirecting
  return router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
  }

  if(roles) {
    const userRole = authService.getRoleFromToken();
    if(!userRole || !roles.includes(userRole)) {
      return router.createUrlTree(['/unauthorized']);
    }
  }

  return true;
  
};
