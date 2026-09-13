# Asend

App de productividad personal para Android, construida en Flutter con almacenamiento local.

La idea: App personal para registro de; Actividades, rutinas, futuras compras, rutinas de gym, cuentas personales, cumpleaños y mas con apartados para autocalificar actividades y obtener recompesas.

## Módulos

| Módulo | Qué hace |
|---|---|
| Banco | Cuentas y fondos con distribución porcentual. Historial de cada movimiento. |
| Rutina | Hábitos diarios con rachas, corte de día a las 4 AM y auto-relleno de días perdidos. |
| Misiones | Tablón con misiones y submisiones. Completar una genera un pago. |
| Pagos | Cobro diario por rutina y por misión, con cuentas de origen y destino configurables. |
| Metas | Ahorro por objetivo, con reparto equitativo y abonos individuales. |
| Tienda | Registro de compras del mes, con historial mensual y desglose. |
| Cumpleaños | Lista ordenada por proximidad, con edad actual. |
| Gym | Días de rutina, ejercicios con peso y formato, y registro de series por sesión. |
| Medidas | Zonas corporales con unidad configurable y seguimiento en el tiempo. |

## Cómo está construido

- **Flutter y Dart** para toda la app.
- **Hive** para persistencia local. Sin servidor: los datos viven en el dispositivo.
- **Adapters escritos a mano** en lugar de generados, para controlar el formato binario de cada modelo.

### Decisiones de diseño

**Borrado suave en todo.** Nada se elimina de verdad. Cada registro lleva una fecha de borrado, así el historial sobrevive aunque borres un hábito o una cuenta.

**Snapshots de valores.** Cuando se registra un pago o una sesión de gym, se congela la configuración del momento. Cambiar el peso de un ejercicio hoy no altera lo que entrenaste el mes pasado.

**Corte de día a las 4 AM.** Un hábito completado a la 1 AM cuenta para el día anterior. El criterio es el mismo en toda la app.

**Guardado progresivo.** En gym y medidas, cada dato se escribe al momento de capturarlo. Cerrar la app a media sesión no pierde nada.

## Cómo correrlo

```bash
flutter pub get
flutter run
```

Requiere Flutter instalado y un dispositivo Android conectado.

## Estado

En uso diario. En desarrollo: un módulo de gráficas para visualizar el progreso de cada módulo en el tiempo.