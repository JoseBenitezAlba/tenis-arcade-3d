# Prueba de articulacion de jugadores

Estado: alternativa local experimental. No lista para incorporar ni publicar.

Se conservan el personaje, la simulacion, la pista, el publico y las reglas.
El objetivo sigue siendo movimiento humano de cuerpo completo jugando al tenis.
Las pruebas de longitudes y de contacto no demuestran naturalidad.

## Tomas y licencia

Se ha vuelto a comprobar Copyright.md de Tennis-MoCap:
https://github.com/jdpulgarin/Tennis-MoCap/blob/main/Copyright.md
CC BY-SA 3.0. La atribucion y cita permanecen en CREDITS.md.

Tomas de esta alternativa:
- Saque V12: data/cferrero_Servicio.bvh, 9.96 a 12.36 segundos.
- Derecha: data/adorozco_Derecha.bvh, 19.0 a 21.4 segundos.
- Reves: data/adorozco_Reves_14seg.bvh, 1.7 a 4.1 segundos.

La transferencia usa el bind y la jerarquia exportados del personaje real.
Los pies del personaje son hijos de Root, no de las espinillas. Los zapatos
se reconstruyen con el enlace de bind desde la espinilla. V14 prueba una correccion proporcional explicita del rig y piel descrita abajo.
No se alargan articulaciones durante el IK de los golpes.

## Reproduccion de las animaciones

Se requiere Python con numpy y scipy. Las tomas originales se descargan
por separado del repositorio citado; no estan incluidas aqui.

```sh
godot --headless --path . --script tools/export_player_rig.gd -- /tmp/player-rig.json
python tools/retarget_player_bvh.py /ruta/cferrero_Servicio.bvh 9.96 Servicio /tmp/player-rig.json /tmp/serve.tres 2.4
python tools/retarget_player_bvh.py /ruta/adorozco_Derecha.bvh 19 Derecha /tmp/player-rig.json /tmp/forehand.tres 2.4
python tools/retarget_player_bvh.py /ruta/adorozco_Reves_14seg.bvh 1.7 Reves /tmp/player-rig.json /tmp/backhand.tres 2.4
```

Los tres resultados corresponden respectivamente a
models/serve_actual_experiment.tres, models/actual_Derecha.tres y
models/actual_Reves.tres. El nombre provisional senala su estado.

## Pruebas

```sh
godot --headless --path . --script tests/contact_chain_test.gd
godot --headless --path . --script tests/contact_match_metrics.gd
xvfb-run -a godot --path . --audio-driver Dummy --rendering-method gl_compatibility --resolution 640x360 --script tests/players_match_close_short.gd -- out=/tmp/players-near
xvfb-run -a godot --path . --audio-driver Dummy --rendering-method gl_compatibility --resolution 640x360 --script tests/players_match_close_short.gd -- out=/tmp/players-far far
```

La camara sigue al jugador para revisar anatomia, agarre, apoyo y gesto en
partido real; no representa la camara normal de juego. Las capturas se
producen cada tres pasos de simulacion, a 60 pasos por segundo.

## Pendiente

- Fijacion y liberacion de los apoyos durante desplazamientos y golpes.
- Preparacion antes del contacto, sin regresar al clip de carrera en el hueco
  entre el fin del temporizador de peticion y la llegada real de la pelota.
- Orientacion continua del cuerpo y contacto en bolas que quedan detras.
- Mano izquierda y agarre del reves; actualmente queda abierta y separada.
- Raqueta/pelota durante el saque y transicion desde el lanzamiento.
- Instantaneas de repeticion para los nuevos objetivos de contacto.
- Comprobar Web, movil, rendimiento en GPU y avisos de liberacion al salir.

El codigo conserva helpers de pruebas anteriores que no son la ruta activa.
No mezclar esta alternativa con parches anteriores: ya los contiene y los
sustituye parcialmente. No se ha creado commit, PR, merge o publicacion.

## Revision local V9 (14 noviembre, 01:56)

La aproximacion visual se calcula con velocidad relativa pelota-jugador.
No se usa want_t como reloj: prep_k cae mientras want_t esta activo.
Se anticipa el objetivo del brazo durante los ultimos 0.25 s. El tronco
puede inclinarse desde el abdomen cuando el alcance de brazo y raqueta no
basta. El reves aproxima la mano izquierda al mango y flexiona sus dedos.
La recuperacion del golpe dura 0.65 s, separada del swing de simulacion.

La animacion de saque usa el instante cpu_serve_at para terminar el
lanzamiento visual. El seguimiento avanza en segundos reales desde tau
1.60; no usa el antiguo reloj de 0.4 s para un swing real de 0.24 s.
La simulacion no ha cambiado. Sigue habiendo desfase espacial en el saque:
la CPU espera a que baje la pelota y lanza desde unos 2 m, por debajo de la
raqueta extendida. No se ha ocultado ese desfase moviendo la pelota.

Comprobado: las tres tomas se reproducen byte por byte con el generador.
La prueba de cadenas pasa, pero no cubre todos los contactos y hay que
ampliarla. Los cuatro contactos registrados son 0/0/1/9 cm, no prueba de
naturalidad ni de agarre perfecto. Se inspeccionaron los 25 tiles de las
trayectorias cerca/lejos, y 25 tiles del saque ampliado 153-180. Hay gestos
rigidos, manos compactas y deslizamiento. No se aprueba la alternativa.

Hallazgo importante: e.swing tambien representa intentos fallidos de la
CPU (sim.gd, rama de fallo aleatorio). En la secuencia 370-393 hay un
intento fallido y a 394 un contacto registrado, no un unico golpe mal
sincronizado. Conservar esta distincion al interpretar pruebas.

La captura grafica obtiene todos los fotogramas pero el lanzador avisa de
procesos hijos pendientes al terminar; no equivale a salida limpia.
Las metricas headless siguen avisando de 21 objetos y un recurso en uso.
No hay prueba nueva de Web, movil, repeticion ni rendimiento de GPU.

## Revision local V10 (14 noviembre, 02:09)

Se recupera el desplazamiento horizontal de cadera de las dos tomas de
suelo. El generador anterior retenia rotacion y altura, pero descartaba
la traslacion lateral y longitudinal del cuerpo (rangos de 27-50 cm en
estas ventanas). No se cambia la posicion de simulacion, la pelota ni
los intentos fallidos de CPU.

El ajuste de contacto conserva la direccion de raqueta y el plano de codo
de la toma hasta donde permite el alcance. Solo gira la raqueta hacia la
pelota el angulo minimo necesario. Antes se alineaba siempre el mango con
la linea hombro-pelota, borrando la flexion del golpe. Se reinicia tambien
el peso de la capa al entrar para que no conserve valores inactivos.

La prueba ampliada pasa 36 casos con contacto registrado, 70 fotogramas
y cuatro extremidades. Los cuatro contactos reales de la secuencia fija
quedan a menos de 0.003 mm en esta revision. Esto NO demuestra naturalidad.
Las dos secuencias de 8 s se inspeccionaron en montajes de 25 fotogramas,
ademas del reves cercano 420 y lejano 396 a resolucion completa. El reves
cercano sigue demasiado alto/compacto y quedan deslizamientos y cambios de
apoyo poco convincentes. No se aprueba ni publica V10.

