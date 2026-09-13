/// Una serie de la sesión en curso. Es el guardado temporal:
/// se escribe conforme anotas, sobrevive a cerrar la app y
/// desaparece al finalizar el día o al corte de las 4 AM.
///
/// [reps] en null es una casilla que aún no has llenado.
class GymSessionSet {
  int id;
  int diaId;
  int ejercicioId;
  int numeroSerie; // 1, 2, 3...
  int? reps;
  DateTime fecha; // Fecha elegida al abrir el día
  DateTime createdAt;

  GymSessionSet({
    required this.id,
    required this.diaId,
    required this.ejercicioId,
    required this.numeroSerie,
    this.reps,
    required this.fecha,
    required this.createdAt,
  });
}
