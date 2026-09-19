;; ==========================================
;; MODELO DE TERMITAS (Recursivo o Iterativo)
;; ==========================================

;; VARIABLES GLOBALES
globals [
  ;; Variables para análisis estadístico (Modo Iterativo)
  cantidad-termitas-cargando  ; Cantidad de termitas que están cargando astillas
  numero-cumulos              ; Número de cúmulos grandes

  ;; Seguimiento del modo actual para re-inicializar al cambiar el switch
  modo-actual                 ; true = recursivo, false = iterativo

  ;; Conteo de pilas por color (Modo Recursivo)
  numero-cumulos-amarillos    ; Número de pilas de astillas amarillas
  numero-cumulos-cafes        ; Número de pilas de astillas cafés
]

;; ==========================
;; PROPIEDADES DE LOS AGENTES
;; ==========================
turtles-own [
  ;; Variables para Modo Recursivo
  wood-type  ; Tipo de astilla cargando: "yellow", "brown", o "none"

  ;; Variables para Modo Iterativo
  estado     ; Estado del agente: "buscando", "llevando", "depositando", "alejandose", "completo"
]

;; ==========================
;; PROPIEDADES DE LOS PATCHES
;; ==========================
patches-own [
  marcado  ; Flag para algoritmo de búsqueda de cúmulos (Modo Iterativo)
]

;; =================
;; FUNCIÓN PRINCIPAL
;; =================
;; Inicializa el modelo de termitas con los parámetros configurados
to setup
  ;; === FASE 1: LIMPIAR ENTORNO ===
  clear-all                        ; Limpiar el mundo y resetear variables
  set-default-shape turtles "bug"  ; Establecer forma de insecto para agentes

  ;; === RECORDAR MODO ACTUAL (para detectar cambios en tiempo de ejecución) ===
  set modo-actual modo-recursivo

  ;; === FASE 2: CONFIGURAR SEGÚN MODO SELECCIONADO ===
  ifelse modo-recursivo [
    ;; MODO RECURSIVO: Trabajo con dos tipos de astillas (yellow y brown)
    inicializar-modo-recursivo
  ] [
    ;; MODO ITERATIVO: Trabajo con un solo tipo de astilla (verde)
    inicializar-modo-iterativo
  ]

  ;; === FASE 3: INICIALIZACIÓN DE TIEMPO ===
  reset-ticks  ; Iniciar contador de tiempo
end

;; =============================
;; INICIALIZACIÓN MODO RECURSIVO
;; =============================
;; Configura el entorno y agentes para el modo recursivo
to inicializar-modo-recursivo
  ;; === FASE 1: DISTRIBUIR ASTILLAS DE DOS COLORES ===
  ; Asigna astillas amarillas y cafés aleatoriamente según la densidad
  ask patches [
    if random-float 100 < densidad [
      ; 50% de probabilidad para cada color
      ifelse random-float 100 < 50 [
        set pcolor yellow  ; Astilla amarilla
      ] [
        set pcolor brown   ; Astilla café
      ]
    ]
  ]

  ;; === FASE 2: CREAR POBLACIÓN DE TERMITAS ===
  create-turtles poblacion [
    set color white                ; Color blanco cuando no cargan nada
    setxy random-xcor random-ycor  ; Posición inicial aleatoria
    set size 5                     ; Tamaño visual del agente
    set wood-type "none"           ; Estado inicial: sin carga
  ]
end

;; ===============================
;; INICIALIZACIÓN MODO ITERATIVO
;; ===============================
;; Configura el entorno y agentes para el modo iterativo
to inicializar-modo-iterativo
  ;; === FASE 1: DISTRIBUIR ASTILLAS DE UN SOLO COLOR ===
  ; Asigna astillas verdes (color 33) según la densidad
  ask patches [
    set marcado false                ; Inicializar variable de marcado
    if random-float 100 < densidad [
      set pcolor 33                  ; Astilla verde
    ]
  ]

  ;; === FASE 2: CREAR POBLACIÓN DE TERMITAS ===
  create-turtles poblacion [
    set color white                ; Color blanco cuando no cargan nada
    setxy random-xcor random-ycor  ; Posición inicial aleatoria
    set size 5                     ; Tamaño visual del agente
    set estado "buscando"          ; Estado inicial: buscar astillas
  ]
end