Descartados: duplicar frecuencia de la toma de saque no cambio el error
espacial; anclar pies en la prueba local no demostro una mejora del conjunto;
traspasar el giro completo de los huesos fuente tampoco. Ninguna de esas
tres pruebas forma parte de V10. El saque mantiene la toma V9 exacta.

Continuan pendientes saque espacial, agarre izquierdo, continuidad de
apoyos, repeticion, Web, movil, rendimiento y salida limpia del proceso.

## Revision local V11 (14 noviembre, 02:19)

Los tobillos de suelo conservan ahora el cambio de orientacion de la toma
respecto al inicio, en lugar de llevar todos los zapatos planos. El saque
se excluye expresamente de traslacion horizontal y de este cambio. Las
tres bibliotecas se han regenerado y comparado byte por byte. Esto corrige
tambien una omision del generador V10: su recurso de saque era V9 exacto,
pero ejecutar el generador V10 podia producir otra traslacion horizontal.

Se mide la suela real a partir de vertices con peso 1 en cada hueso de pie,
no solo la altura del origen del tobillo. La cota de suelo se calcula con
esos puntos transformados, incluyendo la rotacion del zapato. Ademas se
elimina progresivamente el salto heredado de la zancada al sustituirla por
el golpe completo. Ese salto de carrera permanecia activo bajo el golpe
y elevaba ambos pies hasta 9 cm en la secuencia de prueba.

Prueba nueva: 840 pasos del partido fijo, ambos jugadores, 242 muestras con
capa completa, minimo de 116 vertices por pie. El punto mas bajo queda a
4 mm del suelo en todas esas muestras; prueba automatica pasa. No demuestra
inmovilidad horizontal del apoyo ni naturalidad del movimiento. Las pruebas
de 36 contactos y cuatro contactos reales siguen pasando. Se inspeccionaron
25 tiles de cerca, lejos y la camara normal (8 s cada secuencia), mas tres
primeros planos de pies. Sigue habiendo reves compacto, deslizamiento y
agarre izquierdo mejorable. No se aprueba ni publica V11.

La prueba de cambiar el agachamiento por una pose erguida generaba pies
cerrados y rigidez; la nueva orientacion de mano izquierda no demostraba
mejora. Ambas se han descartado. No forman parte de V11. Persisten los
avisos de liberacion del proceso y no hay validacion Web/movil/GPU.

## Revision local V12 (14 noviembre, 02:42)

Tras las dos referencias explicitas de saque de Jose se compara la extension
real de las tomas, no se intenta conseguirla estirando huesos. La toma
jduribe elegida antes no contiene un brazo recto elevado en su contacto
1.60. Se examinan las 15 tomas disponibles. Se conserva alternativa adorozco
sin incorporarla, y se selecciona cferrero_Servicio, ventana 9.96-12.36 s:
la fuente en 11.56 s tiene codo derecho doblado 9.2 grados y mano elevada.
El cuerpo y la raqueta se estiran por encima de la cabeza en el partido.

Fuente y licencia comprobadas otra vez:
https://github.com/jdpulgarin/Tennis-MoCap/blob/main/data/cferrero_Servicio.bvh
https://github.com/jdpulgarin/Tennis-MoCap/blob/main/Copyright.md
La atribucion se actualiza y el generador V11 reproduce el recurso nuevo
byte por byte. No se cambia el generador ni sim.gd. Cadenas de 36 contactos,
cuatro contactos reales y suelas de 840 pasos siguen pasando.

La captura se inspecciona en los 25 tiles de 4 segundos de cerca y lejos,
con saque de cada lado. El test far cambia solo servidor inicial de la
prueba, no el juego. Se inspecciona tambien la extension a tamano completo.
NO es un saque resuelto: pelota y raqueta siguen separados en el lanzamiento,
la recuperacion necesita revision y no se ha validado Web/movil/GPU/replay
ni salida limpia. El reves a dos manos es preferencia explicita pendiente;
los ensayos de agarre/torso rechazados NO forman parte de V12.

## Revision local V14 (14 noviembre, 02:58)

Alternativa, NO version aprobada ni lista para PR. Se conserva V12 por separado.

Hallazgos de proporcion y orientacion:
- El rig original tiene brazo superior de 0.181908 m y antebrazo de 0.235280 m.
  La mano original tiene unos 0.23 m hasta la punta, pero la derecha ya habia
  sido sustituida por un puno menor. Esa asimetria reducia el alcance de la
  izquierda y daba una mano mucho mas grande que la derecha.
- El angulo de referencia del reves era -0.84 rad. El punto de raqueta del
  clip de reves transferido da +0.791 rad en el nuevo contacto: el signo
  anterior giraba el cuerpo al lado contrario y dejaba la mano izquierda
  a unos 20-33 cm del mango en el ensayo. Se cambia la referencia a +0.84.

Ensayo proporcional, comun a ambos jugadores:
- Brazo superior 0.28 m y antebrazo 0.25 m en bind/rest, geometria y pistas
  posicionales de las animaciones. No es un estiramiento en cada golpe.
  La piel se redistribuye con sus pesos y se duplican los recursos que
  se mutan para no acumular el cambio entre las dos instancias.
- Mano izquierda abierta y cerrada procedurales, con proporcion de palma
  y dedos correspondiente al puno derecho. La mano original se separa de
  la malla para ocultarla, sin amputar el resto del personaje. Un enlace
  de muneca une antebrazo y mano durante carrera y golpe.
- El generador toma la separacion derecha-izquierda de la fuente como eje
  del mango de reves, en lugar de confundirlo con la direccion del antebrazo.
- Contacto de reves a tau 0.77, con busqueda de orientacion alcanzable por
  ambos brazos y recuperacion de la toma. La izquierda se cierra sobre
  el mango solo cuando su centro esta a menos de 2.5 cm del objetivo;
  no se simula un agarre pegando la mano a una raqueta fuera de alcance.
  La busqueda discreta todavia puede causar cambios de orientacion.

Las tres animaciones se regeneran exportando ESTE rig modificado con
export_player_rig.gd. Comprobado byte por byte con una nueva exportacion.
Los comandos de arriba sirven con esa exportacion, no con el rig V11/V12.

Pruebas repetidas: 36 casos x70 fotogramas x4 extremidades conservan las
longitudes NUEVAS (PASS). Cuatro contactos reales <0.003 mm (PASS), 242
muestras de suela a4mm (PASS). En los dos reveses reales registrados,
centro de agarre izquierdo-mango <0.001 mm y raqueta-bola <0.003 mm.
137 muestras muestran mano cerrada: separacion maxima 19.94 mm. Esto no
es una prueba de calidad visual o de naturalidad, ni cubre todo el juego.

Capturas: ciclo de8s, 160 imagenes a60 pasos/s con captura cada3 pasos,
para cada jugador, camara de auditoria; los25 tiles de ambas trayectorias
inspeccionados. Los tests hand_unoccluded_capture ocultan bola/trail/flash
solo durante la inspeccion, no modifican produccion ni simulacion. Otros
efectos de contacto pueden seguir visibles. Inspeccionadas capturas de
contacto y recuperacion a tamaño completo, ademas del ciclo de saque.

