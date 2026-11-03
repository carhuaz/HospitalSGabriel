import { HttpErrorResponse } from '@angular/common/http';

interface ErrorBody {
  detail?: unknown;
}

export function getApiErrorMessage(error: unknown): string {
  if (error instanceof HttpErrorResponse) {
    const body = error.error as ErrorBody | null;
    const detail = body?.detail;

    if (typeof detail === 'string' && detail.trim()) {
      return detail;
    }

    if (Array.isArray(detail)) {
      const mensajes = detail
        .map((item) => {
          if (typeof item === 'string') {
            return item;
          }
          if (item && typeof item === 'object' && 'msg' in item) {
            return String((item as { msg: unknown }).msg);
          }
          return '';
        })
        .filter((mensaje) => mensaje.length > 0);

      if (mensajes.length > 0) {
        return mensajes.join('. ');
      }
    }

    if (error.status === 0) {
      return 'No se pudo conectar con el backend. Verifica que esté levantado en el puerto 8000.';
    }

    return error.message || 'Ocurrió un error al consumir la API.';
  }

  if (error instanceof Error) {
    return error.message;
  }

  return 'Ocurrió un error inesperado.';
}
