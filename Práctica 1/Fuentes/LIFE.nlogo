;; =================================
;; JUEGO DE LA VIDA DE CONWAY (LIFE)
;; =================================

;; VARIABLES GLOBALES
globals [
  ;; Variables para control de simulación
  generacion         ; Contador de generaciones
  poblacion-actual   ; Número de células vivas en la generación actual
  poblacion-inicial  ; Población inicial para estadísticas

  ;; Variables para análisis
  poblacion-maxima   ; Máxima población alcanzada
  poblacion-minima   ; Mínima población alcanzada
  poblacion-anterior ; Población de la generación anterior
  historia-poblacion ; Lista con historial de poblaciones

  ;; Variables para detección de patrones
  estabilizado?           ; Flag para detectar si la población se estabilizó
  generaciones-sin-cambio ; Contador de generaciones consecutivas sin cambio
  periodo-detectado       ; Periodo de oscilación detectado (si existe)
  configuraciones-previas ; Para detectar periodicidad
  tiempo-estabilizacion   ; Tick en el que se detectó estabilización (o -1 si no ocurre)

  ;; Variable para diferenciar tipos de simulación
  modo-simulacion ; "experimento" para análisis de densidad, "demo" para patrones dinámicos

  ;; Variables para demo Eater
  eater-demo-activo? ; Flag: true si el demo Eater está en modo generación continua
  ultimo-glider-tick ; Último tick en que se generó un glider
  intervalo-gliders  ; Intervalo en ticks entre generación de gliders

  ;; Variables para compuerta NOT
  not-activo?       ; Flag: true si el demo actual es la compuerta NOT
  input-a-activo?   ; Flag: true si hay input externo A
  ultimo-input-tick ; Último tick en que se generó un glider de input A
  intervalo-input-a ; Intervalo en ticks entre gliders de input A
]

;; PROPIEDADES DE LOS PATCHES
patches-own [
  vecinos      ; Número de vecinos vivos en la generación actual (vecindad de Moore)
  nuevo-estado ; Estado que tendrá en la siguiente generación
]

;; =================
;; FUNCIÓN PRINCIPAL
;; =================
;; Inicializa el Juego de la Vida con todos los parámetros configurados
to setup
  clear-all                ; Limpiar el mundo y resetear variables
  clear-drawing            ; Limpiar cualquier dibujo anterior
  clear-output             ; Limpiar ventana de salida
  configurar-tamano        ; Ajustar dimensiones del mundo según parámetros
  inicializar-variables    ; Configurar variables globales
  inicializar-condiciones  ; Establecer configuración inicial según densidad
  actualizar-estadisticas  ; Calcular estadísticas iniciales
  reset-ticks              ; Resetear contador de tiempo
end

;; ======================================
;; CONFIGURACIÓN DE DIMENSIONES DEL MUNDO
;; ======================================
to configurar-tamano
  ; Asegurar un mínimo de 100x100
  let tamaño-minimo 100
  let tamaño-final max (list tamaño-minimo tamano-retícula)

  ; Calcular radio desde el centro
  let radio int (tamaño-final / 2)

  ; Configurar mundo cuadrado centrado en (0,0)
  resize-world (- radio) (radio - 1) (- radio) (radio - 1)

  if tamano-retícula < 110 [
    set-patch-size 5
  ]
  if tamano-retícula >= 110 and tamano-retícula <= 140 [
    set-patch-size 3.55
  ]
  if tamano-retícula > 140 [
    set-patch-size 2.55
  ]
end

;; ===========================
;; INICIALIZACIÓN DE VARIABLES
;; ===========================
to inicializar-variables
  set generacion 0
  set poblacion-actual 0
  set poblacion-inicial 0
  set poblacion-maxima 0
  set poblacion-minima 999999  ; Inicializar con valor muy alto para encontrar el mínimo real
  set poblacion-anterior 0
  set historia-poblacion []
  set estabilizado? false
  set generaciones-sin-cambio 0
  set periodo-detectado 0
  set configuraciones-previas []

  ; Inicializar modo-simulacion
  set modo-simulacion "experimento"

  set tiempo-estabilizacion -1
  set not-activo? false
  set eater-demo-activo? false
  set ultimo-glider-tick 0
  set intervalo-gliders 80

  ; Inicializar variables de input externo para compuerta NOT
  set input-a-activo? false
  set ultimo-input-tick 0
  set intervalo-input-a 30
