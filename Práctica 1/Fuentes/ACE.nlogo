;; ================================
;; AUTÓMATA CELULAR ELEMENTAL (ACE)
;; ================================

;; VARIABLES GLOBALES
globals[
  fila ; Fila actual de evolución (comienza en max-pycor y decrece)

  ;; Variables para la tabla de transiciones
  iii  ; 111
  iio  ; 110
  ioi  ; 101
  ioo  ; 100
  oii  ; 011
  oio  ; 010
  ooi  ; 001
  ooo  ; 000

  ;; Variables para control de simulación
  generacion    ; Contador de generaciones
  tiempo-actual ; Tiempo actual de simulación
  fila-actual   ; Fila actual de procesamiento

  ;; Variables para experimentos de sensibilidad
  estado-original       ; Almacena el estado inicial para comparación
  evolucion-original    ; Almacena toda la evolución original
  evolucion-perturbada  ; Almacena toda la evolución perturbada
  mostrando-diferencias ; Flag para modo de visualización
]

;; PROPIEDADES DE LOS PATCHES
patches-own [
  izquierda ; Color del vecino izquierdo
  centro    ; Color del patch actual
  derecha   ; Color del vecino derecho
]

;; =================
;; FUNCIÓN PRINCIPAL
;; =================
;; Inicializa el ACE con todos los parámetros configurados
to setup
  clear-all               ; Limpiar el mundo y resetear variables
  configurar-tamano       ; Ajustar dimensiones del mundo según parámetros
  set fila max-pycor      ; Comenzar evolución desde la fila superior
  establecer-regla regla  ; Convertir número de regla a tabla de transiciones
  inicializar-condiciones ; Configurar condiciones iniciales según opción elegida
  reset-ticks             ; Resetear contador de tiempo
end

;; =====================
;; FUNCIÓN DE VALIDACIÓN
;; =====================
to-report configuracion-valida?
  ifelse condicion-inicial = "Usuario" [
    ; Verificar que hay al menos una celda activa
    report (count patches with [pycor = max-pycor and pcolor = white]) > 0
  ] [
    ; Las configuraciones automáticas siempre son válidas
    report true
  ]
end

;; ======================================
;; CONFIGURACIÓN DE DIMENSIONES DEL MUNDO
;; ======================================
to configurar-tamano
  let mitad-ancho int (longitud / 2)      ; Calcular radio horizontal
  let alto-menos-1 (tiempo-evolucion - 1) ; Altura necesaria para evolución

  ; X: [-mitad-ancho, +mitad-ancho] para centrar el patrón
  ; Y: [-(tiempo-evolucion-1), 0] para evolución descendente
  resize-world (- mitad-ancho) mitad-ancho (- alto-menos-1) 0
end

;; =====================
;; FUNCIÓN DE TRANSICIÓN
;; =====================
;; Convierte el número de regla decimal (0-255) en una tabla de transiciones binaria
to establecer-regla [numero-regla]
  ; === VALIDACIÓN DE ENTRADA ===
  if numero-regla < 0 or numero-regla > 255 [
    user-message "Error: La regla debe estar entre 0 y 255"
    stop
  ]

  ; === CONVERSIÓN DECIMAL A BINARIO ===
  let binario []
  let temp numero-regla

  ; División sucesiva por 2
  repeat 8 [
    set binario lput (temp mod 2) binario ; Guardar bit menos significativo
    set temp int (temp / 2)               ; Desplazar bits hacia la derecha
  ]

  set ooo item 0 binario  ; 000 -> bit 0 (menos significativo)
  set ooi item 1 binario  ; 001 -> bit 1
  set oio item 2 binario  ; 010 -> bit 2
  set oii item 3 binario  ; 011 -> bit 3
  set ioo item 4 binario  ; 100 -> bit 4
  set ioi item 5 binario  ; 101 -> bit 5
  set iio item 6 binario  ; 110 -> bit 6
  set iii item 7 binario  ; 111 -> bit 7 (más significativo)
end

