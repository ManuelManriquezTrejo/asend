class FundAccount {
  final int id;
  final int fundId; // ID del fondo (ej: 1 = "sueldo")
  final int accountId; // ID de la cuenta (ej: 2 = "ahorrar")
  final double percentage; // Porcentaje (ej: 75.0 = 75%)

  FundAccount({
    required this.id,
    required this.fundId,
    required this.accountId,
    required this.percentage,
  });
}

//Relacionar el fondo con la cuenta para ver cuanto le toca a cada uno