end

;; =====================
;; CONDICIONES INICIALES
;; =====================
to inicializar-condiciones
  ; === LIMPIAR ESTADO ANTERIOR ===
  ask patches [
    set pcolor black
    set vecinos 0
    set nuevo-estado 0
  ]

  ; === CONFIGURACIÓN ALEATORIA POR DEFECTO ===
  ; Cada celda tiene probabilidad = densidad% de estar viva
  ask patches [
    if random 100 < densidad [
      set pcolor white
    ]
  ]
end

;; ====================
;; FUNCIÓN DE EVOLUCIÓN
;; ====================
;; Ejecuta una generación completa del Juego
to go
  ; === VALIDACIONES ===
  if not any? patches with [pcolor = white] [
    if modo-simulacion = "experimento" [
      set estabilizado? true
    ]
    user-message "Todas las células han muerto.\nUsa 'Reiniciar Experimento' para limpiar los Parámetros."
    stop
  ]

  ; Verificar estabilización
  if estabilizado? and modo-simulacion = "experimento" [
    user-message "La población se estabilizó.\nUsa 'Reiniciar Experimento' para limpiar los Parámetros."
    stop
  ]

  ; === FASE 1: CÁLCULO DE VECINDARIOS ===
  ; Contar vecinos vivos para cada célula usando vecindad de Moore
  calcular-vecinos-moore

  ; === FASE 2: APLICACIÓN DE REGLAS DE CONWAY ===
  ; Aplicar las reglas simultáneamente
  aplicar-reglas-conway

  ; === FASE 3: ACTUALIZACIÓN Y ESTADÍSTICAS ===
  actualizar-estadisticas
  if ticks mod 10 = 0 [ verificar-estabilidad ]
  ; Generar gliders automáticamente en demo Eater (si está activo)
  if eater-demo-activo? [ generar-glider-automatico ]
  ; Generar gliders de input externo A para compuerta NOT (si está activo)
  if input-a-activo? [ generar-input-a-externo ]
  set generacion generacion + 1
  tick
end

;; ============================
;; CÁLCULO DE VECINDARIOS MOORE
;; ============================
to calcular-vecinos-moore
  ; Cada célula considera sus 8 vecinos adyacentes
  ask patches [
    ifelse tipo-frontera = "Periódica" [
      ; Frontera periódica: el mundo se "envuelve" como un toro
      set vecinos count neighbors with [pcolor = white]
    ] [
      ; Frontera no periódica: células fuera del mundo se consideran muertas
      set vecinos calcular-vecinos-no-periodicos
    ]
  ]
end

;; ================================
;; CÁLCULO DE VECINOS NO PERIÓDICOS
;; ================================
to-report calcular-vecinos-no-periodicos
  let x pxcor
  let y pycor
  let contador 0

  ; Verificar cada vecino directamente
  if x > min-pxcor and y > min-pycor and [pcolor] of patch (x - 1) (y - 1) = white [ set contador contador + 1 ]
  if y > min-pycor and [pcolor] of patch x (y - 1) = white [ set contador contador + 1 ]
  if x < max-pxcor and y > min-pycor and [pcolor] of patch (x + 1) (y - 1) = white [ set contador contador + 1 ]
  if x > min-pxcor and [pcolor] of patch (x - 1) y = white [ set contador contador + 1 ]
  if x < max-pxcor and [pcolor] of patch (x + 1) y = white [ set contador contador + 1 ]
  if x > min-pxcor and y < max-pycor and [pcolor] of patch (x - 1) (y + 1) = white [ set contador contador + 1 ]
  if y < max-pycor and [pcolor] of patch x (y + 1) = white [ set contador contador + 1 ]
  if x < max-pxcor and y < max-pycor and [pcolor] of patch (x + 1) (y + 1) = white [ set contador contador + 1 ]

  report contador