Persisten: deslizamiento y cambios de apoyo, encogimiento/guardia alta en
algunos reveses altos, transiciones abruptas al abrir/cerrar y orientar la
raqueta, desfase espacial del saque. No aprobar el gesto completo por
las metricas de contacto. Falta validar rendimiento de la busqueda, GPU,
Web/movil/replay y salida limpia (avisos ObjectDB/recurso y lanzador xvfb).
La simulacion no cambia y no se ocultan errores de CPU. Sin commit/push,
PR, merge ni publicacion.

## Revision local V16, separada de simulacion (14 noviembre03:10)

No aprobada ni lista para PR. Se preserva V14 por separado.
- Correccion visual del lado de intento sin contacto: no reutiliza fore
  heredado para un reves entrante; no se elimina el intento fallido de CPU.
- Apoyo real corto tras evento hit: mantiene un tobillo mundial80ms,
  libera hasta160ms o antes si no alcanza. Longitudes conservadas y suelas
  a4mm; hay deslizamiento durante liberacion y no prueba naturalidad.
- Registro del evento serve antes del avance balistico. IK de brazo y
  orientacion hacia su punto exacto; no hacia la bola ya lanzada del frame.
- Paso visual de35cm anticipado en ultimo28% de toss, misma distancia que
  ya cambia la simulacion al sacar. Elevacion necesaria para alcanzar sin
  estirar, hasta24cm, anticipada por contacto previsto y liberada tras golpe.

Parche sim V16 APARTE: toss parte de1.25m, velocidad5.85m/s y gravedad9.8
solo durante toss (antes10.5m/s y gravedad23..30 segun spin anterior).
Bola en mano y toss usan+/-0.28m segun lado, en lugar de+0.28 para ambos.
No se cambian launch, velocidades de servicio, reglas, fallosCPU ni redes.
Este cambio afecta la trayectoria de toss y la ventana util de toque y
la altura de salida del saque. No es un arreglo puramente de animacion.
Hay que probar extremos de toque humano, let, doble falta y replay antes
aceptarlo. No debe mezclarse con un informe que diga sim intacta.

Medido en dos primeros saques registrados de lados opuestos:
near altura2.7613m, error0.00000034m, codo23.95grados;
far altura2.8749m, error0.00000119m, codo22.71grados.
La separacion con bola del frame ya en vuelo es44/86cm por avance de
la simulacion, no el punto registrado de impacto. No ocultarla al informar.
Los tests nuevos comprueban punto exacto y codo. La nueva auditoria de
las4cadenas durante200pasos FALLO en espera/saque, pendiente diagnostico.
Inspeccionados25tiles de ambos ciclos4s y contacto a tamano completo:
extension arriba conseguida en estos ejemplos, no gesto completo aprobado.
Recuperacion, ritmo/continuidad, apoyos, toque humano y replay pendientes.

Auditoria240s semilla42117: sim original106golpes/24puntos, sim modificada
141golpes/22puntos, con seis tipos de golpe en ambas. No es equivalencia:
el cambio de altura/toss cambia los rallies. No se han quitado fallos ni
alterado IA; falta auditoria de reglas y estadistica de regresion.
Sin commit/push/PR/merge/publicacion. V16 requiere sus dos parches, uno
visual completo y otro sim pequeño; V14 sigue alternativa sin sim.

## V18 local, 14 noviembre 03:42 (sustituye pendientes V16 donde se indica)

Candidato, no aprobado para integrar. No hay commit, push, PR nuevo ni publicacion.
Se mantienen V14/V16 y las dos variantes de simulacion por separado.

Visual V17/V18:
- Espera del saque conserva rodilla relativa a cadera al mezclar. El error
  anterior de acortamiento de 1,41 mm queda corregido. Auditoria 200 pasos,
  cuatro cadenas, ambos lados: PASS, maximo near0,0124mm/far0,0453mm.
- Anticipacion de extension durante toss entre0,38/0,72; golpe humano usa
  referencia temporal0,42. Sigue gesto completo y recupera tras fallo en0,3s.
- Reves alto: ajuste de tronco maximo12cm hacia el deficit del agarre con
  piernas articuladas y pies conservados antes de recalcular ambas manos.
  Corrige error4,5cm en contacto784. No prueba una guardia alta natural.
- Smash reutiliza pose extendida Servicio y contacto registrado. Entrada
  inmediata a su clip evita retener carrera50ms justo en el contacto.
- Repeticion conserva pose final de ambos cuerpos, manos, raqueta y bola
  sostenida, no intenta reconstruirla de un resumen incompleto. Prueba8
  frames/todos los huesosPASS. Pares visuales de7estados inspeccionados:
  mismas posturas; NO efectos/HUD equivalentes. El primer test pixel vacio
  tenia plano near16 al restaurar camara; corregido el test a0,05/fov40.
  Falta validar toda la reproduccion y sus transiciones; no se activa una
  repeticion que la version base no iniciaba automaticamente.

Sim V17, APARTE: incluye toss V16 y altura minima2,75m en ambos controles
humanos (antes1,25). Ventana util observada~0,38..0,81s. Cambia jugabilidad.
No modifica calculo antiguo de calidad. Prueba10timings: aceptados0,383..0,767;
los validos mantienen codo<28grados. Muy pronto/tarde falta. Paso maximo
medido de cabeza al impacto8,3cm en esos casos, no prueba suavidad completa.

Sim V18, incremental y APARTE: solo condicion de contacto AI/demo. Alcance
radial y altura con centro1,35m, tolerancia vertical0,20m, radio1,35m/1,65dive.
Antes rectangulo permitia volea a2,40m horizontal. Sin este candidato, en30s
hay dos fallos visuales irreales: lob34cm y volea1,16m. No se estira rig para
maquillarlos. No cambia asistencia humana ni probabilidad de fallo aleatorio.
Auditoria240s semilla42117: original106golpes24puntos; V17toss141/22;
V18toss+limite162/18. Rallies MAS largos en esta muestra, dificultad distinta.
No es equivalencia estadistica ni se afirma mas fallos. Seis tipos en cada una.

Actual30s:16contactos reales incluyendo smash, error maximo0,0021mm;
cuatro cadenas de extremidades maximo0,29mm, ninguna>1mm. Suelas228muestras
4mmPASS. Reglas doble falta ambos lados, token duplicado sin falta extra,
let ambos lados y ventana humanaPASS. TouchScreenButton nativo sintetico
saque/golpe/camara/pausa/reanudarPASS; no telefono fisico.

Web: exportacion release local sin errores de parseo. Chromium WebGL2 con
SwiftShader ejecuta menus y partido; capturas inspeccionadas de ambos
jugadores y falta por saque sin contacto. Dos intentos de auditoria tardaron
mucho en terminar captura/cerrar navegador. Console sin PAGEERROR; physics
5,6/7ms en esas dos muestras, fps1 reportado. NO afirmar fluidez Web/GPU ni
medida movil. No se ha publicado exportacion ni modificado pagina publica.

Ciclo remate completo39imagenes1020..1134, 25tiles inspeccionados y contacto
1065en grande con encuadre entero. Sigue pendiente juicio de naturalidad:
apoyos/deslizamiento, guardia alta en revés, transiciones y rendimiento del
buscador discreto de agarre, GPU/movil, efectos de replay y avisos salida.
Las metricas y estos fotogramas no cumplen por si solos el objetivo completo.