;; =====================
;; CONDICIONES INICIALES
;; =====================
to inicializar-condiciones
  ; === LIMPIAR ESTADO ANTERIOR ===
  ask patches [set pcolor black]

  ; === CONDICIÓN SIMPLE ===
  ; Una sola celda activa en el centro de la fila superior
  if condicion-inicial = "Simple" [
    ask patch 0 max-pycor [set pcolor white]
  ]

  ; === CONDICIÓN ALEATORIA ===
  ; Cada celda de la fila superior tiene 50% de probabilidad de estar activa
  if condicion-inicial = "Aleatoria" [
    ask patches with [pycor = max-pycor] [
      if random 2 = 1 [set pcolor white]
    ]
  ]

  ; === CONDICIÓN DEFINIDA POR USUARIO ===
  ; Permite configuración manual a través del botón "Por Coordenadas"
  if condicion-inicial = "Usuario" [
    ask patches with [pycor = max-pycor] [set pcolor black]
    user-message "Ahora usa el botón 'Por Coordenadas' para definir tu patrón inicial. Cuando termines, presiona 'Go' para ejecutar."
  ]
end



;; ====================================
;; CONFIGURACIÓN MANUAL POR COORDENADAS
;; ====================================
to configurar-por-coordenadas
  ; === PRERREQUISITOS ===
  if condicion-inicial != "Usuario" [
    user-message "Primero selecciona 'Usuario' en condicion-inicial y presiona 'Setup'"
    stop
  ]

  ; === INTERFAZ DE ENTRADA ===
  let coordenadas user-input "Ingresa las posiciones X de las celdas activas separadas por espacios.\nEjemplo: -2 0 2 (para activar celdas en posiciones -2, 0, 2)\nEjemplo: -5 -3 -1 1 3 5"

  ; === PROCESAMIENTO ===
  if coordenadas != false [
    configurar-desde-coordenadas coordenadas
  ]
end

;; =========================
;; PROCESADOR DE COORDENADAS
;; =========================
;; Analiza una cadena de texto con coordenadas y activa las celdas correspondientes
to configurar-desde-coordenadas [coords-string]
  ; === LIMPIAR CONFIGURACIÓN ANTERIOR ===
  ask patches with [pycor = max-pycor] [set pcolor black]

  ; === ALGORITMO DE PARSING ===
  let texto coords-string ; Cadena de entrada
  let i 0                 ; Índice de carácter actual
  let inicio-num 0        ; Inicio del número actual
  let en-numero false     ; Flag: estamos leyendo un número

  ; === PROCESAMIENTO CARÁCTER POR CARÁCTER ===
  repeat (length texto + 1) [
    let char ""
    if i < length texto [
      set char substring texto i (i + 1)
    ]

    ; === DETECTAR INICIO DE NÚMERO ===
    if (char >= "0" and char <= "9") or char = "-" [
      if not en-numero [
        set inicio-num i   ; Marcar inicio del número
        set en-numero true ; Activar flag de lectura
      ]
    ]

    ; === DETECTAR FIN DE NÚMERO ===
    if char = " " or i = length texto [
      if en-numero [
        ; === EXTRAER Y VALIDAR NÚMERO ===
        let num-str substring texto inicio-num i
        let numero read-from-string num-str

        if is-number? numero [
          ; === VERIFICAR RANGO VÁLIDO ===
          if numero >= min-pxcor and numero <= max-pxcor [
            ask patch numero max-pycor [set pcolor white]
          ]
        ]
        set en-numero false
      ]
    ]

    set i i + 1
  ]
end

;; ==============================
;; FUNCIÓN PRINCIPAL DE EVOLUCIÓN
;; ==============================
;; Ejecuta un paso de evolución del ACE aplicando las reglas de transición
to go
  ; === VALIDACIONES ===
  ; Verificar que existe una configuración inicial válida
  if not configuracion-valida? [
    user-message "No hay configuración inicial válida. Selecciona 'Usuario' en condicion-inicial, presiona Setup y usa 'Por Coordenadas' para definir tu patrón."
    stop
  ]

  ; === CONDICIONES DE PARADA ===
  if fila = min-pycor [stop]          ; Llegamos al fondo del mundo
  if ticks >= tiempo-evolucion [stop] ; Completamos el tiempo configurado

  ; === EVOLUCIÓN ===
  ; Aplicar reglas de transición a todas las celdas de la fila actual
  ask patches with [pycor = fila] [actualizar]

  ; === AVANCE TEMPORAL ===
  set fila (fila - 1) ; Mover a la siguiente fila
  tick                ; Incrementar contador de tiempo
end