end

;; ==============================
;; APLICACIÓN DE REGLAS DE CONWAY
;; ==============================
to aplicar-reglas-conway

  ask patches [
    ; === INICIALIZAR NUEVO ESTADO ===
    set nuevo-estado black  ; Por defecto, la célula muere o permanece muerta

    ; === REGLA DE NACIMIENTO ===
    ; Una célula muerta con exactamente 3 vecinos vivos nace
    if pcolor = black and vecinos = 3 [
      set nuevo-estado white
    ]

    ; === REGLAS DE SUPERVIVENCIA ===
    ; Una célula viva con 2 o 3 vecinos vivos sobrevive
    if pcolor = white and (vecinos = 2 or vecinos = 3) [
      set nuevo-estado white
    ]

    ; === REGLAS DE MUERTE ===
    ; Muerte por soledad: 0 o 1 vecinos
    ; Muerte por sobrepoblación: 4 o más vecinos
  ]

  ; === ACTUALIZACIÓN SIMULTÁNEA ===
  ; Aplicar todos los cambios al mismo tiempo
  ask patches [
    set pcolor nuevo-estado
  ]
end

;; =============================
;; ACTUALIZACIÓN DE ESTADÍSTICAS
;; =============================
to actualizar-estadisticas
  ; === CONTAR POBLACIÓN ACTUAL ===
  set poblacion-actual count patches with [pcolor = white]

  ; === ESTABLECER POBLACIÓN INICIAL ===
  if generacion = 0 and poblacion-inicial = 0 [
    ; Solo establecer población inicial UNA VEZ por experimento
    set poblacion-inicial poblacion-actual
    set poblacion-maxima poblacion-actual
    set poblacion-minima poblacion-actual
  ]

  ; === ACTUALIZAR EXTREMOS ===
  ; Siempre actualizar extremos
  if poblacion-actual > poblacion-maxima [
    set poblacion-maxima poblacion-actual
  ]
  if poblacion-actual < poblacion-minima [
    set poblacion-minima poblacion-actual
  ]

  ; === MANTENER HISTORIAL ===
  set historia-poblacion lput poblacion-actual historia-poblacion

  if length historia-poblacion > 30 [
    set historia-poblacion but-first historia-poblacion
  ]
end

;; ===========================
;; VERIFICACIÓN DE ESTABILIDAD
;; ===========================
to verificar-estabilidad
  ; === SOLO VERIFICAR EN EXPERIMENTOS DE DENSIDAD ===
  if modo-simulacion != "experimento" [
    stop
  ]

  ; === DETECTAR POBLACIÓN ESTABLE ===
  if length historia-poblacion >= 15 [
    let ultimas-15 sublist historia-poblacion (length historia-poblacion - 15) (length historia-poblacion)
    if all-equal? ultimas-15 [
      if not estabilizado? [
        set estabilizado? true
        ; Registrar tiempo de estabilización
        if tiempo-estabilizacion = -1 [ set tiempo-estabilizacion (generacion - 14) ]
      ]
    ]
  ]

  ; === DETECTAR EXTINCIÓN ===
  if poblacion-actual = 0 [
    stop
  ]
end

;; ====================
;; FUNCIONES AUXILIARES
;; ====================

;; Verifica si todos los elementos de una lista son iguales
to-report all-equal? [lista]
  if length lista <= 1 [ report true ]
  let primer-elemento first lista
  let i 1
  while [ i < length lista ] [
    if item i lista != primer-elemento [ report false ]
    set i i + 1
  ]
  report true
end

;; Verifica si dos listas son iguales
to-report equal-lists? [lista1 lista2]
  if length lista1 != length lista2 [ report false ]
  let i 0
  while [ i < length lista1 ] [
    if item i lista1 != item i lista2 [ report false ]
    set i i + 1
  ]
  report true
end

;; =====================
;; REPORTES ESTADÍSTICOS
;; =====================