## V27 local, 14 noviembre04:00, continuidad (no aprobado para integrar)

V18 permanece empaquetado por separado. Actual V27 requiere los mismos
parches SIM V17 y candidato V18; ninguna nueva mutacion de simulacion.

Hallazgos de ciclo, no solo contactos:
- V18/V20 en preparacion elegia revés/derecha segun bola aun lejos y podia
  cambiar de clip en un fotograma. V25 predice llegada y fija lado de esa
  preparacion. Al bote no retrocede la fase y filtra solo la estimacion.
  Prediccion visual corta con gravedad/bote, aproximada (no incorpora todos
  los efectos Magnus/slice de la simulacion). No cambia pelota ni decisionesAI.
- La liberacion mezclaba dos veces posicion/orientacion. V25 mezcla primero
  el objetivo geométrico y resuelve luego articulaciones. Siguen velocidades
  de raqueta altas: maxima recuperacion derecha1,13m/frame antes,0,42m/frame
  ahora; reves0,82a0,51m/frame, muestra30s. No equivale a fluidez o naturalidad.
- V19 deja de forzar el punto viejo en recuperacion y V20 da paso sobre la
  cabeza. Antes distancia minima centro raqueta-hueso cabeza4,9cm/9,04cm;
  ahora~34cm en esos dos reveses. No prueba colision completa aro/mango/cabeza.
- V27 anticipa apoyo de un pie al ultimo120ms de llegada, no rearma un apoyo
  que ya esta vivo al golpear; fija hasta140ms y libera hasta240ms, antes si
  no alcanza la pierna. No alarga huesos ni fija ambos pies artificialmente.
 30s:129frames anclados,25anclajes, error mundial maximo0,004mm. Esto mide
  el pie elegido, no que toda la locomocion sea natural o sin deslizamiento.

V25 ampliado240s en MatchView real:87contactos no-saque, los seis tipos
(67drive,6lob,5slice,4drop,3smash,2volley), maximo0,0024mm; cadenas todas
<1mm, maximo0,264mm. No comparar su cuenta87 con162 del auditSIM anterior:
MatchView consume aleatoriedad para efectos y recorre otra secuencia.
V27 repetido240s:87contactos max0,0024mm/cadenas0,279mmPASS;
pies245muestras4mmPASS en30s.
Reglas, ventana humana10timings, cadenas36casos, contacto/extension de saque
ambos lados y replay8poses repetidosPASS enV25. Saque no cambia enV27.

Replay real: se invoca start/tick/end existentes en prueba,67capturas y
error de pose despues de render0.0 para ambos actores; termina y vuelve al
partido.30tiles y retorno inspeccionados. No se activa automaticamente una
funcion que la base no disparaba. Efectos/HUD no tienen paridad con live.

Inspeccion V24:50tiles de20s por jugador (200frames capturados cada6pasos).
V25:33/25frames densos de las zonas812/836/1098 inspeccionados todos; fallo
CPU sigue visible. V27:33frames zona790..854 y35 del revés alto inspeccionados.
Se conservan variantes V18,V20,V21,V22,V23,V24,V25,V26,V27, incluida V26 de
penalizacion temporal del buscador: NO adoptada, no mejoraba metrica.

Pendientes: calidad completa de ritmo/apoyo, guardias altas en revés,
velocidades y cambios de encuadre/paso, Web V27 y GPU/movil reales. No se
presenta este candidato como movimiento humano convincente ya conseguido.
Salida nativa sigue con avisos ObjectDB/recursos en algunas pruebas y xvfb
hijos al terminar; no salida limpia ni rendimiento real garantizados.

Comandos reproducibles adicionales:
 godot --headless --path . --script tests/contact_long_metrics.gd -- seconds=240
 godot --headless --path . --script tests/stroke_continuity_metrics.gd
 godot --headless --path . --script tests/support_stability_metrics.gd
 godot --path . --rendering-method gl_compatibility --script tests/replay_runtime_capture.gd

## V29 local, 14 noviembre04:19, recorrido cercano a la cabeza

La distancia centro-de-raqueta/hueso-cabeza de V27 no era una prueba de
colision: el mango y el aro podian entrar aunque su centro quedase lejos.
Se conserva V27, pero este candidato sustituye esa elevacion artificial por
una correccion usando limites de la piel de la cabeza. Recuperacion a dos
manos desplaza la trayectoria fuera de una envolvente elipsoidal; derecha
cercana cambia orientacion conservando el centro de cuerdas sobre la bola.
No cambia simulacion, alcance AI ni longitudes de huesos.

Prueba determinista1800frames de V27:154 intersecciones aproximadas, todas
reves. V28 eliminaba esas, pero ampliar a14400frames encontro5 derechas.
V29:14400frames/240s, cero intersecciones con esa envolvente y muestreo de
mango/superficie del aro. Esto NO prueba colision exacta de cada triangulo,
cuello, torso, pelo, manos o raqueta. Inspeccionados antes/despues1531,2752,
10018: el reves ya no pasa por la frente, pero sigue demasiado cercano al
cuello/hombro, y la derecha alta queda forzada. No declarar movimiento
natural ni el conjunto terminado por este resultado.

Repeticion V29:87contactos no-saque240s, maximo0,0024mm, cadenas0,279mm,
ninguna>1mm. Recuperacion reves salto maximo0,285m/frame en muestra30s,
ante0,510m/frameV27; otras transiciones siguen altas. Medicion no prueba
fluidez. Capturas antes/despues reproducen simulacion/camara iguales.

Web V27 local: navegacion tactil menus->partido->pausa verificada en imagen
844x390 emulada, sin PAGEERROR. No es telefono fisico ni prueba de GPU.
Un segundo intento de ampliar a reanudar/camara/golpe excedio40s: no se
consideran verificados esos controles. Sin exportacion publicada.

Comandos adicionales:
 godot --headless --path . --script tests/head_racket_clearance.gd -- seconds=240
 godot --path . --rendering-method gl_compatibility --script tests/head_clearance_capture.gd -- frame=1531 out=/tmp/clearance.png

## V46 local, 14 noviembre04:45, recuperacion de reves

Este checkpoint incluye V29 y sustituye su solucion de recuperacion de
reves. Conserva la muneca de la toma una vez liberado el contacto, en vez
de conservar la cabeza de la raqueta y recolocar el brazo alrededor de ella.
Busca orientacion que permita ambas manos, respete la envolvente de cabeza
y evite una capsula aproximada abdomen-cuello. La orientacion anterior tiene
peso para evitar pasar de un lado del cuello al otro en pocos fotogramas.
Transicion100-200ms desde el ajuste del contacto a la muneca de la toma;
se vuelve a verificar separacion de cabeza durante esa transicion.
No se ha cambiado simulacion ni se ha aceptado ningun nuevo limite AI.

Mano izquierda: alcanza el mango antes durante la preparacion (la mezcla
llega a1 con peso corporal0,5). No se dibuja un puno cerrado si el error de
agarre supera3mm; entonces se conserva la mano abierta siguiendo su muneca.
Esto no convierte en alcanzables los objetivos que no lo son. El contacto
de reves observado sigue a dos manos. Sigue pendiente la calidad completa
de la entrada y liberacion de esa mano, no solo su posicion en el impacto.

