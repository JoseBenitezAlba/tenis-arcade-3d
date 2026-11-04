# Tenis Arcade 3D

Juego de tenis arcade estilo Virtua Tennis 3, hecho en Godot 4.7. Controles con mando y teclado, modo carrera con 10 torneos, superficies (tierra, dura, hierba) y partidos de dia y de noche.

## Ejecutar (Windows)
Descomprime y ejecuta `TenisArcade3D.exe`.

## Controles
- Mover: stick izquierdo / WASD o flechas
- Golpe: boton A / ESPACIO o J (manten para cargar; la direccion gana amplitud con la carga)
- Globo: boton X / tecla Z o K
- Dejada/slice: boton B / tecla SHIFT (dejada cerca de la red, slice desde el fondo)
- Saque: mismo boton de golpe, pulsado dos veces (lanzamiento y golpeo); la direccion coloca el saque
- Pausa: Start / tecla P. Salir del partido: Back / ESC

## Modos
- Partido rapido: superficie, dificultad, sets y dia/noche a elegir.
- Carrera: crea tu jugador y juega una temporada de 10 torneos con ranking, superficie y dia/noche segun el torneo.

## Fuente
Proyecto Godot 4.7. Abrir `project.godot` con el editor Godot 4.7+.
Todos los assets son procedurales (generados por codigo) o CC0; sin costes ni licencias.
Los nombres del roster son un tributo, sin semejanza con jugadores reales.

## Builds de verificacion
- `build/windows/TenisArcade3D.exe` (portable, pck embebido)
- `build/web/` (HTML5, renderer Compatibility)