;; Reporta la población actual
to-report poblacion-viva
  report count patches with [pcolor = white]
end

;; Reporta la población máxima alcanzada
to-report poblacion-maxima-alcanzada
  report poblacion-maxima
end

;; Reporta la población mínima alcanzada  
to-report poblacion-minima-alcanzada
  report poblacion-minima
end

;; Reporta la generación actual
to-report generacion-actual
  report generacion
end

;; Reporta la densidad actual
to-report densidad-actual
  let total-patches count patches
  let vivas count patches with [pcolor = white]
  if total-patches = 0 [ report 0 ]
  report precision (vivas / total-patches * 100) 2
end

;; Reporta si el sistema está estabilizado
to-report sistema-estable?
  report estabilizado?
end

;; Reporta el tamaño actual del mundo
to-report tamano-mundo
  report (max-pxcor - min-pxcor + 1)
end

;; ===========================================
;; CONFIGURACIONES PARA EJERCICIOS ESPECÍFICOS
;; ===========================================

;; Experimento 1: Retícula 100x100 con 50% densidad aleatoria
to setup-ejercicio-50-porciento
  clear-all

  ; Configurar parámetros del experimento
  set tamano-retícula 100
  set tipo-frontera "Periódica"
  set densidad 50
  set modo-simulacion "experimento"

  setup
end

;; Experimento 2: Retícula 100x100 con 85% densidad aleatoria
to setup-ejercicio-85-porciento
  clear-all

  ; Configurar parámetros del experimento
  set tamano-retícula 100
  set tipo-frontera "Periódica"
  set densidad 85
  set modo-simulacion "experimento"

  setup
end

;; Experimento 3: Retícula 100x100 con 35% densidad aleatoria
to setup-experimento-control
  clear-all

  ; Configurar parámetros del experimento
  set tamano-retícula 100
  set tipo-frontera "Periódica"
  set densidad 35
  set modo-simulacion "experimento"

  setup
end

;; Función para reiniciar experimento con nueva semilla aleatoria
to reiniciar-experimento
  clear-all
  clear-drawing
  clear-output
  clear-patches
  clear-turtles
  clear-links

  ; Limpiar explícitamente todos los patches
  ask patches [
    set pcolor black
    set vecinos 0
    set nuevo-estado 0
  ]

  ; Resetear todas las variables globales
  set generacion 0
  set poblacion-actual 0
  set poblacion-inicial 0
  set poblacion-maxima 0
  set poblacion-minima 0
  set historia-poblacion []
  set estabilizado? false
  set periodo-detectado 0
  set configuraciones-previas []
  set modo-simulacion "experimento"

  ; Resetear el contador de ticks
  reset-ticks

  ; Usar una nueva semilla aleatoria para generar diferentes configuraciones iniciales
  random-seed new-seed

  ; Mensaje de confirmación
  user-message "Mundo reiniciado completamente."
end

;; ================================
;; PATRONES PARA COMPUERTAS LÓGICAS
;; ================================

;; Crear un patrón Glider en posición específica
to crear-glider [x y]
  ;   111   ●●●
  ;   001 = ··●
  ;   010   ·●·
  ask patch x y [set pcolor white]             ; (0,0)  - Fila 1
  ask patch (x + 1) y [set pcolor white]       ; (1,0)  - Fila 1
  ask patch (x + 2) y [set pcolor white]       ; (2,0)  - Fila 1
  ask patch (x + 2) (y - 1) [set pcolor white] ; (2,-1) - Fila 2
  ask patch (x + 1) (y - 2) [set pcolor white] ; (1,-2) - Fila 3
end