V39, mismo calculo de cuerpos que V46 excepto visibilidad de mano abierta:
240s/14400frames sin intersecciones con la envolvente elipsoidal aproximada;
87contactos no-saque, maximo0,0024mm; cadenas0,279mm, ninguna>1mm.
V36, mismo recorrido: pies245muestras a4mm/apoyo129frames25anclajes,
maximo0,004mm. No afirmar contacto o apoyo natural por esas cifras.

Prueba de secuencia reproducible: se desactiva la fisica antes de esperar
el primer frame y se vuelve a fijar la semilla despues. Las capturas anteriores
podian consumir aleatoriedad de efectos al dibujar el primer frame y no
reproducir la misma secuencia entre renderizador/headless. Las comparaciones
nuevas V29/V46 usan el mismo arranque y poses finales guardadas. Por eso
HUD y pelota se quedan al final durante el montaje de cuerpos. Se han
inspeccionado26poses completas de cada variante238..288 y las ampliaciones
254/262/270. El aro ya no baja por detras del cuello al volver al centro en
ese ciclo. No se ha validado rendimiento real, ni se usa este montaje como
video de partido completo.

No adoptadas: aumentar la envolvente hasta el cuello sin cambiar el ajuste
llevaba el aro al torso; adelantar todo el objetivo no conservaba el gesto;
filtrar la prediccion y cambiar el buscador de llegada daban regresiones
entre secuencias; mezclar clips al cambiar de lado empeoraba otros contactos.
Esas pruebas locales estan preservadas fuera de este checkpoint.

Pendiente delimitado: prediccion visual del intento fallido, cambio de
preparacion a carrera, giro del cuerpo y transiciones rapidas. La prediccion
actual puede llevar la raqueta hacia un punto imposible aunque la CPU falle
correctamente. No se ha cambiado la simulacion para esconderlo ni se ha
presentado el movimiento completo como terminado. Las mediciones con otra
semilla/arranque cambian los casos peores y no prueban una mejora global.

V46 comprobacion de agarre30s:427frames con puno izquierdo cerrado,
error maximo0,00054mm. Diez contactos de reves no-overhead de ambos cuerpos
con mano izquierda cerrada y error menor3mm (assert). El remate no se cuenta
como reves a dos manos. Reglas de saque y12casos/70frames/cuatro cadenas
repetidosPASS; extension del saque23,95grados y cadenas0,012mmPASS.
Copia limpia desde603c0ab, aplicar visualV46+SIMV17+SIMV18, importacion y
head-proxy30s strictPASS. Persisten avisos ObjectDB/recursos al salir.

## V48 local, 14 noviembre04:52, salida de intento fallido

Sobre V46, mezcla durante200ms la ultima pose del intento fallido con
la carrera, manteniendo longitud de cadenas y abriendo la mano izquierda.
No retrasa la posicion del jugador ni cambia la simulacion o el predictor.
Se cancela al iniciar golpe o saque. No incluye el filtro de alcance V47,
rechazado por regresion en otra secuencia.

Arranque reproducible despues del primer dibujado,30s: dos salidas de
intento. Paso de cabeza de raqueta en el primer frame baja de0,931/0,723m
(V46) a0,157/0,148m (V48). Esto no mide continuidad global. Inspeccionadas
19poses318..354 y19poses1374..1410; se elimina el destello de brazo alto
al pasar a carrera en el primer caso y la segunda salida conserva su
transicion. Sigue sin resolver la prediccion de un intento fuera del alcance,
y la carrera/giro/apoyos siguen sin validacion de naturalidad.

V48 repetido:240s87contactos no-saque, error maximo0,0031mm, cadenas0,276mm
sin casos>1mm;240s/14400frames sin cruce del proxy de cabeza aproximado.
245muestras de suela a4mm;36casos de contacto/70frames/cuatro cadenasPASS.
427frames con puno izquierdo cerrado, gap maximo0,00085mm y10contactos de
reves no-saque/no-remate a dos manos(assert). Saque extension/cadenasPASS.
Replay8poses de ambos cuerpos identicas a grabacion; replay real67muestras
tras dibujado, error0 y regreso al partido verificados. Se inspecciono la
lamina completa de67frames mas regreso; no es medicion GPU/movil.
Persisten avisos de recursos al salir. No publicado ni aplicado al remoto.

## V51 local, 14 noviembre05:17, preparacion mientras corre

Sobre V48. Si el punto previsto sigue a mas de1,7m del jugador, las piernas
mantienen progresivamente su ciclo de carrera, en vez de congelarse en
la toma de golpe. A2,5m conservan toda la carrera. Cadera/tronco/brazos
mantienen el calculo anterior. En un golpe ya registrado no se aplica esta
mascara. El objetivo del ajuste de brazo durante la preparacion queda
dentro de brazo+raqueta menos6cm, no se intenta resolver un objetivo mas
lejano estirando el brazo. Los impactos registrados no se limitan asi.
Simulacion y predictor sin cambios respecto V48. Esto no arregla por si
solo una decision de lado equivocada o todos los tiempos del gesto.

Inspeccionadas18poses300..334 de V48 y V51 con el mismo arranque. Se ve el
ciclo de piernas durante la carrera al intento que no alcanza. Mantiene la
salida suavizada V48. Tambien se inspeccionaron los341frames de una muestra
real de partido de17,05s a20fps (pasos simulacion60Hz), camara partido y
primer plano cercano, incluyendo saque y rally. No es rendimiento real:
la captura tardo mas de115s y se detuvo antes de completar los30s previstos.
Otra muestra lejana hasta28s se inspecciono por muestras; se descarta su
transicion artificial de camara28s porque el guion de prueba la llevaba
fuera de la pista. No es un defecto nuevo atribuido al juego.

Repetidos V51:240s87contactos no-saque/error maximo0,0031mm/cadenas0,276mm
sin>1mm;240s sin cruce del proxy de cabeza;36casos70frames4cadenasPASS.
428frames con mano izq cerrada/gap maximo0,00085mm,10contactos de reves
no-remate/no-saque a dos manos(assert). Reglas de saquePASS.
La prueba antigua de pies falla porque exigia un pie en suelo tambien
mientras corre preparando sin golpear: cuatro frames de ambos pies en aire,
maximo58,2mm. No se borra ese resultado. Nueva feet_planted_metrics separa
esa carrera del golpe/apoyo;104muestras de apoyo o golpe a4mmPASS, no hay
penetracion en las141muestras de preparacion corriendo de esa secuencia.
Eso no prueba un buen ritmo de apoyos.

Control tactil nativo1280x720: sacar con dos pulsaciones, cambiar camara,
pausar y reanudarPASS. La inyeccion sintetica a844x390 no vale como prueba:
coordenadas/escalado no coincidian y no se resolvio su mapeo. Export Web
local640x360 con tacto emulado: menu/configuracion/partido/pausa/reanudar
inspeccionados en capturas. Capturar despues de cambiar camara excedio70s;
camara/golpe Web siguen sin validar. No se ha probado telefono fisico.