;; ==================================
;; APLICACIÓN DE REGLAS DE TRANSICIÓN
;; ==================================
;; Función ejecutada por cada celda para calcular su estado en la siguiente generación
to actualizar
  ; === OBTENER VECINDARIO ===
  ; El comportamiento en los bordes depende del tipo de frontera seleccionado
  if tipo-frontera = "Periódica" [
    set izquierda obtener-vecino-izq-periodica ; Frontera tipo toro
    set derecha obtener-vecino-der-periodica
  ]
  if tipo-frontera = "Fija" [
    set izquierda obtener-vecino-izq-fija ; Frontera con valores fijos
    set derecha obtener-vecino-der-fija
  ]

  set centro pcolor ; Estado actual de la celda

  ; === APLICACIÓN DE LA TABLA DE TRANSICIONES ===
  ; Evaluar todas las 8 posibles configuraciones de vecindario
  let nuevo-estado black

  ; Configuración 111: izq=activo, centro=activo, der=activo
  if (izquierda = white and centro = white and derecha = white and iii = 1) [set nuevo-estado white]

  ; Configuración 110: izq=activo, centro=activo, der=inactivo
  if (izquierda = white and centro = white and derecha = black and iio = 1) [set nuevo-estado white]

  ; Configuración 101: izq=activo, centro=inactivo, der=activo
  if (izquierda = white and centro = black and derecha = white and ioi = 1) [set nuevo-estado white]

  ; Configuración 100: izq=activo, centro=inactivo, der=inactivo
  if (izquierda = white and centro = black and derecha = black and ioo = 1) [set nuevo-estado white]

  ; Configuración 011: izq=inactivo, centro=activo, der=activo
  if (izquierda = black and centro = white and derecha = white and oii = 1) [set nuevo-estado white]

  ; Configuración 010: izq=inactivo, centro=activo, der=inactivo
  if (izquierda = black and centro = white and derecha = black and oio = 1) [set nuevo-estado white]

  ; Configuración 001: izq=inactivo, centro=inactivo, der=activo
  if (izquierda = black and centro = black and derecha = white and ooi = 1) [set nuevo-estado white]

  ; Configuración 000: izq=inactivo, centro=inactivo, der=inactivo
  if (izquierda = black and centro = black and derecha = black and ooo = 1) [set nuevo-estado white]

  ; === APLICAR RESULTADO ===
  ; El nuevo estado se aplica a la celda de la fila inferior
  if pycor > min-pycor [
    ask patch-at 0 -1 [set pcolor nuevo-estado]
  ]
end

;; ===========================================
;; MANEJO DE FRONTERAS - TIPO PERIÓDICA (TORO)
;; ===========================================
;; En fronteras periódicas, el mundo se "envuelve" como un toro
;; El borde izquierdo se conecta con el borde derecho

;; Obtiene el vecino izquierdo con frontera periódica
to-report obtener-vecino-izq-periodica
  ifelse pxcor = min-pxcor [
    ; Si estamos en el borde izquierdo, el vecino izquierdo es el borde derecho
    report [pcolor] of patch max-pxcor pycor
  ] [
    ; En caso normal, el vecino izquierdo es la celda adyacente
    report [pcolor] of patch-at -1 0
  ]
end

;; Obtiene el vecino derecho con frontera periódica
to-report obtener-vecino-der-periodica
  ifelse pxcor = max-pxcor [
    ; Si estamos en el borde derecho, el vecino derecho es el borde izquierdo
    report [pcolor] of patch min-pxcor pycor
  ] [
    ; En caso normal, el vecino derecho es la celda adyacente
    report [pcolor] of patch-at 1 0
  ]
end

;; ===============================
;; MANEJO DE FRONTERAS - TIPO FIJA
;; ===============================
;; En fronteras fijas, los bordes tienen un valor constante (negro = inactivo)
;; No hay conexión entre bordes opuestos

;; Obtiene el vecino izquierdo con frontera fija
to-report obtener-vecino-izq-fija
  ifelse pxcor = min-pxcor [
    ; Si estamos en el borde izquierdo, el vecino es siempre inactivo
    report black
  ] [
    ; En caso normal, el vecino izquierdo es la celda adyacente
    report [pcolor] of patch-at -1 0
  ]
end