;; Crear glider con orientación específica
to crear-glider-orientado [x y orientacion]
  ; Orientacion: "NE" (noreste), "NW" (noroeste), "SE" (sureste), "SW" (suroeste)

  if orientacion = "SE" [
    ; SE: se mueve hacia abajo-derecha (+X, -Y)
    ; ●●●
    ; ··●
    ; ·●·
    ask patch x y [set pcolor white]
    ask patch (x + 1) y [set pcolor white]
    ask patch (x + 2) y [set pcolor white]
    ask patch (x + 2) (y - 1) [set pcolor white]
    ask patch (x + 1) (y - 2) [set pcolor white]
  ]

  if orientacion = "NE" [
    ; NE: se mueve hacia arriba-derecha (+X, +Y)
    ; ·●·
    ; ··●
    ; ●●●
    ask patch (x + 1) (y + 2) [set pcolor white]
    ask patch (x + 2) (y + 1) [set pcolor white]
    ask patch x y [set pcolor white]
    ask patch (x + 1) y [set pcolor white]
    ask patch (x + 2) y [set pcolor white]
  ]

  if orientacion = "NW" [
    ; NW: se mueve hacia arriba-izquierda (-X, +Y)
    ; ·●·
    ; ●··
    ; ●●●
    ask patch (x + 1) (y + 2) [set pcolor white]
    ask patch x (y + 1) [set pcolor white]
    ask patch x y [set pcolor white]
    ask patch (x + 1) y [set pcolor white]
    ask patch (x + 2) y [set pcolor white]
  ]

  if orientacion = "SW" [
    ; SW: se mueve hacia abajo-izquierda (-X, -Y)
    ; ●●●
    ; ●··
    ; ·●·
    ask patch x y [set pcolor white]
    ask patch (x + 1) y [set pcolor white]
    ask patch (x + 2) y [set pcolor white]
    ask patch x (y - 1) [set pcolor white]
    ask patch (x + 1) (y - 2) [set pcolor white]
  ]
end

;; Crear un patrón Eater
to crear-eater [x y]

  ; Fila 0: 2o (bloque 2x2 superior izquierdo)
  ask patch (x + 0) (y + 0) [set pcolor white]
  ask patch (x + 1) (y + 0) [set pcolor white]

  ; Fila 1: obo (bloque 2x2 completo + inicio de cola)
  ask patch (x + 0) (y + 1) [set pcolor white]
  ask patch (x + 2) (y + 1) [set pcolor white]

  ; Fila 2: bo (continuación de la cola)
  ask patch (x + 2) (y + 2) [set pcolor white]

  ; Fila 3: b2o (bloque 2x2 inferior derecho)
  ask patch (x + 2) (y + 3) [set pcolor white]
  ask patch (x + 3) (y + 3) [set pcolor white]
end

;; Crear una Gosper Glider Gun
to crear-gosper-gun [x y]

  ; Bloque izquierdo (estabilizador)
  ask patch (x + 0) (y + 4) [set pcolor white]
  ask patch (x + 1) (y + 4) [set pcolor white]
  ask patch (x + 0) (y + 5) [set pcolor white]
  ask patch (x + 1) (y + 5) [set pcolor white]

  ; Emisor izquierdo
  ask patch (x + 10) (y + 4) [set pcolor white]
  ask patch (x + 10) (y + 5) [set pcolor white]
  ask patch (x + 10) (y + 6) [set pcolor white]
  ask patch (x + 11) (y + 3) [set pcolor white]
  ask patch (x + 11) (y + 7) [set pcolor white]
  ask patch (x + 12) (y + 2) [set pcolor white]
  ask patch (x + 12) (y + 8) [set pcolor white]
  ask patch (x + 13) (y + 2) [set pcolor white]
  ask patch (x + 13) (y + 8) [set pcolor white]
  ask patch (x + 14) (y + 5) [set pcolor white]
  ask patch (x + 15) (y + 3) [set pcolor white]
  ask patch (x + 15) (y + 7) [set pcolor white]
  ask patch (x + 16) (y + 4) [set pcolor white]
  ask patch (x + 16) (y + 5) [set pcolor white]
  ask patch (x + 16) (y + 6) [set pcolor white]
  ask patch (x + 17) (y + 5) [set pcolor white]

  ; Receptor derecho
  ask patch (x + 20) (y + 2) [set pcolor white]
  ask patch (x + 20) (y + 3) [set pcolor white]
  ask patch (x + 20) (y + 4) [set pcolor white]
  ask patch (x + 21) (y + 2) [set pcolor white]
  ask patch (x + 21) (y + 3) [set pcolor white]
  ask patch (x + 21) (y + 4) [set pcolor white]
  ask patch (x + 22) (y + 1) [set pcolor white]
  ask patch (x + 22) (y + 5) [set pcolor white]
  ask patch (x + 24) (y + 0) [set pcolor white]
  ask patch (x + 24) (y + 1) [set pcolor white]
  ask patch (x + 24) (y + 5) [set pcolor white]
  ask patch (x + 24) (y + 6) [set pcolor white]

  ; Bloque derecho (estabilizador)
  ask patch (x + 34) (y + 2) [set pcolor white]
  ask patch (x + 34) (y + 3) [set pcolor white]
  ask patch (x + 35) (y + 2) [set pcolor white]
  ask patch (x + 35) (y + 3) [set pcolor white]