;; ==============================
;; FUNCIÓN PRINCIPAL DE EVOLUCIÓN
;; ==============================
;; Ejecuta un paso de tiempo en el modelo de termitas
to go
  ;; === DETECTAR CAMBIO DE MODO Y REINICIALIZAR AUTOMÁTICAMENTE ===
  if modo-actual != modo-recursivo [
    set modo-actual modo-recursivo
    setup
    stop
  ]

  ifelse modo-recursivo [
    ;; === MODO RECURSIVO: CICLO COMPLETO POR AGENTE ===
    ; Cada termita ejecuta su ciclo completo: buscar → encontrar → depositar
    ejecutar-modo-recursivo
    ;; Avanzar el tiempo en modo recursivo
    tick

    ;; Conteo periódico de pilas por color (usa 'umbral' como tamaño mínimo)
    if (ticks mod 10000 = 0) [
      set numero-cumulos-amarillos count-larger-clusters-color umbral yellow
      set numero-cumulos-cafes     count-larger-clusters-color umbral brown
    ]
  ] [
    ;; === MODO ITERATIVO: MÁQUINA DE ESTADOS ===
    ; Las termitas avanzan por estados en cada tick
    ejecutar-modo-iterativo
  ]
end

;; ========================
;; EJECUCIÓN MODO RECURSIVO
;; ========================
;; Ejecuta el comportamiento recursivo de todas las termitas
to ejecutar-modo-recursivo
  ask turtles [
    ;; === CICLO COMPLETO DE LA TERMITA ===
    buscar-madera   ; FASE 1: Buscar y recoger una astilla
    encontrar-pila  ; FASE 2: Encontrar pila del mismo color
    dejar-madera    ; FASE 3: Depositar astilla y teletransportarse
  ]
end

;; ========================
;; EJECUCIÓN MODO ITERATIVO
;; ========================
;; Ejecuta el comportamiento por estados de todas las termitas
to ejecutar-modo-iterativo
  ;; === ESTADO 1: BUSCANDO ASTILLAS ===
  ask turtles with [estado = "buscando"] [
    do-buscar-madera
  ]
  tick

  ;; === ACTUALIZAR CONTADOR DE TERMITAS CARGANDO ===
  set cantidad-termitas-cargando count turtles with [estado = "llevando"]

  ;; === ESTADO 2: LLEVANDO ASTILLAS ===
  ask turtles with [estado = "llevando"] [
    do-encontrar-pila
  ]
  tick

  ;; === ESTADO 3: DEPOSITANDO ASTILLAS ===
  ask turtles with [estado = "depositando"] [
    do-dejar-madera
  ]
  tick

  ;; === ESTADO 4: ALEJÁNDOSE DE LA PILA ===
  ask turtles with [estado = "alejandose"] [
    do-alejarse
  ]
  tick

  ;; === REINICIAR CICLO ===
  ; Las termitas que completaron su ciclo vuelven a buscar
  ask turtles with [estado = "completo"] [
    set estado "buscando"
  ]

  ;; === CONTEO PERIÓDICO DE CÚMULOS ===
  ; Cada 10,000 ticks se cuentan los cúmulos grandes
  if (ticks mod 10000 = 0) [
    set numero-cumulos count-larger-clusters umbral
  ]
end

;; ==================================
;; PROCEDIMIENTOS PARA MODO RECURSIVO
;; ==================================

;; ===========================
;; BUSCAR Y RECOGER ASTILLA
;; ===========================
;; Procedimiento recursivo: busca astilla hasta encontrar una
to buscar-madera
  ;; === VERIFICAR PATCH ACTUAL ===
  ifelse (pcolor = yellow) [
    ;; Encontró astilla amarilla
    set wood-type "yellow"  ; Registrar tipo de astilla
    set pcolor black        ; Quitar astilla del patch
    forward 20              ; Avanzar después de recoger
  ] [
    ifelse (pcolor = brown) [
      ;; Encontró astilla café
      set wood-type "brown"  ; Registrar tipo de astilla
      set pcolor black       ; Quitar astilla del patch
      forward 20             ; Avanzar después de recoger
    ] [
      ;; === CASO RECURSIVO: NO HAY ASTILLA ===
      ; Continuar buscando en otra ubicación
      caminata-aleatoria
      buscar-madera  ; Llamada recursiva
    ]
  ]
end