Se preservaron, pero NO se adoptan, V49 (mezclar tambien cadera hacia
carrera), V52 (separar reloj de armado y avance), V53 (fijar lado mas tarde)
y V54 (orientacion segun lado fijado). Producian regresiones en otras
entradas. V50 es la mascara de piernas V51 sin el limite de preview.
Pendiente: calidad completa de la preparacion, eleccion de lado y giro,
ritmo de carrera/apoyo. El conjunto no se da por terminado o natural.
V51 final: replay real repetido67muestras despues de dibujar/error0/regreso
al partidoPASS; lamina completa de67masregreso inspeccionada. Copia limpia
603c0ab+visualV51+SIMV17+SIMV18 aplica/importa, rig identico al probado y
feet_planted_metrics reproducidoPASS con las mismas cuatro fases de vuelo.

## V57 local, 14 noviembre05:34, eleccion de preparacion

Reinicia la preparacion al comenzar una llegada nueva, no arrastra su lado
anterior. Espera a que la preparacion pase0,7 para elegir derecha/reves y
entra progresivamente durante160ms desde la postura de carrera. La espera
no dibuja ya la toma equivocada mientras se decide el lado. No cambia el
lado del impacto ni la simulacion. La entrada anterior a veces preparaba
una derecha y cambiaba a reves al registrar el golpe.

En la secuencia1722..1758 se inspeccionaron19poses: ahora arma el reves a
dos manos antes del impacto. Tambien se inspeccionaron los47frames de una
muestra real2,35s a20fps con pelota/HUD sincronizados: armado, contacto,
recuperacion y carrera hacia la siguiente pelota. No mide rendimiento
real: son pasos simulacion60Hz con dibujado muestreado.

Un nuevo cruce con el proxy de cabeza durante la entrada de una derecha
se detecto en la otra secuencia (frame346), por eso V56 sola se descarto.
V57 corrige solo esa preparacion mediante IK de muneca manteniendo la
orientacion, hasta cuatro pasos contra la misma envolvente. No actua en
un impacto registrado ni cuando la mano izquierda esta cerrada. Proxy
240s/14400frames repetido sin cruces; no es colision exacta de malla ni
prueba completa del cuello/torso.

FINAL V57: contacto240s87no-saque/error max0,0031mm/cadenas0,276mm, ninguna
>1mm;36casos70frames4cadenasPASS;reglas y extension de saquePASS.332frames
con mano izquierda cerrada/maxgap0,00085mm y10contactos reves no-remate/
no-saque a dos manos(assert).86muestras de golpe/apoyo a4mm, cuatro fases
de vuelo en carrera preparando comoV51, max58mm. El fallo de la prueba
antigua que exigia estar plantado mientras corre se conserva documentado.
Replay8poses exactas y replay real67muestras despues de dibujar/error0/
regresoPASS; lamina de67masregreso inspeccionada entera.

El conjunto no se da por terminado: aun queda un caso de eleccion de lado
incorrecto en otra secuencia y transiciones rapidas. Las mejoras de este
checkpoint no prueban naturalidad, ritmo global o rendimiento en telefono.
No se ha exportado/probado WebV57; los controles Web descritos antes son
V51. Sin commits nuevos, remoto, merge o publicacion.

## V59 local, 14 noviembre05:47, cambio de lado durante la llegada

V57 fijo el lado demasiado pronto en trayectorias distintas de la muestra
original: cuatro semillas de30s daban14preparaciones equivocadas de45.
No se adopto la prediccion lineal de posicion futura: mejoraba una semilla
y empeoraba otra. V58 dejo cambiar de lado tras50ms de confirmacion y
mezclo las poses locales durante160ms; se rechazo porque una transicion
que seguia durante un impacto bajo dejo la raqueta24,9mm fuera de contacto.

V59 conserva el cambio de lado confirmado, pero acaba la mezcla de
preparacion antes del impacto previsto (duracion33..160ms segun el tiempo
restante). El golpe real usa su pose de golpe, sin arrastrar la mezcla de
preparacion. No cambia posicion, pelota, CPU ni lado decidido por el juego.
Las cuatro trayectorias pasan de14/45lados equivocados a1/45. Desglose:
42117:1/12a0/12;1234:2/11a0/11;72:0/2a0/2;8853:11/20a1/20.
El residual es8853/frame1262/actor1, una llegada junto al plano central
que termina en derecha. No es cero errores y no se considera terminado.
La prueba preparation_side_regression registra preparacion ANTES del
impacto, no toma el lado real como si fuera una prediccion acertada. Su
techo conocido es1, se imprime explicitamente; no prueba naturalidad.

V59 se inspecciono en104frames reales de tres ventanas (dos jugadores,
dos semillas, pelota y HUD sincronizados). Comparacion V57/V59 en10pares
de poses de dos llegadas: el jugador gira y arma el reves antes de pegar
en vez de pasar de una derecha al reves en el impacto. Captura software,
60Hzsimulacion/20fpsmuestreo, no prueba de rendimiento.

Regresion final V59:240s87contactos, error max0,0031mm/cadenas0,276mm,
0cadenas invalidas;240s proxy cabeza0cruces.36casos70frames4cadenasPASS;
362frames con segundo agarre cerrado maxgap0,00085mm.86muestras de apoyo
4mm y4vuelos preparando max58mm, igual que antes.8poses replay ambos
jugadores exactas; saque/contacto/extension/reglas repetidos enV59PASS.
No se exporto WebV59.

V59 sustituye el parche visual completoV57, no se apila. Aun requiere los
mismos parches separadosV17toss yV18reach. V57 queda como alternativa.
Sin commits nuevos, remoto, merge o publicacion. Quedan el caso central,
la valoracion del ritmo corporal completo y rendimiento en telefono real;
la mejora de14a1no justifica llamar natural o terminado al conjunto.

## V74 local, 14 noviembre06:22, orientacion y desplazamiento

Revision posterior a V59. No es aprobacion del movimiento del conjunto.
Se quita la suma de giro de windup aplicada cada frame, se deja de seguir
con el cuerpo la pelota que ya sale, y se corrige la eleccion izquierda/
derecha de carrera para el jugador lejano. La orientacion de llegada se
introduce entre6,5y2m, no con un salto de umbral a3,5m. La orientacion de
sprint entra progresivamente entre5,6y7m/s. Fuera del ultimo cuarto de
segundo de contacto se limita el giro a270grados/s; ese limite NO se
aplica durante el contacto porque el ensayo anterior dejaba49mm de error.
Para un globo alto se conserva orientacion de pista, no se hace girar al
jugador alrededor del punto horizontal que pasa bajo sus pies.

240s/87contactos: error max0,00391mm, cadenas0,259mm,0invalidas. Proxy
cabeza240s0cruces.36casos70frames4extremidadesPASS.362frames de segundo
agarre cerrado, distancia maxima0,162mm (mayor queV59, sigue bajo3mm).
86muestras plantadas a4mm;4frames de carrera preparando con vuelo max58mm
como antes. Saque/extension/reglas/replay8poses exactasPASS. Preparacion
4semillas conserva1/45equivocado, no se cambia ese reves para perseguir0.

Tres ventanas reales de27frames se inspeccionaron enteras,81frames:
reves lejano llegada-contacto-recuperacion, preparacion alta fallida y
carrera hasta punto perdido. La preparacion alta ya no gira alrededor de
la pelota pero sigue demasiado tiempo con brazos levantados. Queda ese
ritmo de preparacion, cambios rapidos de orientacion en llegadas finales
y apoyos poco convincentes. No se declara humano/natural ni terminado.
Las cuentas de cambios>8grados/frame en dos semillas solo son diagnostico,
no criterio de calidad. No hay nueva pruebaWeb/movil ni rendimientoGPU.

