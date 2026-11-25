# Creditos

## Animaciones mocap de golpes (Derecha, Reves, Servicio, Smash)

Las animaciones de golpes derivan de tomas del dataset **Tennis-MoCap**
(https://github.com/jdpulgarin/Tennis-MoCap), licenciado bajo
**Creative Commons Atribucion-CompartirIgual 3.0 Unported (CC BY-SA 3.0)**
(https://creativecommons.org/licenses/by-sa/3.0/), segun consta en el
archivo Copyright.md de dicho repositorio.

Mantenedor del dataset: Juan Diego Pulgarin-Giraldo (Universidad Autonoma de
Occidente, Colombia). Citacion solicitada por los autores:

Pulgarin-Giraldo J.D., Alvarez-Meza A.M., Melo-Betancourt L.G.,
Ramos-Bermudez S., Castellanos-Dominguez G. "A Similarity Indicator for
Differentiating Kinematic Performance Between Qualified Tennis Players."
Lecture Notes in Computer Science 10125, pp. 309-317, 2017.
https://doi.org/10.1007/978-3-319-52277-7_38

Las tomas BVH originales fueron re-segmentadas y retargeteadas al esqueleto
del personaje del juego (adaptacion). La toma de saque actual deriva de
`data/cferrero_Servicio.bvh` (9.96-12.36 s). De acuerdo con la condicion CompartirIgual,
estas animaciones derivadas se distribuyen bajo la misma licencia
CC BY-SA 3.0.

En la alternativa experimental de articulacion se vuelven a adaptar
`data/cferrero_Servicio.bvh` (9.96-12.36 s),
`data/adorozco_Derecha.bvh` (19.0-21.4 s) y
`data/adorozco_Reves_14seg.bvh` (1.7-4.1 s), usando el bind y la jerarquia
del personaje actual. Las tres animaciones derivadas nuevas conservan
CC BY-SA 3.0; no cambian la licencia de las tomas ni su atribucion.

Las voleas usan tomas dedicadas del mismo dataset:
`data/jduribe_VDerecha.bvh` (11.4-13.0 s) y `data/jduribe_VReves.bvh`
(2.1-3.7 s), retargeteadas con la misma tecnica. Ambas animaciones
derivadas conservan CC BY-SA 3.0; no cambian la licencia de las tomas
ni su atribucion.

## Cuerpos de los jugadores (MakeHuman)

Los cuerpos 3D de los jugadores son modelos **MakeHuman** (mallas, ropa y
texturas CC0), exportados por el proyecto **char-kit**
(https://github.com/MMWilliams/char-kit) y adaptados al rig y a las
animaciones de este juego. MakeHuman: https://static.makehumancommunity.org/
(CC0). Los clips de animación propios de char-kit no se usan en el juego.