;; ==============================
;; ENCONTRAR PILA DEL MISMO COLOR
;; ==============================
;; Procedimiento recursivo: busca pila del mismo color de astilla que carga
to encontrar-pila
  ;; === VERIFICAR SI ENCONTRÓ PILA CORRECTA ===
  ; Debe coincidir el color de la astilla cargada con el color del parche
  ifelse (
    (wood-type = "yellow" and pcolor = yellow) or
    (wood-type = "brown"  and pcolor = brown )
  ) [
    ;; === CASO BASE: PILA ENCONTRADA ===
    ; Terminar búsqueda, pasar a depositar
    stop
  ] [
    ;; === CASO RECURSIVO: SEGUIR BUSCANDO ===
    ; Moverse y continuar la búsqueda
    caminata-aleatoria
    encontrar-pila  ; Llamada recursiva
  ]
end

;; =================
;; DEPOSITAR ASTILLA
;; =================
;; Procedimiento recursivo: busca lugar apto para depositar la astilla
to dejar-madera
  ;; === VERIFICAR SI EL PATCH ES APTO ===
  ifelse ( suitable-patch? wood-type ) [
    ;; === CASO BASE: PATCH APTO ENCONTRADO ===
    ; Depositar la astilla según su tipo
    if (wood-type = "yellow") [ set pcolor yellow ]
    if (wood-type = "brown")  [ set pcolor brown  ]

    ;; === COMPORTAMIENTO AL SOLTAR (configurable) ===
    ;; Si el switch 'salta-al-soltar' está activo, la termita salta a
    ;; una posición aleatoria; de lo contrario, simplemente sigue su camino
    ifelse salta-al-soltar [
      ; Teletransportarse a una posición aleatoria
      saltar
    ] [
      ; No saltar: liberar carga y continuar
      set wood-type "none"
      caminata-aleatoria
    ]
  ] [
    ;; === CASO RECURSIVO: BUSCAR OTRO LUGAR ===
    ; Moverse a posición adyacente
    rt random 360  ; Girar aleatoriamente
    fd 1           ; Avanzar 1 unidad
    dejar-madera   ; Llamada recursiva
  ]
end

;; ==================
;; TELETRANSPORTACIÓN
;; ==================
;; Mueve la termita a una ubicación aleatoria y resetea su estado
to saltar
  ;; === TELETRANSPORTAR A POSICIÓN ALEATORIA ===
  setxy random-xcor random-ycor

  ;; === RESETEAR ESTADO DE CARGA ===
  set wood-type "none"  ; Ya no está cargando nada
end

;; ===================
;; ALEJARSE DE LA PILA
;; ===================
to alejarse
  ;; === MOVIMIENTO ALEATORIO ===
  rt random 360  ; Girar aleatoriamente
  fd 20          ; Avanzar distancia mayor

  ;; === VERIFICAR SI SIGUE EN LA PILA ===
  ; Si todavía está sobre el color que depositó, seguir alejándose
  if (
    (wood-type = "yellow" and pcolor = yellow) or
    (wood-type = "brown"  and pcolor = brown )
  ) [
    alejarse  ; Llamada recursiva
  ]
end

;; ==================
;; CAMINATA ALEATORIA
;; ==================
;; Movimiento aleatorio simple con giros pequeños
to caminata-aleatoria
  forward 1       ; Avanzar 1 unidad
  rt random 51    ; Girar a la derecha entre 0-50 grados
  lt random 51    ; Girar a la izquierda entre 0-50 grados
end

;; ====================
;; VERIFICAR PATCH APTO
;; ====================
;; Reporta si el patch actual es apto para depositar la astilla
;; Un patch es apto si está vacío y tiene suficientes vecinos del mismo color
to-report suitable-patch? [ deposit-type ]
  ;; === VERIFICAR QUE EL PATCH ESTÉ VACÍO ===
  if pcolor != black [ report false ]

  ;; === DETERMINAR COLOR DESEADO ===
  let desired-color (ifelse-value (deposit-type = "yellow") [ yellow ] [ brown ])

  ;; === CONTAR VECINOS DEL MISMO COLOR ===
  let count-same count neighbors with [ pcolor = desired-color ]

  ;; === VERIFICAR UMBRAL DE VECINOS ===
  ; Retornar true si hay suficientes vecinos del mismo color
  report (count-same >= umbral-vecinos)
end