Sustituye completoV59 sobre603c0ab. Requiere mismosSIMV17toss+V18reach,
separados; no contiene esos cambios de simulacion. V59 queda conservado.
Sin commit, push, PR, merge o publicacion.

## V75 local, 14 noviembre06:29, preparacion alta segun altura alcanzable

La traza del globo8853mostro el defecto exacto: el reloj horizontal marcaba
llegada inmediata mientras la pelota estaba a12-14m de altura. Se conservaba
progreso1de preparacion y el personaje mantenia el brazo alto mas de1s,
incluso cuando el globo ya pasaba fuera. No era una pelota de remate posible.

Solo cambia la capa visual: la aproximacion de preparacion se atenúa entre
3,25y4m de altura prevista, usando la mezcla temporal ya existente. Una
preparacion alta no hereda un progreso maximo anterior cuando la pelota
sigue fuera de alcance. No se cambia la trayectoria, la CPU ni el punto
perdido. El remate real y el saque conservan sus caminos de contacto.

Prueba nueva overhead_readiness_regression: dos semillas30s,82muestras con
pelota actual>6m y prevista>4m tras200ms. V74tenia34frames con mano por
encima de la cabeza (max53,4cm);V75tiene0, mano al menos31,9cm por debajo.
No es prueba general de naturalidad: comprueba ese gesto prematuro concreto.
54frames reales se inspeccionaron completos: globo fallido sin mantener
brazo arriba y otra llegada-remate real con extension y recuperacion.
Ademas, clip continuo12s240frames0..717,20fps, inspeccionados TODOS en
cuatro laminas, incluye general, saque cercano completo y reves lejano.
Captura software57s; no es medicion de rendimientoGPU.

RegresionV75:240s87contactos, max0,00391mm/cadenas0,259mm/0invalidas;
proxy cabeza240s0cruces;36casos70frames4extremidadesPASS.362frames agarre
cerrado max0,162mm;86muestras plantadas4mm y4frames corriendo preparando
con vuelo max58mm. Saque/extension/reglas/replay8poses exactasPASS.
Preparacion cuatro semillas sigue1/45equivocado, techo conocido no cero.
Persisten giros rapidos durante llegadas finales y apoyos/deslizamiento;
no se presenta como el movimiento humano completo que pide Jose.

V75sustituyeV74yV59, no se apila. MismosSIMV17toss+V18reach separados.
WebV59ya tuvo verificados config/partido/pausa/reanudar/cambio de camara;
ese control NO validaV75. GolpeWeb y movil fisico/GPU siguen sin verificar.
No hay commit, push, PR, merge ni publicacion de estas alternativas.

## V76 local, 14 noviembre06:38, pasos en coordenadas del cuerpo

La eleccion carrera lateral/atras seguia usando vx/vz del mundo y una
inversion fija por lado de pista. Eso solo coincide con los ejes de las
piernas cuando el cuerpo mira exactamente a0o180grados. V76transforma
la velocidad al espacio del cuerpo antes de elegir la direccion del paso.
No cambia velocidad/posicion de simulacion ni el giro de cuerpo deV75.
No modifica la rama separada de recolocacion entre puntos (el ensayoV77
para esa rama queda conservado, no adoptado).

Se inspeccionaron27frames de vuelta al fondo y27de llegada/reves en partido
real, mas9pares conV75. La direccion de paso acompana el giro en el primer
caso; no implica pies fijados o ausencia general de deslizamiento.
Clip continuo nuevo12s240frames0..717, todos inspeccionados en4laminas;
misma cobertura general/saque cercano/reves lejano, no pantalla negra ni
cortes de pista vistos. Captura software57s, no rendimiento.

Regresiones repetidas:240s87contactos max0,00391mm/cadenas0,259mm/0invalidas;
proxy cabeza240s0cruces;362frames segundo agarre max0,00052mm;86muestras
plantadas4mm,4vuelos preparando58mm. Cadenas36casos70frames,saque,
extension,reglas,replay8poses exactasPASS. Preparacion1/45residual comoV75;
prueba globo alto82muestras0brazo alto prematuroPASS. No hay nueva prueba
Web/movil. Siguen limites deV75y no se declara movimiento humano terminado.
V76sustituyeV75; mismosSIMV17toss+V18reach separados, sin apilar.
No commit, push, PR, merge ni publicacion.


## V92 local, 14 noviembre07:24, llegada final y alcance con dos manos

Correccion de cobertura: V76 pasaba87contactos de una secuencia240s, pero
las cuatro semillas exactas de captura revelaron otros dos errores de
61,1mm y13,9mm. Ese PASS anterior no cerraba contacto global. V76 queda
conservado con esta salvedad. V85 arreglo esos contactos, pero su torso
saltaba23,1cm/24,8cm en el primer frame de esos golpes. No se entregaV85
como cierre visual por aprobar solo sus numeros de contacto.

V92 conserva el limite de giro270grados/s durante TODA la preparacion,
incluida la llegada final. El ajuste del golpe registrado conserva su
camino anterior: limitar tambien este ajuste rompia otro contacto10mm
y dos remates, asi que ese ensayo no esta adoptado.

El alcance del reves se calcula para ambas manos, hasta tres pasadas de
recolocacion del torso (maximo acumulado0,20unidades del rig,21,7cm del
mundo). Las piernas se resuelven otra vez hacia los pies guardados, sin
alargar huesos. La misma preparacion de alcance se aplica antes del golpe
con su objetivo previsto, no se espera al primer frame registrado. La
orientacion a dos manos se busca ya para el objetivo solicitado, no para
un contacto anterior que no seria alcanzable. No cambia simulacion,
trayectoria de pelota, raiz de jugador ni resultado del punto.

Comparacion real de las dos llegadas: torso primer frame23,1->5,13cm y
24,8->9,19cm, incluyendo desplazamiento de carrera. Prueba dirigida nueva
contact_arrival_body_regression fija techo12cm SOLO en esos dos casos;
no es prueba de fluidez general. Siguen cambios rapidos en el cambio de
lado de preparacion de la segunda llegada (max30,7cm frente29,7cm del
ensayo sin anticipacion), por lo que no se declara movimiento humano
terminado ni ausencia de saltos en todo el partido.

La anticipacion descubrio un cruce raqueta/cabeza en una liberacion de
intento fallido, ya terminado el punto. La proteccion de preparacion ahora
tambien cubre esos200ms de liberacion, no golpes registrados ni saques.
Se inspeccionaron19frames consecutivos de esa liberacion en partido.

Nueva arrival_turn_regression:4semillas30s,4620muestras de giro sin
contacto,0superan4,51grados/frame;47contactos no saque max0,00228mm;
44contactos de suelo apoyo4mm (error<0,00004mm);3remates saltados se
excluyen SOLO de apoyo, no de contacto/cadenas. Cadenas max0,101mm,
agarre a dos manos max0,00066mm,sin separaciones. No se ocultan fallos
CPU ni se ajusta trayectoria para mejorar estas cifras.

