// Archivo de datos: las 6 magias de fábrica con todas sus habilidades.
// Al agregar una magia desde Stats se copia de aquí; después todo se
// puede editar dentro de la app.
//
// Los costos de mana están pensados para esta reserva de referencia por
// rango: F 25, E 60, D 150, C 350, B 700, A 1300, S 2300, SS 4000. Así una
// habilidad básica de tu rango cuesta de 1% a 6% de la reserva, una fuerte
// de 8% a 15% y la última de cada magia (rango SS) cerca del 22%, para que
// en rangos altos se puedan usar varias cosas seguidas.

class PlantillaNivel {
  final int rango;
  final String descripcion;
  final String mana;

  const PlantillaNivel(this.rango, this.descripcion, this.mana);
}

class PlantillaHabilidad {
  final String nombre;
  final String tipo;
  final String nota;
  final List<PlantillaNivel> niveles;

  const PlantillaHabilidad(this.nombre, this.tipo, this.nota, this.niveles);
}

class PlantillaMagia {
  final String clave;
  final String nombre;
  final List<PlantillaHabilidad> habilidades;

  const PlantillaMagia(this.clave, this.nombre, this.habilidades);
}

/// Rangos: 0 = F, 1 = E, 2 = D, 3 = C, 4 = B, 5 = A, 6 = S, 7 = SS.
const List<PlantillaMagia> plantillasMagia = [
  PlantillaMagia('sombra', 'Sombras', [
    PlantillaHabilidad('Materialización de sombras', 'Ataque', 'Creas armas sólidas hechas de sombra. Cada arma puede salir un rango más fuerte con la probabilidad indicada', [
      PlantillaNivel(0, 'Creas 1 daga de rango F. 10% de que salga de rango E.', '1 por invocación'),
      PlantillaNivel(1, 'Creas 1 daga de rango E. 12% de que salga de rango D.', '2 por invocación'),
      PlantillaNivel(2, 'Creas 1 espada o lanza de rango D. 15% de que salga de rango C.', '6 por invocación'),
      PlantillaNivel(3, 'Creas hasta 3 armas de cualquier tipo de rango C. 20% de que cada una salga de rango B.', '18 por invocación (hasta 3 armas)'),
      PlantillaNivel(4, 'Creas hasta 3 armas de cualquier tipo, incluidas pesadas, de rango B. 27% de que cada una salga de rango A.', '35 por invocación (hasta 3 armas)'),
      PlantillaNivel(5, 'Creas hasta 10 armas de rango A que flotan y atacan solas hasta a 20 m de ti. 37% de que cada una salga de rango S.', '80 por invocación (hasta 10 armas)'),
      PlantillaNivel(6, 'Creas hasta 10 armas flotantes de rango S, hasta a 20 m de ti, que atraviesan armadura. 50% de que cada una salga de rango SS.', '140 por invocación (hasta 10 armas)'),
      PlantillaNivel(7, 'Lluvia de 50 armas de rango SS que atraviesan armadura. 65% de que cada una salga legendaria.', '320 por lluvia de 50 armas'),
    ]),
    PlantillaHabilidad('Inventario de sombras', 'Apoyo', 'Guardas objetos dentro de tu sombra. Guardar cuesta mana según el peso; sacar es gratis', [
      PlantillaNivel(0, 'Capacidad de 5 kg.', '0.5 por kg guardado'),
      PlantillaNivel(1, 'Capacidad de 15 kg.', '0.5 por kg guardado'),
      PlantillaNivel(2, 'Capacidad de 50 kg. Sacas cualquier objeto en 1 s.', '0.3 por kg guardado'),
      PlantillaNivel(3, 'Capacidad de 150 kg. Sacas cualquier objeto en 1 s.', '0.2 por kg guardado'),
      PlantillaNivel(4, 'Capacidad de 500 kg. Sacas cualquier objeto en 1 s. El tiempo se detiene dentro: la comida no se echa a perder.', '0.1 por kg guardado'),
      PlantillaNivel(5, 'Capacidad de 2 t. Sacas en 1 s y el tiempo se detiene dentro. Puedes guardar objetos que toquen cualquier sombra a 5 m de ti.', '0.05 por kg guardado'),
      PlantillaNivel(6, 'Capacidad de 10 t. Sacas en 1 s y el tiempo se detiene dentro. Guardas desde sombras a 5 m de ti.', '0.02 por kg guardado'),
      PlantillaNivel(7, 'Capacidad de 50 t. Sacas en 1 s y el tiempo se detiene dentro. Guardas desde sombras a 50 m de ti.', '0.01 por kg guardado'),
    ]),
    PlantillaHabilidad('Portales de sombra', 'Apoyo', 'Entras en una sombra y sales por otra sombra a la distancia indicada', [
      PlantillaNivel(0, 'Sales por otra sombra a máximo 5 m. Solo viajas tú, sin lo que cargues.', '3 por portal'),
      PlantillaNivel(1, 'Sales por otra sombra a máximo 10 m. Llevas contigo lo que cargues.', '4 por portal'),
      PlantillaNivel(2, 'Sales por otra sombra a máximo 100 m, sin necesidad de verla. Llevas lo que cargues.', '10 por portal'),
      PlantillaNivel(3, 'Sales a máximo 5 km, sin necesidad de ver la salida. Llevas lo que cargues y puedes mandar a otras personas hasta 5 km.', '25 por portal + 15 por persona'),
      PlantillaNivel(4, 'Sales a máximo 20 km, sin ver la salida. Llevas lo que cargues y mandas a otras personas hasta 20 km.', '40 por portal + 20 por persona'),
      PlantillaNivel(5, 'Sales a máximo 100 km, sin ver la salida. El portal queda abierto 10 s para que pasen otras personas.', '70 por portal + 25 por persona'),
      PlantillaNivel(6, 'Sales a máximo 1,000 km, sin ver la salida. El portal queda abierto 10 s para que pasen otras personas.', '120 por portal + 30 por persona'),
      PlantillaNivel(7, 'Sales en cualquier lugar donde hayas estado. El portal queda abierto 10 s para que pasen otras personas.', '250 por portal + 40 por persona'),
    ]),
    PlantillaHabilidad('Ceguera', 'Apoyo', 'Cubres de sombra los ojos del objetivo y no puede ver', [
      PlantillaNivel(1, 'Ciegas a 1 objetivo a máximo 5 m durante 3 s.', '3 por objetivo'),
      PlantillaNivel(2, 'Ciegas a 1 objetivo a máximo 10 m durante 10 s.', '6 por objetivo'),
      PlantillaNivel(3, 'Ciegas hasta 3 objetivos a máximo 15 m durante 15 s.', '10 por objetivo'),
      PlantillaNivel(4, 'Ciegas hasta 5 objetivos a máximo 20 m durante 30 s.', '15 por objetivo'),
      PlantillaNivel(5, 'Ciegas a todos en un área de 10 m de radio durante 1 min.', '120 por uso'),
      PlantillaNivel(6, 'Ciegas a todos en un área de 30 m de radio durante 3 min. También bloquea la visión mágica.', '220 por uso'),
      PlantillaNivel(7, 'Ciegas a todos en un área de 100 m de radio durante 10 min, sin afectar a tus aliados. Bloquea la visión mágica.', '400 por uso'),
    ]),
    PlantillaHabilidad('Campo de vacío', 'Defensa', 'Esfera de oscuridad de la que no sale luz ni sonido; desde fuera nadie ve ni oye lo que pasa dentro', [
      PlantillaNivel(2, 'Esfera de 2 m de radio durante 30 s. Queda fija donde la creas.', '12 por activación'),
      PlantillaNivel(3, 'Esfera de 5 m de radio durante 1 min. Se mueve contigo.', '30 por activación'),
      PlantillaNivel(4, 'Esfera de 10 m de radio durante 3 min. Se mueve contigo.', '60 por activación'),
      PlantillaNivel(5, 'Esfera de 25 m de radio durante 5 min. Se mueve contigo. Quien entre sin permiso queda ciego y sordo.', '120 por activación'),
      PlantillaNivel(6, 'Esfera de 50 m de radio durante 10 min. Se mueve contigo, los intrusos quedan ciegos y sordos, y bloquea la detección mágica.', '220 por activación'),
      PlantillaNivel(7, 'Esfera de 150 m de radio durante 30 min. Se mueve contigo, los intrusos quedan ciegos y sordos, y bloquea la detección mágica.', '400 por activación'),
    ]),
    PlantillaHabilidad('Clon de sombra', 'Apoyo', 'Creas copias de ti hechas de sombra', [
      PlantillaNivel(3, '1 clon durante 1 min. Imita tus movimientos y desaparece con 1 golpe.', '20 por clon'),
      PlantillaNivel(4, '2 clones durante 2 min. Siguen órdenes simples y desaparecen con 1 golpe.', '35 por clon'),
      PlantillaNivel(5, '4 clones durante 3 min. Siguen órdenes, usan armas 2 rangos menores que las tuyas y desaparecen con 1 golpe.', '45 por clon'),
      PlantillaNivel(6, '6 clones durante 5 min. Siguen órdenes, usan armas 2 rangos menores, aguantan 3 golpes y puedes ver por sus ojos.', '60 por clon'),
      PlantillaNivel(7, '10 clones durante 10 min con 30% de tu Fuerza. Siguen órdenes, usan armas 2 rangos menores, aguantan 3 golpes, ves por sus ojos y puedes cambiar de lugar con cualquiera de ellos.', '70 por clon'),
    ]),
    PlantillaHabilidad('Devorar', 'Ataque', 'Tu sombra absorbe la vida del objetivo. El HP robado se suma al tuyo sin pasar tu máximo', [
      PlantillaNivel(4, 'Tocando al objetivo durante 3 s le robas 10% de su HP.', '50 por uso'),
      PlantillaNivel(5, 'A máximo 2 m, en 2 s, le robas 20% de su HP.', '100 por uso'),
      PlantillaNivel(6, 'A máximo 10 m le robas 35% de su HP y 10% de su mana.', '180 por uso'),
      PlantillaNivel(7, 'Hasta 3 objetivos a máximo 20 m, al instante: les robas 50% de su HP y 20% de su mana.', '250 por objetivo'),
    ]),
    PlantillaHabilidad('Soldados de sombra', 'Ataque', 'Invocas soldados de sombra que pelean por ti', [
      PlantillaNivel(5, '3 soldados de rango C durante 3 min.', '200 por invocación'),
      PlantillaNivel(6, '6 soldados de rango B durante 5 min.', '350 por invocación'),
      PlantillaNivel(7, '12 soldados de rango A y 1 capitán de rango S durante 10 min.', '650 por invocación'),
    ]),
    PlantillaHabilidad('Fusión con la sombra', 'Aumento', 'Te fundes con una sombra y los ataques te atraviesan', [
      PlantillaNivel(6, 'Eres intangible 30 s dentro de una sombra. No puedes atacar mientras dura.', '250 por uso'),
      PlantillaNivel(7, 'Eres intangible 3 min. Viajas de sombra en sombra y puedes atacar al salir.', '450 por uso'),
    ]),
    PlantillaHabilidad('Eclipse', 'Ataque', 'Oscuridad total sobre una zona enorme', [
      PlantillaNivel(7, 'Oscuridad total en 500 m de radio durante 10 min. Los enemigos quedan ciegos y tus habilidades de sombra cuestan la mitad de mana.', '900 por uso'),
    ]),
  ]),
  PlantillaMagia('fuego', 'Fuego', [
    PlantillaHabilidad('Bola de fuego', 'Ataque', 'Lanzas bolas de fuego. La distancia es lo más lejos que llegan', [
      PlantillaNivel(0, 'Lanzas 1 bola de fuego que llega a 5 m.', '1 por bola'),
      PlantillaNivel(1, 'Lanzas 1 bola de fuego que llega a 10 m.', '2 por bola'),
      PlantillaNivel(2, 'Lanzas 1 bola de fuego que llega a 20 m y explota en 1 m de radio.', '5 por bola'),
      PlantillaNivel(3, 'Lanzas 3 bolas de fuego que llegan a 30 m y explotan en 2 m de radio.', '7 por bola'),
      PlantillaNivel(4, 'Lanzas 3 bolas de fuego que llegan a 50 m y explotan en 4 m de radio.', '14 por bola'),
      PlantillaNivel(5, 'Lanzas 5 bolas de fuego que llegan a 80 m y explotan en 8 m de radio.', '25 por bola'),
      PlantillaNivel(6, 'Haces caer un meteoro que quema un área de 15 m de radio.', '180 por meteoro'),
      PlantillaNivel(7, 'Lluvia de meteoros sobre un área de 50 m de radio.', '420 por lluvia de meteoros'),
    ]),
    PlantillaHabilidad('Calor corporal', 'Aumento', 'Tu cuerpo genera calor y resistes el frío sin sufrir daño', [
      PlantillaNivel(0, 'Resistes el frío hasta 5 °C.', '1 por hora'),
      PlantillaNivel(1, 'Resistes el frío hasta 0 °C.', '2 por hora'),
      PlantillaNivel(2, 'Resistes el frío hasta −10 °C.', '3 por hora'),
      PlantillaNivel(3, 'Resistes el frío hasta −30 °C. Eres inmune a quemaduras leves.', '5 por hora'),
      PlantillaNivel(4, 'Resistes el frío hasta −50 °C. Eres inmune a quemaduras leves.', '8 por hora'),
      PlantillaNivel(5, 'Pasiva: resistes el frío hasta −50 °C sin gastar mana. Inmune a quemaduras leves.', '0 (pasiva)'),
      PlantillaNivel(6, 'Pasiva: resistes el frío hasta −50 °C e inmune a quemaduras leves. También protege a tus aliados a 5 m.', '0 (pasiva)'),
      PlantillaNivel(7, 'Pasiva: resistes el frío hasta −50 °C e inmune a quemaduras leves. También protege a tus aliados a 20 m.', '0 (pasiva)'),
    ]),
    PlantillaHabilidad('Puño ígneo', 'Aumento', 'Tus golpes queman y hacen más daño', [
      PlantillaNivel(1, '+10% de daño en tus golpes durante 1 min.', '3 por activación'),
      PlantillaNivel(2, '+20% de daño en tus golpes durante 2 min.', '7 por activación'),
      PlantillaNivel(3, '+35% de daño en tus golpes durante 3 min.', '15 por activación'),
      PlantillaNivel(4, '+50% de daño durante 5 min, en tus golpes y en tu arma.', '30 por activación'),
      PlantillaNivel(5, '+75% de daño durante 5 min, en tus golpes y en tu arma.', '60 por activación'),
      PlantillaNivel(6, 'Doble de daño (x2) durante 5 min, en tus golpes y en tu arma.', '110 por activación'),
      PlantillaNivel(7, 'Triple de daño (x3) durante 10 min, en tus golpes y en tu arma.', '200 por activación'),
    ]),
    PlantillaHabilidad('Muro de fuego', 'Defensa', 'Levantas fuego que bloquea el paso y quema a quien lo cruce', [
      PlantillaNivel(2, 'Muro de 3 m de largo durante 30 s.', '8 por muro'),
      PlantillaNivel(3, 'Muro de 10 m de largo durante 1 min.', '20 por muro'),
      PlantillaNivel(4, 'Muro de 20 m de largo durante 2 min.', '40 por muro'),
      PlantillaNivel(5, 'Anillo de fuego de 15 m de radio a tu alrededor durante 3 min.', '90 por anillo'),
      PlantillaNivel(6, 'Anillo de fuego de 30 m de radio durante 5 min.', '170 por anillo'),
      PlantillaNivel(7, 'Anillo de fuego de 100 m de radio durante 10 min.', '320 por anillo'),
    ]),
    PlantillaHabilidad('Explosión', 'Ataque', 'Explosión que sale desde tu cuerpo; no te daña', [
      PlantillaNivel(3, 'Explosión de 3 m de radio.', '25 por explosión'),
      PlantillaNivel(4, 'Explosión de 6 m de radio.', '50 por explosión'),
      PlantillaNivel(5, 'Explosión de 12 m de radio.', '100 por explosión'),
      PlantillaNivel(6, 'Explosión de 25 m de radio.', '180 por explosión'),
      PlantillaNivel(7, 'Explosión de 60 m de radio.', '350 por explosión'),
    ]),
    PlantillaHabilidad('Lanza de fuego', 'Ataque', 'Lanzas lanzas de fuego concentrado que perforan', [
      PlantillaNivel(4, '1 lanza que llega a 50 m y atraviesa madera.', '35 por lanza'),
      PlantillaNivel(5, '3 lanzas que llegan a 100 m y atraviesan metal.', '50 por lanza'),
      PlantillaNivel(6, '1 lanza que llega a 300 m y atraviesa metal.', '160 por lanza'),
      PlantillaNivel(7, '1 lanza que llega a 1 km y atraviesa metal.', '320 por lanza'),
    ]),
    PlantillaHabilidad('Armadura de fuego', 'Defensa', 'Te cubres de fuego: recibes menos daño y quemas a quien te toque', [
      PlantillaNivel(5, 'Recibes 20% menos daño durante 3 min.', '110 por activación'),
      PlantillaNivel(6, 'Recibes 35% menos daño durante 5 min.', '200 por activación'),
      PlantillaNivel(7, 'Recibes 50% menos daño durante 10 min.', '340 por activación'),
    ]),
    PlantillaHabilidad('Renacer', 'Apoyo', 'Se activa sola al llegar a 0 HP', [
      PlantillaNivel(6, 'Revives con 30% de tu HP. Funciona 1 vez al día.', '300 cada vez que te revive'),
      PlantillaNivel(7, 'Revives con 60% de tu HP. Funciona 2 veces al día.', '500 cada vez que te revive'),
    ]),
    PlantillaHabilidad('Sol infernal', 'Ataque', 'Creas un sol en miniatura que lo quema todo', [
      PlantillaNivel(7, 'Esfera de fuego de 200 m de radio.', '900 por uso'),
    ]),
  ]),
  PlantillaMagia('agua', 'Agua', [
    PlantillaHabilidad('Crear agua', 'Apoyo', 'Creas agua potable de la nada', [
      PlantillaNivel(0, 'Creas 1 L de agua potable.', '1 por uso'),
      PlantillaNivel(1, 'Creas 5 L de agua potable.', '1 por uso'),
      PlantillaNivel(2, 'Creas 20 L de agua potable.', '2 por uso'),
      PlantillaNivel(3, 'Creas 100 L de agua potable.', '4 por uso'),
      PlantillaNivel(4, 'Creas 1,000 L de agua potable.', '8 por uso'),
      PlantillaNivel(5, 'Creas 10,000 L de agua potable.', '15 por uso'),
      PlantillaNivel(6, 'Creas 100,000 L de agua potable.', '30 por uso'),
      PlantillaNivel(7, 'Creas 1,000,000 L de agua potable.', '60 por uso'),
    ]),
    PlantillaHabilidad('Látigo de agua', 'Ataque', 'Látigos de agua que golpean; el largo es su alcance', [
      PlantillaNivel(0, '1 látigo de 2 m.', '1 por látigo'),
      PlantillaNivel(1, '1 látigo de 4 m.', '2 por látigo'),
      PlantillaNivel(2, '1 látigo de 6 m que puede sujetar al objetivo.', '4 por látigo'),
      PlantillaNivel(3, '2 látigos de 10 m que pueden sujetar.', '8 por látigo'),
      PlantillaNivel(4, '2 látigos de 15 m que pueden sujetar y cortan madera.', '15 por látigo'),
      PlantillaNivel(5, '4 látigos de 25 m que pueden sujetar y cortan madera.', '20 por látigo'),
      PlantillaNivel(6, '8 látigos de 40 m que pueden sujetar y cortan metal.', '25 por látigo'),
      PlantillaNivel(7, '8 látigos de alta presión de 50 m que pueden sujetar y cortan metal.', '45 por látigo'),
    ]),
    PlantillaHabilidad('Curación', 'Apoyo', 'Recuperas HP. El porcentaje es del HP máximo de quien se cura', [
      PlantillaNivel(1, 'Curas 5% de HP. Solo a ti.', '4 por curación'),
      PlantillaNivel(2, 'Curas 10% de HP. Solo a ti.', '8 por curación'),
      PlantillaNivel(3, 'Curas 20% de HP a ti o a 1 aliado.', '15 por persona curada'),
      PlantillaNivel(4, 'Curas 35% de HP a ti o a 1 aliado y cierras heridas.', '30 por persona curada'),
      PlantillaNivel(5, 'Curas 50% de HP y cierras heridas a todos en un área de 5 m de radio.', '80 por uso en área'),
      PlantillaNivel(6, 'Curas 75% de HP y cierras heridas a todos en un área de 10 m de radio.', '170 por uso en área'),
      PlantillaNivel(7, 'Curas 100% de HP y cierras heridas a todos en un área de 20 m de radio.', '320 por uso en área'),
    ]),
    PlantillaHabilidad('Respiración acuática', 'Aumento', 'Respiras bajo el agua', [
      PlantillaNivel(2, 'Respiras 5 min bajo el agua.', '4 por activación'),
      PlantillaNivel(3, 'Respiras 15 min bajo el agua.', '8 por activación'),
      PlantillaNivel(4, 'Respiras 1 h bajo el agua y nadas al doble de velocidad.', '15 por activación'),
      PlantillaNivel(5, 'Respiras 3 h bajo el agua y nadas al doble de velocidad. También a tus aliados.', '25 por activación + 10 por aliado'),
      PlantillaNivel(6, 'Pasiva: respiras bajo el agua sin límite y nadas al doble de velocidad.', '0 (pasiva)'),
      PlantillaNivel(7, 'Pasiva para ti: respiras sin límite y nadas al doble de velocidad. Dárselo a tus aliados cuesta mana.', '0 para ti (pasiva) + 10 por aliado'),
    ]),
    PlantillaHabilidad('Burbuja protectora', 'Defensa', 'Esfera de agua que absorbe daño hasta romperse', [
      PlantillaNivel(3, 'Esfera de 2 m que absorbe 50 de daño.', '25 por burbuja'),
      PlantillaNivel(4, 'Esfera de 4 m que absorbe 100 de daño.', '50 por burbuja'),
      PlantillaNivel(5, 'Esfera de 8 m que absorbe 250 de daño.', '100 por burbuja'),
      PlantillaNivel(6, 'Esfera de 15 m que absorbe 500 de daño.', '180 por burbuja'),
      PlantillaNivel(7, 'Esfera de 30 m que absorbe 1,000 de daño.', '320 por burbuja'),
    ]),
    PlantillaHabilidad('Prisión de agua', 'Apoyo', 'Encierras al objetivo en agua: queda inmovilizado pero puede respirar', [
      PlantillaNivel(4, 'Inmovilizas a 1 objetivo durante 10 s.', '50 por objetivo'),
      PlantillaNivel(5, 'Inmovilizas hasta 3 objetivos durante 20 s.', '60 por objetivo'),
      PlantillaNivel(6, 'Inmovilizas hasta 5 objetivos durante 30 s.', '70 por objetivo'),
      PlantillaNivel(7, 'Inmovilizas hasta 10 objetivos durante 1 min.', '60 por objetivo'),
    ]),
    PlantillaHabilidad('Ola gigante', 'Ataque', 'Lanzas una ola que arrastra todo a su paso', [
      PlantillaNivel(5, 'Ola de 5 m de alto y 50 m de ancho.', '160 por ola'),
      PlantillaNivel(6, 'Ola de 15 m de alto y 200 m de ancho.', '300 por ola'),
      PlantillaNivel(7, 'Tsunami de 30 m de alto y 1 km de ancho.', '600 por tsunami'),
    ]),
    PlantillaHabilidad('Lluvia sanadora', 'Apoyo', 'Lluvia que cura 5% de HP a tus aliados cada 10 s', [
      PlantillaNivel(6, 'Cubre un área de 100 m de radio durante 3 min.', '320 por uso'),
      PlantillaNivel(7, 'Cubre un área de 500 m de radio durante 10 min.', '650 por uso'),
    ]),
    PlantillaHabilidad('Diluvio', 'Ataque', 'Tormenta que inunda una zona enorme', [
      PlantillaNivel(7, 'Lluvia torrencial e inundación en 1 km de radio durante 10 min.', '900 por uso'),
    ]),
  ]),
  PlantillaMagia('tierra', 'Tierra', [
    PlantillaHabilidad('Piel de piedra', 'Defensa', 'Tu piel se endurece como piedra y recibes menos daño', [
      PlantillaNivel(0, 'Recibes 5% menos daño durante 1 min.', '2 por activación'),
      PlantillaNivel(1, 'Recibes 10% menos daño durante 2 min.', '4 por activación'),
      PlantillaNivel(2, 'Recibes 15% menos daño durante 3 min.', '8 por activación'),
      PlantillaNivel(3, 'Recibes 20% menos daño durante 5 min.', '18 por activación'),
      PlantillaNivel(4, 'Recibes 30% menos daño durante 5 min.', '35 por activación'),
      PlantillaNivel(5, 'Recibes 40% menos daño durante 10 min.', '70 por activación'),
      PlantillaNivel(6, 'Recibes 50% menos daño durante 10 min.', '130 por activación'),
      PlantillaNivel(7, 'Recibes 60% menos daño durante 30 min.', '240 por activación'),
    ]),
    PlantillaHabilidad('Lanzar roca', 'Ataque', 'Arrancas rocas del suelo y las lanzas; la distancia es lo más lejos que llegan', [
      PlantillaNivel(0, 'Lanzas 1 roca de 1 kg que llega a 5 m.', '1 por roca'),
      PlantillaNivel(1, 'Lanzas 1 roca de 3 kg que llega a 10 m.', '2 por roca'),
      PlantillaNivel(2, 'Lanzas 1 roca de 10 kg que llega a 20 m.', '5 por roca'),
      PlantillaNivel(3, 'Lanzas 3 rocas de 30 kg que llegan a 30 m.', '7 por roca'),
      PlantillaNivel(4, 'Lanzas 1 roca de 100 kg que llega a 50 m.', '28 por roca'),
      PlantillaNivel(5, 'Lanzas 10 rocas que llegan a 100 m.', '12 por roca'),
      PlantillaNivel(6, 'Lanzas 1 roca de 5 t que llega a 200 m.', '200 por roca'),
      PlantillaNivel(7, 'Lluvia de rocas sobre un área de 50 m de radio.', '400 por lluvia de rocas'),
    ]),
    PlantillaHabilidad('Pilar de tierra', 'Apoyo', 'Levantas pilares del suelo que te elevan o bloquean el paso', [
      PlantillaNivel(1, '1 pilar de 1 m de alto.', '3 por pilar'),
      PlantillaNivel(2, '1 pilar de 3 m de alto.', '6 por pilar'),
      PlantillaNivel(3, '3 pilares de 6 m de alto.', '8 por pilar'),
      PlantillaNivel(4, '1 pilar de 15 m de alto.', '35 por pilar'),
      PlantillaNivel(5, '1 pilar de 30 m de alto.', '70 por pilar'),
      PlantillaNivel(6, '1 pilar de 80 m de alto.', '130 por pilar'),
      PlantillaNivel(7, '1 torre de 200 m de alto.', '250 por torre'),
    ]),
    PlantillaHabilidad('Sentir vibraciones', 'Apoyo', 'Detectas pasos y movimiento por el suelo; la distancia es el radio que alcanzas a sentir', [
      PlantillaNivel(2, 'Sientes vibraciones hasta 10 m.', '1 por minuto'),
      PlantillaNivel(3, 'Sientes vibraciones hasta 30 m.', '1 por minuto'),
      PlantillaNivel(4, 'Sientes vibraciones hasta 100 m.', '1 por minuto'),
      PlantillaNivel(5, 'Pasiva: sientes vibraciones hasta 100 m sin gastar mana.', '0 (pasiva)'),
      PlantillaNivel(6, 'Pasiva: sientes vibraciones hasta 500 m.', '0 (pasiva)'),
      PlantillaNivel(7, 'Pasiva: sientes vibraciones hasta 2 km.', '0 (pasiva)'),
    ]),
    PlantillaHabilidad('Muro de tierra', 'Defensa', 'Levantas tierra que bloquea ataques; aguanta golpes hasta el rango indicado', [
      PlantillaNivel(3, 'Muro de 3 m que resiste golpes de rango C.', '25 por muro'),
      PlantillaNivel(4, 'Muro de 10 m que resiste golpes de rango B.', '50 por muro'),
      PlantillaNivel(5, 'Domo de 10 m de radio que resiste golpes de rango A.', '100 por domo'),
      PlantillaNivel(6, 'Fortaleza de 30 m que resiste golpes de rango S.', '200 por fortaleza'),
      PlantillaNivel(7, 'Muralla de 200 m que resiste golpes de rango SS.', '380 por muralla'),
    ]),
    PlantillaHabilidad('Temblor', 'Ataque', 'Haces temblar el suelo a tu alrededor', [
      PlantillaNivel(4, 'Temblor de 10 m de radio que derriba personas.', '50 por uso'),
      PlantillaNivel(5, 'Temblor de 30 m de radio que derriba personas y agrieta el suelo.', '110 por uso'),
      PlantillaNivel(6, 'Temblor de 100 m de radio que agrieta el suelo y derrumba casas.', '220 por uso'),
      PlantillaNivel(7, 'Terremoto de 1 km de radio.', '450 por terremoto'),
    ]),
    PlantillaHabilidad('Gólem', 'Ataque', 'Creas gólems de tierra que pelean por ti', [
      PlantillaNivel(5, '1 gólem de 3 m con fuerza de rango B durante 5 min.', '180 por gólem'),
      PlantillaNivel(6, '2 gólems de 3 m con fuerza de rango A durante 10 min.', '160 por gólem'),
      PlantillaNivel(7, '1 gólem de 20 m con fuerza de rango S durante 15 min.', '600 por gólem'),
    ]),
    PlantillaHabilidad('Viaje subterráneo', 'Aumento', 'Te mueves dentro de la tierra como si nadaras', [
      PlantillaNivel(6, 'Avanzas bajo tierra a 20 km/h durante 5 min.', '40 por minuto'),
      PlantillaNivel(7, 'Avanzas bajo tierra a 60 km/h durante 30 min.', '15 por minuto'),
    ]),
    PlantillaHabilidad('Fractura', 'Ataque', 'Partes la tierra en dos', [
      PlantillaNivel(7, 'Grieta de 500 m de largo y 50 m de profundidad.', '900 por uso'),
    ]),
  ]),
  PlantillaMagia('luz', 'Luz', [
    PlantillaHabilidad('Esfera de luz', 'Apoyo', 'Creas esferas que iluminan; la distancia es el radio que alumbran', [
      PlantillaNivel(0, '1 esfera que ilumina 5 m durante 10 min.', '1 por esfera'),
      PlantillaNivel(1, '1 esfera que ilumina 15 m durante 30 min.', '1 por esfera'),
      PlantillaNivel(2, '1 esfera que ilumina 30 m durante 1 h.', '2 por esfera'),
      PlantillaNivel(3, '4 esferas que iluminan 50 m cada una durante 1 h.', '2 por esfera'),
      PlantillaNivel(4, '4 esferas que iluminan 100 m cada una durante 1 h.', '3 por esfera'),
      PlantillaNivel(5, '4 esferas que iluminan 300 m cada una durante 1 h.', '5 por esfera'),
      PlantillaNivel(6, '4 esferas que iluminan 1 km cada una durante 1 h.', '10 por esfera'),
      PlantillaNivel(7, 'Luz de día en 5 km de radio.', '25 por uso'),
    ]),
    PlantillaHabilidad('Rayo de luz', 'Ataque', 'Disparas un rayo de luz; la distancia es su alcance', [
      PlantillaNivel(0, 'Rayo que llega a 5 m.', '1 por rayo'),
      PlantillaNivel(1, 'Rayo que llega a 10 m.', '3 por rayo'),
      PlantillaNivel(2, 'Rayo que llega a 20 m y quema.', '6 por rayo'),
      PlantillaNivel(3, 'Rayo que llega a 40 m y quema.', '14 por rayo'),
      PlantillaNivel(4, 'Rayo que llega a 80 m, quema y perfora madera.', '28 por rayo'),
      PlantillaNivel(5, 'Rayo que llega a 200 m, quema y perfora metal.', '55 por rayo'),
      PlantillaNivel(6, 'Rayo que llega a 500 m, quema y perfora metal.', '100 por rayo'),
      PlantillaNivel(7, 'Rayo que llega a 2 km, quema y perfora metal.', '180 por rayo'),
    ]),
    PlantillaHabilidad('Destello', 'Apoyo', 'Un destello de luz que ciega a los enemigos', [
      PlantillaNivel(1, 'Ciegas a 1 objetivo a máximo 3 m durante 2 s.', '3 por uso'),
      PlantillaNivel(2, 'Ciegas a todos en un área de 5 m durante 3 s.', '8 por uso'),
      PlantillaNivel(3, 'Ciegas a todos en un área de 10 m durante 5 s.', '18 por uso'),
      PlantillaNivel(4, 'Ciegas a todos en un área de 20 m durante 10 s.', '35 por uso'),
      PlantillaNivel(5, 'Ciegas a todos en un área de 40 m durante 20 s.', '70 por uso'),
      PlantillaNivel(6, 'Ciegas a todos en un área de 80 m durante 30 s y anulas las sombras.', '130 por uso'),
      PlantillaNivel(7, 'Ciegas a todos en un área de 200 m durante 1 min y anulas las sombras.', '240 por uso'),
    ]),
    PlantillaHabilidad('Escudo de luz', 'Defensa', 'Escudo de luz que absorbe daño hasta romperse', [
      PlantillaNivel(2, 'Escudo frontal que absorbe 30 de daño.', '8 por escudo'),
      PlantillaNivel(3, 'Escudo frontal que absorbe 80 de daño.', '18 por escudo'),
      PlantillaNivel(4, 'Escudo frontal que absorbe 200 de daño. Puede cubrir a 1 aliado.', '35 por escudo'),
      PlantillaNivel(5, 'Domo de 5 m que absorbe 400 de daño.', '80 por domo'),
      PlantillaNivel(6, 'Domo de 15 m que absorbe 800 de daño.', '150 por domo'),
      PlantillaNivel(7, 'Domo de 30 m que absorbe 2,000 de daño.', '300 por domo'),
    ]),
    PlantillaHabilidad('Purificación', 'Apoyo', 'Limpias venenos, efectos negativos y magia enemiga', [
      PlantillaNivel(3, 'Quitas venenos y efectos leves. Solo a ti.', '15 por uso'),
      PlantillaNivel(4, 'Quitas venenos y efectos leves a ti y a 1 aliado.', '15 por persona'),
      PlantillaNivel(5, 'Quitas venenos y efectos leves a todos en un área de 10 m.', '80 por uso en área'),
      PlantillaNivel(6, 'Quitas venenos y efectos leves, y anulas la magia enemiga de rango B o menor, en un área de 20 m.', '180 por uso en área'),
      PlantillaNivel(7, 'Quitas venenos y efectos leves, y anulas la magia enemiga de rango A o menor, en un área de 50 m.', '350 por uso en área'),
    ]),
    PlantillaHabilidad('Paso de luz', 'Aumento', 'Te teletransportas en línea recta', [
      PlantillaNivel(4, 'Te teletransportas hasta 20 m.', '20 por salto'),
      PlantillaNivel(5, 'Te teletransportas hasta 100 m.', '35 por salto'),
      PlantillaNivel(6, 'Te teletransportas hasta 1 km.', '80 por salto'),
      PlantillaNivel(7, 'Te teletransportas hasta 10 km.', '160 por salto'),
    ]),
    PlantillaHabilidad('Armadura de luz', 'Aumento', 'Te cubres de luz y aumentan tu Fuerza y tu Agilidad', [
      PlantillaNivel(5, '+25% de Fuerza y Agilidad durante 3 min.', '150 por activación'),
      PlantillaNivel(6, '+50% de Fuerza y Agilidad durante 5 min.', '260 por activación'),
      PlantillaNivel(7, 'Doble (x2) de Fuerza y Agilidad durante 10 min.', '450 por activación'),
    ]),
    PlantillaHabilidad('Juicio', 'Ataque', 'Columna de luz que cae del cielo', [
      PlantillaNivel(6, 'Columna de luz de 10 m de radio.', '300 por uso'),
      PlantillaNivel(7, 'Columna de luz de 50 m de radio.', '600 por uso'),
    ]),
    PlantillaHabilidad('Amanecer', 'Apoyo', 'Haces amanecer sobre una zona enorme', [
      PlantillaNivel(7, 'Área de 1 km durante 10 min. Tus aliados curan 10% de HP cada 10 s y la magia de sombra enemiga pierde 50% de fuerza.', '900 por uso'),
    ]),
  ]),
  PlantillaMagia('viento', 'Viento', [
    PlantillaHabilidad('Pasos silenciosos', 'Aumento', 'El aire a tu alrededor apaga el ruido que haces al moverte', [
      PlantillaNivel(0, 'Haces 50% menos ruido al caminar.', '1 por minuto'),
      PlantillaNivel(1, 'Haces 75% menos ruido al caminar.', '1 por minuto'),
      PlantillaNivel(2, 'Silencio total al caminar.', '1 por minuto'),
      PlantillaNivel(3, 'Silencio total al caminar y al correr.', '1 por minuto'),
      PlantillaNivel(4, 'Silencio total al caminar y al correr, y borras tus huellas.', '1 cada 5 minutos'),
      PlantillaNivel(5, 'Pasiva: silencio total al caminar y correr, y borras tus huellas.', '0 (pasiva)'),
      PlantillaNivel(6, 'Pasiva: silencio total al moverte, borras tus huellas y silencias tu ropa y tu respiración.', '0 (pasiva)'),
      PlantillaNivel(7, 'Pasiva: silencio total, sin huellas, ropa ni respiración audibles, para ti y hasta 5 aliados.', '0 (pasiva)'),
    ]),
    PlantillaHabilidad('Amortiguar caída', 'Defensa', 'Un colchón de aire frena tus caídas y no recibes daño', [
      PlantillaNivel(0, 'Caes desde hasta 3 m sin daño.', '1 por caída'),
      PlantillaNivel(1, 'Caes desde hasta 6 m sin daño.', '2 por caída'),
      PlantillaNivel(2, 'Caes desde hasta 15 m sin daño.', '4 por caída'),
      PlantillaNivel(3, 'Caes desde hasta 30 m sin daño, tú y 1 aliado.', '8 por persona'),
      PlantillaNivel(4, 'Caes desde hasta 100 m sin daño, tú y 1 aliado.', '15 por persona'),
      PlantillaNivel(5, 'Caes desde cualquier altura sin daño, tú y 1 aliado.', '25 por persona'),
      PlantillaNivel(6, 'Caes desde cualquier altura sin daño, tú y tus aliados a 10 m.', '60 por uso'),
      PlantillaNivel(7, 'Pasiva para ti: caes desde cualquier altura sin daño. Proteger a tus aliados a 30 m cuesta mana.', '0 para ti (pasiva) + 40 por uso con aliados'),
    ]),
    PlantillaHabilidad('Cuchillas de viento', 'Ataque', 'Cortes invisibles de aire comprimido; la distancia es su alcance', [
      PlantillaNivel(1, '1 cuchilla que llega a 5 m.', '2 por cuchilla'),
      PlantillaNivel(2, '2 cuchillas que llegan a 10 m.', '4 por cuchilla'),
      PlantillaNivel(3, '3 cuchillas que llegan a 20 m.', '6 por cuchilla'),
      PlantillaNivel(4, '5 cuchillas que llegan a 40 m y cortan madera.', '8 por cuchilla'),
      PlantillaNivel(5, '10 cuchillas que llegan a 80 m y cortan metal delgado.', '10 por cuchilla'),
      PlantillaNivel(6, 'Torbellino de cuchillas en un área de 15 m de radio. Cortan metal delgado.', '200 por torbellino'),
      PlantillaNivel(7, 'Torbellino de cuchillas de 40 m de radio, o 1 solo corte que llega a 300 m.', '400 por torbellino o corte'),
    ]),
    PlantillaHabilidad('Velocidad', 'Aumento', 'El viento te empuja y te mueves más rápido', [
      PlantillaNivel(1, '+10% de velocidad durante 30 s.', '3 por activación'),
      PlantillaNivel(2, '+20% de velocidad durante 1 min.', '7 por activación'),
      PlantillaNivel(3, '+35% de velocidad durante 2 min.', '15 por activación'),
      PlantillaNivel(4, '+50% de velocidad durante 3 min.', '30 por activación'),
      PlantillaNivel(5, '+75% de velocidad durante 5 min.', '60 por activación'),
      PlantillaNivel(6, 'Doble de velocidad (x2) durante 5 min.', '110 por activación'),
      PlantillaNivel(7, 'Triple de velocidad (x3) durante 10 min.', '200 por activación'),
    ]),
    PlantillaHabilidad('Planear', 'Apoyo', 'Se usa al saltar desde una altura; la distancia es lo más lejos que llegas', [
      PlantillaNivel(2, 'Planeas hasta 20 m de distancia.', '4 por salto'),
      PlantillaNivel(3, 'Planeas hasta 100 m de distancia.', '8 por salto'),
      PlantillaNivel(4, 'Planeas hasta 500 m y puedes ganar algo de altura.', '15 por salto'),
      PlantillaNivel(5, 'Planeas hasta 2 km y puedes ganar algo de altura.', '25 por salto'),
      PlantillaNivel(6, 'Planeas hasta 10 km y puedes ganar algo de altura.', '45 por salto'),
      PlantillaNivel(7, 'Planeas sin límite de distancia y puedes ganar altura.', '2 por minuto'),
    ]),
    PlantillaHabilidad('Barrera de viento', 'Defensa', 'Desvía flechas, piedras y otros proyectiles', [
      PlantillaNivel(3, 'Muro de viento de 3 m durante 1 min. Desvía proyectiles ligeros.', '25 por barrera'),
      PlantillaNivel(4, 'Muro de viento de 6 m durante 2 min. Desvía proyectiles ligeros y medianos.', '50 por barrera'),
      PlantillaNivel(5, 'Cúpula de viento de 10 m de radio durante 3 min. Desvía proyectiles ligeros y medianos.', '100 por cúpula'),
      PlantillaNivel(6, 'Cúpula de 30 m de radio durante 5 min. Desvía proyectiles y los regresa a quien los lanzó.', '180 por cúpula'),
      PlantillaNivel(7, 'Cúpula de 100 m de radio durante 10 min. Desvía proyectiles y los regresa a quien los lanzó.', '350 por cúpula'),
    ]),
    PlantillaHabilidad('Volar', 'Apoyo', 'Vuelas sostenido por el viento; la altura y la velocidad son las máximas', [
      PlantillaNivel(4, 'Vuelas hasta 10 m de altura a 20 km/h.', '8 por minuto'),
      PlantillaNivel(5, 'Vuelas hasta 50 m de altura a 40 km/h.', '10 por minuto'),
      PlantillaNivel(6, 'Vuelas hasta 200 m de altura a 80 km/h y cargas a 1 persona.', '15 por minuto + 5 por persona cargada'),
      PlantillaNivel(7, 'Vuelas hasta 1,000 m de altura a 150 km/h y cargas hasta 3 personas.', '20 por minuto + 5 por persona cargada'),
    ]),
    PlantillaHabilidad('Tornado', 'Ataque', 'Creas tornados que arrastran lo que tocan', [
      PlantillaNivel(5, '1 tornado de 10 m durante 1 min. Arrastra personas.', '160 por tornado'),
      PlantillaNivel(6, '1 tornado de 30 m durante 3 min. Arrastra personas y autos.', '320 por tornado'),
      PlantillaNivel(7, '3 tornados de 50 m durante 5 min. Arrastran personas y autos.', '250 por tornado'),
    ]),
    PlantillaHabilidad('Forma de viento', 'Aumento', 'Tu cuerpo se vuelve aire: los ataques físicos te atraviesan', [
      PlantillaNivel(6, 'Eres aire durante 1 min y vuelas a 200 km/h.', '200 por minuto'),
      PlantillaNivel(7, 'Eres aire durante 5 min y vuelas a 300 km/h.', '90 por minuto'),
    ]),
    PlantillaHabilidad('Tempestad', 'Ataque', 'Tormenta de viento sobre una zona enorme', [
      PlantillaNivel(7, 'Vientos huracanados en 1 km de radio durante 10 min.', '900 por uso'),
    ]),
  ]),
];