;; ==================================
;; PROCEDIMIENTOS PARA MODO ITERATIVO
;; ==================================

;; ===================================
;; ESTADO 1: BUSCAR MADERA (ITERATIVO)
;; ===================================
;; Busca y recoge una astilla verde, luego cambia a estado "llevando"
to do-buscar-madera
  ;; === VERIFICAR SI HAY ASTILLA EN PATCH ACTUAL ===
  if pcolor = 33 [
    ;; Recoger astilla
    set pcolor black      ; Quitar astilla del patch
    set color orange      ; Cambiar color (indicador visual de carga)
    forward 20            ; Avanzar después de recoger
    set estado "llevando" ; Cambiar a siguiente estado
  ]

  ;; === CONTINUAR BUSCANDO ===
  ; Si no encontró astilla, seguir caminando
  caminata-aleatoria
end

;; ====================================
;; ESTADO 2: ENCONTRAR PILA (ITERATIVO)
;; ====================================
;; Busca un lugar donde depositar la astilla (cualquier patch con astillas)
to do-encontrar-pila
  ;; === VERIFICAR SI ESTÁ EN PATCH VACÍO ===
  if pcolor = black [
    ; Si el patch está vacío, seguir buscando
    caminata-aleatoria
  ]

  ;; === CAMBIAR A ESTADO DEPOSITANDO ===
  ; Cuando encuentra un patch con astillas, cambia de estado
  set estado "depositando"
end

;; ==================================
;; ESTADO 3: DEJAR MADERA (ITERATIVO)
;; ==================================
;; Deposita la astilla en un patch vacío y se prepara para alejarse
to do-dejar-madera
  ;; === VERIFICAR SI PUEDE DEPOSITAR ===
  if pcolor = black [
    ;; Depositar astilla
    set pcolor 33            ; Colocar astilla verde
    set color white          ; Cambiar color (ya no está cargando)
    set estado "alejandose"  ; Cambiar a siguiente estado
  ]

  ;; === CONTINUAR BUSCANDO LUGAR VACÍO ===
  rt random 360  ; Girar aleatoriamente
  fd 1           ; Avanzar 1 unidad
end

;; ==============================
;; ESTADO 4: ALEJARSE (ITERATIVO)
;; ==============================
;; Se aleja de la pila donde depositó la astilla
to do-alejarse
  ;; === MOVIMIENTO ALEATORIO ===
  rt random 360  ; Girar aleatoriamente
  fd 20          ; Avanzar distancia mayor

  ;; === VERIFICAR SI SALIÓ DE LA PILA ===
  if pcolor != 33 [
    ; Si ya no está sobre astillas, completar ciclo
    set estado "completo"
  ]
end

;; =========================
;; CONTEO DE CÚMULOS GRANDES
;; =========================
;; Cuenta cuántos cúmulos de astillas tienen tamaño >= min-size
to-report count-larger-clusters [min-size]
  ;; === FASE 1: INICIALIZAR MARCADO ===
  ask patches [ set marcado false ]

  ;; === FASE 2: BUSCAR Y CONTAR CÚMULOS ===
  let clusters 0  ; Contador de cúmulos grandes
  let unvisited patches with [ pcolor = 33 and not marcado ]

  while [ any? unvisited ] [
    ;; Tomar un patch sin visitar como semilla
    let seed one-of unvisited

    ;; Calcular tamaño del cúmulo conectado
    let cluster-size marcar-cluster-y-retornar-tamano seed

    ;; Contar si supera el umbral
    if cluster-size >= min-size [
      set clusters clusters + 1
    ]

    ;; Actualizar patches sin visitar
    set unvisited patches with [ pcolor = 33 and not marcado ]
  ]

  ;; === FASE 3: REPORTAR RESULTADO ===
  report clusters
end

;; ======================================
;; CONTEO DE PILAS POR COLOR (MODO RECURSIVO)
;; ======================================
;; Cuenta cuántos cúmulos conectados hay del color indicado (yellow/brown)
;; con tamaño >= min-size
to-report count-larger-clusters-color [min-size target-color]
  ;; Inicializar marcado
  ask patches [ set marcado false ]

  ;; Buscar y contar cúmulos del color objetivo
  let clusters 0
  let unvisited patches with [ pcolor = target-color and not marcado ]

  while [ any? unvisited ] [
    let seed one-of unvisited
    let cluster-size marcar-cluster-y-retornar-tamano-color seed target-color
    if cluster-size >= min-size [
      set clusters clusters + 1
    ]
    set unvisited patches with [ pcolor = target-color and not marcado ]
  ]

  report clusters