;; Obtiene el vecino derecho con frontera fija
to-report obtener-vecino-der-fija
  ifelse pxcor = max-pxcor [
    ; Si estamos en el borde derecho, el vecino es siempre inactivo
    report black
  ] [
    ; En caso normal, el vecino derecho es la celda adyacente
    report [pcolor] of patch-at 1 0
  ]
end

;; =======================
;; FUNCIONES PARA ANÁLISIS
;; =======================

;; Configura experimento de sensibilidad para Regla 30
to setup-sensibilidad-regla30
  ; Configurar parámetros automáticamente
  set regla 30
  set longitud 500
  set tiempo-evolucion 500
  set tipo-frontera "Periódica"
  set condicion-inicial "Aleatoria"

  ; Usar semilla fija
  random-seed 12345

  ; Inicializar modelo
  setup

  ; Guardar estado original usando coordenadas explícitas
  set estado-original []
  let x-coord min-pxcor
  while [ x-coord <= max-pxcor ] [
    let color-patch [pcolor] of patch x-coord max-pycor
    set estado-original lput color-patch estado-original
    set x-coord x-coord + 1
  ]

  ; Inicializar variables de evolución
  set evolucion-original []
  set evolucion-perturbada []
  set mostrando-diferencias false

  user-message "Experimento de sensibilidad configurado para Regla 30.\n1. Presiona 'Go' para evolucionar el estado original\n2. Usa 'Aplicar Perturbación' para generar y evolucionar estado perturbado\n3. Usa 'Mostrar Diferencias' para visualizar las diferencias"
end

;; Aplica perturbación y muestra diferencias
to aplicar-perturbacion-regla30
  if length estado-original = 0 [
    user-message "Error: Primero ejecuta 'Setup Sensibilidad Regla 30'"
    stop
  ]

  ; Si es la primera vez, ejecutar evolución original
  if length evolucion-original = 0 [
    ; Restaurar estado original
    clear-patches
    ask patches [ set pcolor gray ]

    let x-coord min-pxcor
    let i 0
    while [ x-coord <= max-pxcor and i < length estado-original ] [
      ask patch x-coord max-pycor [
        set pcolor item i estado-original
      ]
      set x-coord x-coord + 1
      set i i + 1
    ]

    ; Usar la función Go normal para evolucionar
    set fila max-pycor
    repeat tiempo-evolucion [
      if fila <= min-pycor [ stop ]

      ; Guardar fila actual antes de evolucionar
      let fila-datos []
      let x min-pxcor
      while [ x <= max-pxcor ] [
        set fila-datos lput ([pcolor] of patch x fila) fila-datos
        set x x + 1
      ]
      set evolucion-original lput fila-datos evolucion-original

      ; Evolucionar usando la lógica normal
      ask patches with [ pycor = fila ] [ actualizar ]
      set fila fila - 1
    ]

    user-message "Evolución original completada."
    stop
  ]

  ; Generar evolución perturbada
  clear-patches
  ask patches [ set pcolor gray ]

  ; Restaurar estado original
  let x-coord min-pxcor
  let i 0
  while [ x-coord <= max-pxcor and i < length estado-original ] [
    ask patch x-coord max-pycor [
      set pcolor item i estado-original
    ]
    set x-coord x-coord + 1
    set i i + 1
  ]

  ; Aplicar perturbación de un solo bit en posición central
  let posicion-central floor(longitud / 2)
  let x-central min-pxcor + posicion-central
  ask patch x-central max-pycor [
    ifelse pcolor = white [
      set pcolor black
    ] [
      set pcolor white
    ]
  ]

  ; Usar la función Go normal para evolucionar estado perturbado
  set fila max-pycor
  repeat tiempo-evolucion [
    if fila <= min-pycor [ stop ]

    ; Guardar fila actual antes de evolucionar
    let fila-datos []
    let x min-pxcor
    while [ x <= max-pxcor ] [
      set fila-datos lput ([pcolor] of patch x fila) fila-datos
      set x x + 1
    ]
    set evolucion-perturbada lput fila-datos evolucion-perturbada

    ; Evolucionar usando la lógica normal
    ask patches with [ pycor = fila ] [ actualizar ]
    set fila fila - 1
  ]

  user-message "Estado perturbado completado."
end

