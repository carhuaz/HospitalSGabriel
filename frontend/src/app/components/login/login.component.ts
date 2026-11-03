import { Component, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { FormField, FormRoot, form, required } from '@angular/forms/signals';
import { firstValueFrom } from 'rxjs';

import { LoginRequest } from '../../interfaces/auth.interface';
import { getApiErrorMessage } from '../../services/api-error';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  imports: [FormField, FormRoot],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css',
})
export class Login {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);

  readonly loginModel = signal<LoginRequest>({
    username: '',
    password: '',
  });

  readonly error = signal('');

  readonly loginForm = form(
    this.loginModel,
    (schema) => {
      required(schema.username);
      required(schema.password);
    },
    {
      submission: {
        action: async (field) => {
          this.error.set('');

          try {
            await firstValueFrom(this.authService.login(field().value()));
            await this.router.navigate(['/dashboard']);
          } catch (error) {
            this.error.set(getApiErrorMessage(error));
          }
        },
      },
    },
  );
}