end

;; =====================================
;; CONFIGURACIONES DE COMPUERTAS LÓGICAS
;; =====================================

;; Setup para demostrar patrón Glider
to setup-demo-glider
  clear-all
  resize-world -15 15 -15 15
  set-patch-size 5

  set tamano-retícula 30
  set tipo-frontera "Periódica"

  setup

  ; DESPUÉS configurar modo demo y reset de estabilización
  set modo-simulacion "demo"
  set estabilizado? false

  ask patches [set pcolor black]
  crear-glider 0 0
end

;; Función para generar gliders automáticamente en demo Eater
to generar-glider-automatico
  ; Solo generar si ha pasado suficiente tiempo desde el último glider
  if ticks >= (ultimo-glider-tick + intervalo-gliders) [
    ; Verificar si hay espacio libre en la zona de generación
    let zona-libre? true
    ask patches with [pxcor >= -18 and pxcor <= -14 and pycor >= -16 and pycor <= -12] [
      if pcolor = white [ set zona-libre? false ]
    ]

    ; Solo generar si la zona está libre
    if zona-libre? [
      crear-glider-orientado -16 -14 "SE"
      set ultimo-glider-tick ticks
    ]
  ]
end

;; Generar gliders de input externo A
to generar-input-a-externo
  ; Solo generar si ha pasado suficiente tiempo desde el último input A
  if ticks >= (ultimo-input-tick + intervalo-input-a) [
    ; Verificar si hay espacio libre en la zona de generación
    let zona-libre? true
    ask patches with [pxcor >= 5 and pxcor <= 9 and pycor >= 5 and pycor <= 9] [
      if pcolor = white [ set zona-libre? false ]
    ]

    ; Solo generar si la zona está libre
    if zona-libre? [
      crear-glider-orientado 7 7 "NW"
      set ultimo-input-tick ticks
    ]
  ]
end

;; Setup para demostrar patrón Eater
to setup-demo-eater
  clear-all
  resize-world -20 20 -20 20
  set-patch-size 5

  set tamano-retícula 40
  set tipo-frontera "Periódica"

  setup

  ; Configurar para demo
  set modo-simulacion "demo"
  set estabilizado? false

  ; Activar generación automática de gliders
  set eater-demo-activo? true
  set ultimo-glider-tick 0
  set intervalo-gliders 80

  ; Limpiar mundo y crear patrones
  ask patches [set pcolor black]

  crear-eater 0 0
  crear-glider-orientado -16 -14 "SE"
end

;; Setup para demostrar Pistola de Gosper
to setup-demo-gosper-gun
  clear-all
  resize-world -50 50 -50 50
  set-patch-size 5

  ; Configurar variables de interfaz
  set tipo-frontera "No Periódica"
  set densidad 50
  set tamano-retícula 100

  inicializar-variables

  ; Configurar modo demo específico
  set modo-simulacion "demo"
  set estabilizado? false

  crear-gosper-gun -45 -40

  reset-ticks
end

