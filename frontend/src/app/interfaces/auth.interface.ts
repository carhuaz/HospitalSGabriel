export interface LoginRequest {
  username: string;
  password: string;
}

export interface Usuario {
  id_usuario: number;
  username: string;
  nombre_completo: string;
  rol: string;
  activo: boolean;
}