;; Muestra diferencias entre evolución original y perturbada
to mostrar-diferencias-sensibilidad
  if length evolucion-original = 0 or length evolucion-perturbada = 0 [
    user-message "Error: Primero debes ejecutar el experimento completo:\n1. Setup Sensibilidad Regla 30\n2. Aplicar Perturbación (dos veces)"
    stop
  ]

  clear-patches
  ask patches [ set pcolor gray ]

  ; Visualizar diferencias
  let num-filas length evolucion-original
  if length evolucion-perturbada < num-filas [
    set num-filas length evolucion-perturbada
  ]
  let fila-display max-pycor

  let fila-idx 0
  repeat num-filas [
    if fila-display < min-pycor [ stop ]

    let fila-original item fila-idx evolucion-original
    let fila-perturbada item fila-idx evolucion-perturbada

    let x-coord min-pxcor
    let celda-idx 0
    repeat longitud [
      if x-coord > max-pxcor [ stop ]
      if celda-idx >= length fila-original [ stop ]
      if celda-idx >= length fila-perturbada [ stop ]

      let color-original item celda-idx fila-original
      let color-perturbada item celda-idx fila-perturbada

      ask patch x-coord fila-display [
        ifelse color-original != color-perturbada [
          set pcolor red
        ] [
          set pcolor color-original
        ]
      ]

      set x-coord x-coord + 1
      set celda-idx celda-idx + 1
    ]

    set fila-display fila-display - 1
    set fila-idx fila-idx + 1
  ]

  set mostrando-diferencias true

  user-message "Diferencias mostradas en color rojo.\nLas áreas negras/blancas son idénticas en ambas evoluciones.\nSe observa cómo una perturbación mínima se propaga caóticamente."
end

;; Configura experimento para Regla 132
to setup-regla132-computo
  set regla 132
  set longitud 500
  set tiempo-evolucion 500
  set tipo-frontera "Periódica"
  set condicion-inicial "Simple"
  setup
  user-message "Regla 132 configurada.\nPresiona 'Go' para ver estructuras."
end

;; Configura experimento adicional para Regla 132 con patrón complejo
to setup-regla132-complejo
  set regla 132
  set longitud 500
  set tiempo-evolucion 500
  set tipo-frontera "Periódica"
  set condicion-inicial "Simple"
  setup

  ; Configurar patrón específico automáticamente (verificando límites)
  ask patches with [pycor = max-pycor] [set pcolor black]

  ; Verificar que las coordenadas estén dentro del rango
  if -10 >= min-pxcor and -10 <= max-pxcor [
    ask patch -10 max-pycor [set pcolor white]
  ]
  if -5 >= min-pxcor and -5 <= max-pxcor [
    ask patch -5 max-pycor [set pcolor white]
  ]
  if 0 >= min-pxcor and 0 <= max-pxcor [
    ask patch 0 max-pycor [set pcolor white]
  ]
  if 5 >= min-pxcor and 5 <= max-pxcor [
    ask patch 5 max-pycor [set pcolor white]
  ]
  if 10 >= min-pxcor and 10 <= max-pxcor [
    ask patch 10 max-pycor [set pcolor white]
  ]

  ; Cambiar a Usuario después de configurar el patrón
  set condicion-inicial "Usuario"

  user-message "Regla 132 con patrón complejo configurada.\nPresiona 'Go' para ver interacciones."
end

;; Configura experimento para Regla 110 - Condición simple
to setup-regla110-simple
  set regla 110
  set longitud 500
  set tiempo-evolucion 500
  set tipo-frontera "Periódica"
  set condicion-inicial "Simple"
  setup
  user-message "Regla 110 configurada.\nPresiona 'Go' para ver estructuras."
end

;; Configura experimento para Regla 90 - Triángulo de Sierpinski
to setup-regla90-sierpinski
  set regla 90
  set longitud 500
  set tiempo-evolucion 500
  set tipo-frontera "Periódica"
  set condicion-inicial "Simple"
  setup
  user-message "Regla 90 configurada.\nPresiona 'Go' para ver el fractal Triángulo de Sierpinski."
end

;; Configura experimento para Regla 22 - Condición simple
to setup-regla22-simple
  set regla 22
  set longitud 500
  set tiempo-evolucion 500
  set tipo-frontera "Periódica"
  set condicion-inicial "Simple"
  setup
  user-message "Regla 22 configurada.\nPresiona 'Go' para ver patrón fractal ordenado."
end