end

;; Marca un cúmulo conectando vecinos del mismo color objetivo y regresa su tamaño
to-report marcar-cluster-y-retornar-tamano-color [ p target-color ]
  ask p [ set marcado true ]
  let frontera (list p)
  let total 1

  while [ not empty? frontera ] [
    let nuevo []
    foreach frontera [ p0 ->
      ask p0 [
        ask neighbors with [ pcolor = target-color and not marcado ] [
          set marcado true
          set nuevo lput self nuevo
        ]
      ]
    ]
    set total total + length nuevo
    set frontera nuevo
  ]

  report total
end

;; ======================================
;; UTILIDAD: CONTAR Y MOSTRAR PILAS FINALES
;; ======================================
;; Ejecuta el conteo por color y guarda/mostrar resultados
to contar-pilas
  set numero-cumulos-amarillos count-larger-clusters-color umbral yellow
  set numero-cumulos-cafes     count-larger-clusters-color umbral brown
  show (word "Pilas amarillas: " numero-cumulos-amarillos ", pilas cafés: " numero-cumulos-cafes)
end

;; ===============================
;; MARCAR CÚMULO Y CALCULAR TAMAÑO
;; ===============================
;; Usa algoritmo de búsqueda en amplitud (BFS) para marcar cúmulo conectado
;; Retorna el tamaño total del cúmulo
to-report marcar-cluster-y-retornar-tamano [ p ]
  ;; === FASE 1: MARCAR SEMILLA ===
  ask p [ set marcado true ]

  ;; === FASE 2: BÚSQUEDA EN AMPLITUD (BFS) ===
  let frontera (list p)  ; Lista de patches en la frontera
  let total 1            ; Contador de patches en el cúmulo

  while [ not empty? frontera ] [
    let nuevo []  ; Nueva frontera

    ;; Expandir frontera a vecinos no marcados
    foreach frontera [ p0 ->
      ask p0 [
        ask neighbors with [ pcolor = 33 and not marcado ] [
          set marcado true           ; Marcar vecino
          set nuevo lput self nuevo  ; Agregar a nueva frontera
        ]
      ]
    ]

    ;; Actualizar contadores
    set total total + length nuevo
    set frontera nuevo
  ]

  ;; === FASE 3: REPORTAR TAMAÑO ===
  report total
end
@#$#@#$#@
GRAPHICS-WINDOW
192
20
897
726
-1
-1
3.47
1
10
1
1
1
0
1
1
1
-100
100
-100
100
0
0
1
ticks
30.0

SWITCH
18
101
178
134
modo-recursivo
modo-recursivo
1
1
-1000

SLIDER
19
148
177
181
densidad
densidad
1
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
18
191
177
224
poblacion
poblacion
1
100
80.0
1
1
NIL
HORIZONTAL

BUTTON
23
54
96
87
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
101
54
174
87
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
17
262
178
295
umbral-vecinos
umbral-vecinos
1
8
3.0
1
1
NIL
HORIZONTAL

SLIDER
16
332
177
365
umbral
umbral
5
20
10.0
1
1
NIL
HORIZONTAL

PLOT
914
21
1607
203
Termitas Cargando
ticks
termitas
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13403783 true "" "if not modo-recursivo [ plot cantidad-termitas-cargando ]"

PLOT
910
214
1607
396
Numero de Cumulos cada 10,000 ticks
ticks
cumulos
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16113878 true "" "if not modo-recursivo [ plot numero-cumulos ]"

TEXTBOX
20
310
170
338
Modo Iterativo
14
0.0
1

TEXTBOX
18
240
168
258
Modo Recursivo\n
14
0.0
1

TEXTBOX
21
20
181
43
Termitas Apiladoras
18
0.0
1

MONITOR
14
404
176
449
Pilas amarillas
numero-cumulos-amarillos
0
1
11

MONITOR
14
457
176
502
Pilas cafés
numero-cumulos-cafes
0
1
11

BUTTON
15
513
175
546
contar-pilas
contar-pilas
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
15
562
175
595
salta-al-soltar
salta-al-soltar
0
1
-1000

@#$#@#$#@
## Termitas Apiladoras
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