;; Setup para la compuerta NOT completa
to setup-compuerta-not
  set tamano-retícula 100
  set tipo-frontera "No Periódica"

  setup

  ; Configurar modo demo
  set modo-simulacion "demo"
  set estabilizado? false

  ask patches [set pcolor black]

  ; COMPUERTA NOT - INPUT EXTERNO A

  ; 1) GOSPER GUN:
  crear-gosper-gun -35 -25

  ; 2) INPUT EXTERNO A
  set input-a-activo? true
  set ultimo-input-tick 0
  set intervalo-input-a 30

  ; 3) Activar detector de salida
  set not-activo? true

  ; 4) Zona de colisiones frontales
  ask patch -10 -5 [ set pcolor red ]
  ask patch -9 -4 [ set pcolor red ]
  ask patch -8 -3 [ set pcolor red ]
  ask patch -7 -2 [ set pcolor red ]
  ask patch -6 -1 [ set pcolor red ]
end

;; Función para probar compuerta NOT sin entrada
to setup-compuerta-not-sin-entrada
  set tamano-retícula 100
  set tipo-frontera "No Periódica"

  setup

  set modo-simulacion "demo"
  set estabilizado? false

  ask patches [set pcolor black]

  ; 1) GOSPER GUN
  crear-gosper-gun -35 -25

  ; 2) NO HAY INPUT EXTERNO A
  set input-a-activo? false

  ; 3) Activar detector
  set not-activo? true

  ; 4) Marcar trayectoria libre
  ask patch -10 -5 [ set pcolor green ]
  ask patch -9 -4 [ set pcolor green ]
  ask patch -8 -3 [ set pcolor green ]
  ask patch -7 -2 [ set pcolor green ]
  ask patch -6 -1 [ set pcolor green ]
end
@#$#@#$#@
GRAPHICS-WINDOW
367
55
875
564
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-50
49
-50
49
0
0
1
ticks
60.0

BUTTON
24
60
94
95
Setup
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
104
60
174
95
Go
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
87
111
267
144
tamano-retícula
tamano-retícula
100
200
100.0
10
1
celdas
HORIZONTAL

SLIDER
87
151
267
184
densidad
densidad
0
100
35.0
1
1
%
HORIZONTAL

CHOOSER
104
196
242
241
tipo-frontera
tipo-frontera
"Periódica" "No Periódica"
0

MONITOR
957
98
1057
143
Población Actual
poblacion-viva
0
1
11

MONITOR
1407
98
1507
143
Densidad %
densidad-actual
2
1
11

MONITOR
1290
98
1390
143
Generación
generacion
0
1
11

PLOT
902
179
1581
423
Conteo de Células Vivas a Través del Tiempo
Generación
Número de Células Vivas
0.0
100.0
0.0
1000.0
true
true
"" ""
PENS
"Población Actual" 1.0 0 -16777216 true "" "plot poblacion-viva"
"Población Máxima" 1.0 0 -2674135 true "" "plot poblacion-maxima"
"Población Mínima" 1.0 0 -13345367 true "" "plot poblacion-minima"

TEXTBOX
23
260
173
278
EJERCICIOS DENSIDAD
11
0.0
1

BUTTON
19
334
169
369
50%
setup-ejercicio-50-porciento
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
19
379
169
414
85%
setup-ejercicio-85-porciento
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
19
288
169
323
35%
setup-experimento-control
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
187
60
337
95
Reiniciar Experimento
reiniciar-experimento
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1066
98
1166
143
Población Máxima
poblacion-maxima
0
1
11

MONITOR
1176
98
1276
143
Población Mínima
poblacion-minima
0
1
11

TEXTBOX
188
259
338
277
ELEMENTOS\n
11
0.0
1

BUTTON
186
287
336
322
Demo: Glider
setup-demo-glider
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
186
332
336
367
Demo: Eater
setup-demo-eater
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
185
379
335
414
Demo: Gosper Gun
setup-demo-gosper-gun
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
185
427
335
460
Compuerta NOT (A=1)
setup-compuerta-not
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
185
467
335
500
Compuerta NOT (A=0)
setup-compuerta-not-sin-entrada
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
25
25
337
69
Juego de la Vida de Conway
18
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