;; Configura experimento para Regla 22 - Condición aleatoria
to setup-regla22-aleatoria
  set regla 22
  set longitud 500
  set tiempo-evolucion 500
  set tipo-frontera "Periódica"
  set condicion-inicial "Aleatoria"
  setup
  user-message "Regla 22 con condición aleatoria configurada.\nPresiona 'Go' para ver comportamiento aparentemente caótico."
end

;; Guarda el estado actual en una variable temporal
to guardar-estado-inicial
  ask patches with [pycor = max-pycor] [
    set plabel-color pcolor  ; Usar plabel-color como almacén temporal
  ]
end

;; Perturba un bit aleatorio en la condición inicial
to perturbar-condicion-inicial
  ; Seleccionar una celda aleatoria en la fila superior
  let celda-perturbada one-of patches with [pycor = max-pycor]
  ask celda-perturbada [
    ; Cambiar su estado (negro <-> blanco)
    ifelse pcolor = black [
      set pcolor white
    ] [
      set pcolor black
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
250
10
759
519
-1
-1
1.0
1
10
1
1
1
0
1
1
1
-250
250
-499
0
0
0
1
ticks
30.0

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

INPUTBOX
24
110
154
170
regla
30.0
1
0
Number

SLIDER
24
180
204
213
longitud
longitud
50
500
500.0
1
1
celdas
HORIZONTAL

SLIDER
24
220
204
253
tiempo-evolucion
tiempo-evolucion
50
500
500.0
1
1
pasos
HORIZONTAL

CHOOSER
23
325
161
370
condicion-inicial
condicion-inicial
"Simple" "Aleatoria" "Usuario"
1

CHOOSER
23
272
161
317
tipo-frontera
tipo-frontera
"Fija" "Periódica"
1

BUTTON
22
392
122
425
Por Coordenadas
configurar-por-coordenadas
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
163
119
239
164
Regla Binaria
(word iii iio ioi ioo oii oio ooi ooo)
17
1
11

MONITOR
130
385
230
430
Celdas Activas
count patches with [pycor = max-pycor and pcolor = white]
17
1
11

TEXTBOX
771
18
921
36
REGLA 30
13
0.0
1

BUTTON
771
38
921
73
Setup Sensibilidad
setup-sensibilidad-regla30
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
771
78
921
113
Aplicar Perturbación
aplicar-perturbacion-regla30
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
773
172
923
190
REGLA 132
13
0.0
1

BUTTON
773
192
923
227
Setup Simple
setup-regla132-computo
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
773
232
923
267
Setup Complejo
setup-regla132-complejo
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
777
392
927
410
EXPLORACIÓN
13
0.0
1

BUTTON
777
412
927
447
Setup R110
setup-regla110-simple
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
777
452
927
487
Setup R90
setup-regla90-sierpinski
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
775
281
925
299
REGLA 22
13
0.0
1

BUTTON
775
301
925
336
Setup Simple
setup-regla22-simple
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
775
341
925
376
Setup Aleatoria
setup-regla22-aleatoria
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
772
120
922
155
Mostrar Diferencias
mostrar-diferencias-sensibilidad
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
23
240
63
Autómata Celular Elemental
16
0.0
1

@#$#@#$#@
## ¿QUÉ ES ESTO?

Este modelo implementa un **Autómata Celular Elemental (ACE)** completo según las especificaciones académicas. Los ACE son sistemas dinámicos discretos donde cada celda puede estar en uno de dos estados (activo/inactivo) y evoluciona según reglas locales basadas en su vecindario inmediato.

El modelo permite explorar las 256 reglas posibles de Wolfram, desde patrones simples hasta comportamientos complejos y caóticos, siendo una herramienta fundamental para el estudio de sistemas complejos y emergencia.

## ¿CÓMO FUNCIONA?

### Componentes Principales:
- **Celdas**: Cada patch representa una celda que puede estar activa (naranja) o inactiva (negra)
- **Vecindario**: Cada celda considera sus vecinos izquierdo y derecho (radio = 1)
- **Regla de Transición**: Un número del 0-255 que define cómo evoluciona cada configuración de vecindario
- **Evolución Temporal**: El sistema evoluciona de arriba hacia abajo, generación tras generación

### Algoritmo de Evolución:
1. **Análisis**: Cada celda examina su vecindario (izquierda-centro-derecha)
2. **Consulta**: Busca en la tabla de transiciones el nuevo estado correspondiente
3. **Aplicación**: El nuevo estado se asigna a la celda de la fila inferior
4. **Iteración**: El proceso se repite para todas las filas hasta completar la evolución

## ¿CÓMO USAR EL MODELO?

### Controles Principales:
- **regla**: Número de regla (0-255) que define el comportamiento del ACE
- **longitud**: Número de celdas horizontales (50-500)
- **tiempo-evolucion**: Número de generaciones a simular (50-500)
- **tipo-frontera**: 
  - *Periódica*: Los bordes se conectan (toro)
  - *Fija*: Los bordes tienen valor constante (negro)
- **condicion-inicial**:
  - *Simple*: Una celda activa en el centro
  - *Aleatoria*: Distribución aleatoria 50%
  - *Usuario*: Configuración manual

### Procedimiento de Uso:
1. **Configurar parámetros**: Ajustar regla, longitud y tiempo de evolución
2. **Seleccionar frontera**: Elegir entre periódica o fija
3. **Definir condición inicial**: Simple, aleatoria o manual
4. **Presionar Setup**: Inicializar el sistema
5. **Si eligió "Usuario"**: Usar botón "Por Coordenadas" para definir patrón
6. **Presionar Go**: Iniciar la evolución del ACE

### Monitores:
- **Regla Binaria**: Muestra la representación binaria de la regla actual
- **Celdas Activas**: Cuenta las celdas activas en la fila inicial

## COSAS A OBSERVAR

### Patrones Fascinantes:
- **Regla 30**: Comportamiento caótico, genera números pseudoaleatorios
- **Regla 90**: Crea el fractal Triángulo de Sierpinski
- **Regla 110**: Turing-completa, puede realizar cualquier computación
- **Regla 184**: Modela flujo de tráfico vehicular

### Comportamientos Emergentes:
- **Periodicidad**: Algunos patrones se repiten cíclicamente
- **Propagación**: Estructuras que se mueven a velocidad constante
- **Extinción**: Patrones que tienden a desaparecer
- **Caos**: Comportamiento aparentemente aleatorio pero determinista

## COSAS A PROBAR

### Experimentos Sugeridos:
1. **Comparar fronteras**: Misma regla con fronteras periódica vs fija
2. **Sensibilidad inicial**: Pequeños cambios en condiciones iniciales
3. **Reglas famosas**: Probar reglas 30, 90, 110, 184
4. **Patrones simétricos**: Usar condición inicial simple
5. **Análisis estadístico**: Usar condición aleatoria y observar densidades

### Configuraciones Interesantes:
- **Regla 150 + condición simple**: Patrón fractal
- **Regla 225 + frontera periódica**: Propagación de estructuras
- **Regla 18 + configuración manual**: Patrones localizados

## EXTENDIENDO EL MODELO

### Posibles Mejoras:
- **Análisis estadístico**: Gráficos de densidad y entropía
- **Detección de periodicidad**: Identificar ciclos automáticamente
- **Clasificación de Wolfram**: Implementar las 4 clases de comportamiento
- **ACE bidimensionales**: Extender a autómatas de von Neumann o Moore
- **Reglas totalizadoras**: Implementar reglas basadas en suma de vecinos

## CARACTERÍSTICAS DE NETLOGO

### Técnicas Implementadas:
- **Conversión decimal-binaria**: Algoritmo manual para reglas de transición
- **Parser de texto**: Análisis manual de cadenas para configuración por coordenadas
- **Manejo de fronteras**: Implementación de topologías toro y fija
- **Validación robusta**: Verificación de parámetros y estados válidos
- **Interfaz adaptativa**: Mensajes contextuales según el modo de operación

### Limitaciones Superadas:
- NetLogo 6.2.0 no tiene funciones split nativas (implementamos parser manual)
- Manejo explícito de casos de borde para diferentes tipos de frontera
- Optimización de memoria para mundos grandes

## MODELOS RELACIONADOS

### En la Librería de NetLogo:
- **CA 1D Elementary**: Versión básica de autómatas celulares
- **CA 1D Totalistic**: Autómatas basados en suma de vecinos
- **Life**: Juego de la Vida (ACE bidimensional)

### Referencias Académicas:
- Wolfram, S. "A New Kind of Science" (2002)
- Estudios sobre complejidad computacional en ACE
- Aplicaciones en criptografía y generación de números aleatorios

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