Regresiones V92:240s87contactos max0,00534mm,cadenas0,278mm,0invalidas;
proxy cabeza240s0cruces;357frames agarre max0,00055mm;86apoyos4mm,
0vuelos preparando en esta secuencia. Cadenas36casos70frames4extremidades,
saque/extension/reglas,replay8poses exactasPASS. Preparacion sigue1/45
central conocido;globo alto82muestras0brazo prematuro. No es cobertura
exhaustiva ni medicion de anatomia por colision de malla completa.

Inspeccion visual:42frames de ambas llegadas antes/despues,12s continuos
240frames0..717 TODOS inspeccionados (general,saque cercano completo,
reves lejano),19frames de liberacion fallida. Captura software unos56s
para12s, no rendimiento GPU. WebV59 tenia comprobados menus/config/
partido/pausa/reanudar/camara; eso NO validaV92. GolpeWeb y movil fisico
siguen sin verificar, sin repetir intentos identicos costosos.

V92 sustituye COMPLETO V76/V75/V59 sobre603c0ab, no se apila. Requiere
los mismos SIMV17toss+V18reach SEPARADOS, sin cambiosSIMnuevos. Se
conservan variantes sin limite. Sin commit,push,PR,merge o publicacion.

## V94 local, 14 noviembre07:32, cambio de lado sin salto de alcance

V92 quedo conservado con su salto30,7cm del torso en el cambio tardio
forehand->reves. El cambio mezclaba el clip, pero aplicaba inmediatamente
todo el alcance del torso para el nuevo lado. V94 mantiene100ms minimos
de mezcla y aplica el presupuesto de alcance con esa misma mezcla. Al
llegar un contacto se conserva el resto de mezcla local si aun falta,
pero el ajuste exacto de ambas manos sigue resolviendo el impacto. El
ensayo antiguoV58 no tenia este ajuste bilateral y fallaba24,9mm; no se
reusa su resultado como justificacion ni se oculta aquella regresion.

En el caso8853 el mayor desplazamiento del torso de todo el tramo350..380
baja30,7->17,7cm/frame; pie derecho53,1->29,4cm/frame. Incluye carrera,
no es garantia contra deslizamiento. Primer frame contacto9,37cm; otro
caso42117 sigue5,13cm. La prueba dirigida ahora exige inicio<12cm y maximo
del torso<20cm en esos dos tramos. No se afirma que toda la animacion sea
humana o fluida por superar ese techo. Sigue preparacion1/45central y
faltan Web/movil/GPU actuales.

Regresiones repetidasV94:4semillas47contactos max0,00308mm,44apoyos4mm,
0violaciones de giro/agarre/cadenas;240s87contactos max0,00534mm,cadenas
0,278mm,0invalidas;proxy cabeza240s0cruces;351frames segundo agarre max
0,00055mm;86apoyos4mm,0vuelos preparando en esta secuencia. Cadenas36x70,
preparacion1/45,globo0/82,saque/extension/reglas/replay8exactasPASS.

Inspeccionados31frames consecutivos del cambio y81frames adicionales
de3llegadas/giros, ademas del nuevo continuo12s240frames TODOS vistos
en4laminas y9pares V92/V94. Captura software57s, no rendimientoGPU.
V94 sustituye completoV92y anteriores sobre603c0ab, mismosSIMV17toss+
V18reach separados. V92 queda conservado. Sin commit,push,PR o publicacion.

## V95 local, 14 noviembre07:39, liberar preparacion tras punto

Se inspeccionaron TODOS los480frames de un partido V94 de24s (frames720..2157,
cada3, semilla8853, camara cercana al jugador de cada lado). Revelo un defecto
concreto: tras fallar la devolucion quedaba congelado el reves unos2s mientras
se anunciaba el punto. El timer want_t de simulacion quedaba positivo durante
ese descanso y la presentacion lo seguia interpretando como preparacion activa.
V95 pasa a la figura un indicador visual de punto terminado; solo desactiva
esas dos ramas de preparacion, sin borrar timers ni editar reglas o CPU.
La figura termina el gesto, baja la raqueta y espera. Inspeccionados59frames
1740..1914 de la correccion en partido. Regresion nueva comprueba76frames de
espera pese al timer residual. Las dos llegadas y47contactos de4semillas no
cambian;240s87contactos mantienen max0,00534mm y cadenas0,278mm.
No se afirma movimiento humano terminado, pies sin deslizamiento o rendimiento
GPU. Web/movil actuales siguen pendientes. V94 queda conservado.

## V99 local, 14 noviembre08:00, transiciones de pasos

V95/V94 quedan conservados. Al pasar entre carrera frontal, lateral, atras
y paseo, el fundido nativo seguia produciendo cambios bruscos de piernas.
V99 mezcla durante120ms la pelvis y las piernas desde la pose final anterior,
en coordenadas locales y conservando longitudes. Los brazos no se congelan
con esa mezcla; saque, golpe y ajuste final se aplican despues como antes.
No hay cambio de velocidad, posicion ni decision en simulacion.

Se probaron y descartaron otras variantes: conservar solo la fase del clip
empeoro un cambio Run->Run_Back (43cm/frame); mezclar tambien brazos retenia
innecesariamente la raqueta tras el punto. No se presentan como soluciones.

La prueba dirigida incluye el cambio y OCHO frames posteriores, para no
ocultar un salto retrasado: 849muestras de3semillas (90s de simulacion).
El peor desplazamiento de pie en esos tramos baja57,7->46,0cm/frame;
para1234/jugador0 baja49,7->32,5cm y8853/jugador0 51,1->38,4cm. Es movimiento
mundial de pies en carrera, NO error de apoyo ni garantia de pies clavados.
La media baja en los seis grupos de semilla/jugador. Longitudes de cuatro
extremidades en TODOS los frames de esas3semillas: error max0,288mm.
Contacto47/4semillas y dos llegadas conservan resultadosV94;240s87contactos
max0,00534mm,cadenas0,278mm. Cabeza240s0cruces de proxy. Agarre351, apoyos86,
cadenas36x70, saque/extension/reglas/replay8, globo82 y preparacion45 pasan
con el mismo residual1/45central conocido. La liberacion tras punto pasa76.

Inspeccion visual: V95 y V99, cada uno16s continuos320frames (480..1437,
semilla1234), todos vistos;25frames consecutivos del cambio y4pares a mayor
tamano; otros167framesV97 fueron diagnostico, no se atribuyen aV99. Captura
software V99 unos70s para16s: no mide rendimiento GPU ni movil.
Se reduce un defecto de transicion; no se declara naturalidad global resuelta
ni ausencia de deslizamiento. Web/movil/GPU actuales siguen sin verificar.
Sustituye completoV95 sobre603c0ab, mismosSIMV17toss+V18reach separados.
Sin commit,push,PR,merge o publicacion.

Entrega08:03: copia limpia aplica/importa y reproduce punto, giro/contacto y
la nueva regresion de pasos. Se codificaron y volvieron a decodificar los
16s/320frames y un segundo continuo12s/240frames (plano general, saque cercano
completo, reves lejano). Se inspeccionaron TODOS los560frames decodificados,
no solo las capturas fuente. No se vieron franjas negras ni cortes de pista
en esos archivos. El segundo clip tardo unos60s en capturarse por software.
