;; =====================================
;; MODELO SIR CON DISTANCIAMIENTO SOCIAL
;; =====================================

;; VARIABLES GLOBALES
globals [
  ;; Variables para conteo de poblaciones
  cantidad-sanos        ; Número de personas sanas (susceptibles)
  cantidad-enfermos     ; Número de personas enfermas (infectados)
  cantidad-recuperados  ; Número de personas recuperadas

  ;; Variables para análisis epidemiológico
  pico-maximo          ; Máximo número de infectados simultáneos (Emax)
  tiempo-pico          ; Tiempo en que ocurre el pico (t*)
  
  ;; Variables para sistema de calles (mapa)
  color-calle          ; Color de las calles (blanco)
  color-fondo          ; Color del fondo/edificios
  calles               ; Agentset de patches que son calles
]

;; ==========================
;; PROPIEDADES DE LOS AGENTES
;; ==========================
turtles-own [
  ;; Variables de estado epidemiológico
  estado                ; Estado actual: "sano", "enfermo", "recuperado"

  ;; Variables de tiempo de infección
  tiempo-enfermo        ; Contador de tiempo que lleva enfermo
  tiempo-recuperacion   ; Tiempo necesario para recuperarse (personalizado por agente)

  ;; Variables de comportamiento
  aplica-distanciamiento?  ; Flag: true si este agente practica distanciamiento social

  ;; Variables para caminata aleatoria
  angulo-vision        ; Apertura del cono de visión para movimiento
]

;; =================
;; FUNCIÓN PRINCIPAL
;; =================
;; Inicializa el modelo SIR con los parámetros configurados
to setup
  ;; === FASE 1: LIMPIAR TURTLES Y PLOTS ===
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots
  clear-output
  
  ;; === FASE 2: CONFIGURAR MUNDO SOLO SI USA MAPA ===
  if usar-mapa? [
    ; MODO MAPA: Ajustar tamaño del mundo para mejor visualización
    resize-world -300 300 -300 300
    set-patch-size 1.1631
  ]
  
  ;; === FASE 3: CARGAR Y PROCESAR MAPA (OPCIONAL) ===
  ifelse usar-mapa? [
    ; Cargar mapa desde archivo PNG
    import-pcolors "media/5/mapa_anillo.png"
    
    ; Configurar colores para detección de calles
    set color-calle white
    set color-fondo black
    
    ; Identificar calles: patches con color blanco o cercano a blanco (pcolor > 9)
    set calles patches with [pcolor > 9]
    
    ; Verificar que hay calles disponibles
    if count calles = 0 [
      ; Si no hay calles detectadas, usar todas las patches
      set calles patches
      print "ADVERTENCIA: No se detectaron calles en el mapa"
    ]
    
  ] [
    ; Sin mapa: fondo blanco simple
    ask patches [
      set pcolor white
    ]
    
    ; Sin mapa, todas las patches son "calles" (transitables)
    set calles patches
    set color-calle white
    set color-fondo white
  ]

  ;; === FASE 4: CREAR POBLACIÓN DE AGENTES ===
  crear-poblacion

  ;; === FASE 5: ASIGNAR DISTANCIAMIENTO SOCIAL ===
  asignar-distanciamiento

  ;; === FASE 6: INFECTAR AGENTES INICIALES ===
  infectar-iniciales

  ;; === FASE 7: INICIALIZACIÓN DE VARIABLES ===
  set pico-maximo 0
  set tiempo-pico 0

  reset-ticks
  actualizar-contadores
end

;; ===============
;; CREAR POBLACIÓN
;; ===============
;; Crea la población inicial de agentes según densidad especificada
to crear-poblacion
  ;; Determinar cantidad de agentes según el modo
  let personas 0
  
  ifelse usar-mapa? [
    ;; CON MAPA: Usar slider específico de población-mapa (cantidad exacta)
    set personas poblacion-mapa
  ] [
    ;; SIN MAPA: Usar densidad porcentual como antes
    let cuadros count patches
    set personas (cuadros * densidad-pob) / 100
  ]

  ;; === CREAR AGENTES SANOS ===
  create-turtles personas [
    ;; Ubicación aleatoria en el mundo
    ifelse usar-mapa? [
      ;; CON MAPA: Colocar agentes solo sobre calles
      move-to one-of calles
    ] [
      ;; SIN MAPA: Ubicación aleatoria normal
      setxy random-xcor random-ycor
    ]

    ;; Estado inicial: sano (susceptible)
    set estado "sano"
    set color blue
    set shape "person"
    
    ;; Ajustar tamaño según el modo
    ifelse usar-mapa? [
      set size 15   ;; Más grandes en modo mapa (mundo 600x600)
    ] [
      set size 1.5  ;; Tamaño normal en modo sin mapa
    ]

    ;; Inicializar variables de tiempo
    set tiempo-enfermo 0
    set tiempo-recuperacion tiempo-enfermedad  ; Asignar tiempo base de enfermedad

    ;; Inicializar comportamiento
    set aplica-distanciamiento? false
    set angulo-vision wiggle  ; Ángulo de visión para movimiento
  ]
end

;; ==============================
;; ASIGNAR DISTANCIAMIENTO SOCIAL
;; ==============================
;; Selecciona aleatoriamente qué porcentaje de agentes aplicará distanciamiento
to asignar-distanciamiento
  ;; Calcular cuántos agentes harán distanciamiento
  let total-agentes count turtles
  let num-distanciamiento (total-agentes * distanciamiento-social) / 100

  ;; Seleccionar aleatoriamente los agentes que aplicarán distanciamiento
  ask n-of num-distanciamiento turtles [
    set aplica-distanciamiento? true
  ]
end

;; ==========================
;; INFECTAR AGENTES INICIALES
;; ==========================
;; Establece algunos agentes como infectados para iniciar la epidemia
to infectar-iniciales
  ;; Infectar el número especificado en el slider
  let num-infectados-inicial min (list infectados-iniciales (count turtles))

  ask n-of num-infectados-inicial turtles [
    set estado "enfermo"
    set color red
    set tiempo-enfermo 0
  ]
end

;; =====================
;; ACTUALIZAR CONTADORES
;; =====================
;; Actualiza las variables globales de conteo de poblaciones
to actualizar-contadores
  set cantidad-sanos count turtles with [estado = "sano"]
  set cantidad-enfermos count turtles with [estado = "enfermo"]
  set cantidad-recuperados count turtles with [estado = "recuperado"]

  ;; Registrar pico máximo de infectados
  if cantidad-enfermos > pico-maximo [
    set pico-maximo cantidad-enfermos
    set tiempo-pico ticks
  ]
end

;; ==============================
;; FUNCIÓN PRINCIPAL DE EVOLUCIÓN
;; ==============================
;; Ejecuta un paso de tiempo en el modelo SIR
to go
  ;; === CONDICIÓN DE PARADA ===
  ;; Detener si no quedan infectados (epidemia terminó)
  if cantidad-enfermos = 0 [
    print "La epidemia ha terminado"
    stop
  ]

  ;; === FASE 1: MOVIMIENTO ===
  ; Solo se mueven los agentes que NO aplican distanciamiento social
  ask turtles with [not aplica-distanciamiento?] [
    mover-agente
  ]

  ;; === FASE 2: CONTAGIO ===
  ; Los enfermos pueden contagiar a susceptibles cercanos
  ask turtles with [estado = "enfermo"] [
    intentar-contagio
  ]

  ;; === FASE 3: RECUPERACIÓN ===
  ; Los enfermos pueden recuperarse después de tiempo suficiente
  ask turtles with [estado = "enfermo"] [
    verificar-recuperacion
  ]

  ;; === FASE 4: ACTUALIZACIÓN ===
  actualizar-contadores

  tick  ; Incrementar contador de tiempo
end

;; ====================
;; MOVIMIENTO DE AGENTE
;; ====================
;; Implementa caminata aleatoria con rango de visión limitado
to mover-agente
  ifelse usar-mapa? [
    ;; === MOVIMIENTO SOBRE MAPA (SIGUIENDO CALLES) ===
    ;; Intentar varias veces encontrar una dirección válida
    let intentos 0
    let movio? false
    
    while [intentos < 20 and not movio?] [
      ;; Girar aleatoriamente dentro del rango de visión
      rt random-float wiggle - (wiggle / 2)
      
      ;; Verificar si el patch adelante es una calle (blanco: pcolor > 9)
      let patch-destino patch-ahead 3
      if patch-destino != nobody [
        if [pcolor] of patch-destino > 9 [
          ;; Si hay calle adelante (blanco), avanzar
          forward 3
          set movio? true
        ]
      ]
      
      set intentos intentos + 1
    ]
    
  ] [
    ;; === MOVIMIENTO NORMAL (SIN MAPA) ===
    ;; Girar dentro del rango de visión especificado
    rt random-float wiggle - (wiggle / 2)
    ;; Avanzar una unidad
    fd 1
  ]
end

;; =================
;; INTENTAR CONTAGIO
;; =================
;; Un agente enfermo intenta contagiar a vecinos sanos
to intentar-contagio
  ;; Obtener vecinos cercanos (radio ampliado en modo mapa)
  let vecinos-cercanos nobody
  
  ifelse usar-mapa? [
    ;; En modo mapa: radio mayor porque el mundo es más grande
    set vecinos-cercanos turtles in-radius 15
  ] [
    ;; En modo normal: vecindad de Moore estándar
    set vecinos-cercanos turtles-on neighbors
  ]

  ;; Filtrar solo los sanos (susceptibles)
  let vecinos-sanos vecinos-cercanos with [estado = "sano"]

  ;; Intentar contagiar a cada vecino sano con probabilidad PC
  ask vecinos-sanos [
    if random-float 1 < probabilidad-contagio [
      set estado "enfermo"
      set color red
      set tiempo-enfermo 0
    ]
  ]
end

;; ======================
;; VERIFICAR RECUPERACIÓN
;; ======================
;; Verifica si un agente enfermo debe recuperarse
to verificar-recuperacion
  ;; Incrementar tiempo de enfermedad
  set tiempo-enfermo tiempo-enfermo + 1

  ;; Si ha pasado el tiempo de recuperación, el agente se recupera
  if tiempo-enfermo >= tiempo-recuperacion [
    set estado "recuperado"
    set color green
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
220
10
916
707
-1
-1
6.88
1
10
1
1
1
0
1
1
1
0
99
0
99
0
0
1
ticks
30.0

SLIDER
16
116
206
149
densidad-pob
densidad-pob
10
100
30.0
1
1
%
HORIZONTAL

SLIDER
16
157
206
190
wiggle
wiggle
10
360
15.0
5
1
°
HORIZONTAL

SLIDER
16
198
206
231
probabilidad-contagio
probabilidad-contagio
0
1
0.8
0.01
1
NIL
HORIZONTAL

SLIDER
16
239
206
272
tiempo-enfermedad
tiempo-enfermedad
10
100
25.0
1
1
ticks
HORIZONTAL

SLIDER
16
280
206
313
distanciamiento-social
distanciamiento-social
0
100
0.0
5
1
%
HORIZONTAL

SLIDER
16
321
206
354
infectados-iniciales
infectados-iniciales
1
50
5.0
1
1
agentes
HORIZONTAL

SWITCH
16
362
206
395
usar-mapa?
usar-mapa?
1
1
-1000

SLIDER
16
403
206
436
poblacion-mapa
poblacion-mapa
10
500
200.0
10
1
agentes
HORIZONTAL

TEXTBOX
16
20
180
43
Modelo SIR + DS
18
0.0
1

BUTTON
16
54
89
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
95
54
168
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

TEXTBOX
18
96
168
114
Parámetros del Modelo:
12
0.0
1

PLOT
936
10
1396
200
Curvas SIR
Tiempo (ticks)
Población
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Sanos" 1.0 0 -13345367 true "" "plot cantidad-sanos"
"Enfermos" 1.0 0 -2674135 true "" "plot cantidad-enfermos"
"Recuperados" 1.0 0 -10899396 true "" "plot cantidad-recuperados"

MONITOR
936
215
1046
260
Sanos
cantidad-sanos
0
1
11

MONITOR
1054
215
1164
260
Enfermos
cantidad-enfermos
0
1
11

MONITOR
1172
215
1282
260
Recuperados
cantidad-recuperados
0
1
11

MONITOR
936
276
1096
321
Pico Máximo (Emax)
pico-maximo
0
1
11

MONITOR
1111
276
1271
321
Tiempo del Pico (t*)
tiempo-pico
0
1
11

MONITOR
1290
215
1396
260
Total Población
count turtles
0
1
11

MONITOR
1288
275
1398
320
Ticks
ticks
0
1
11

@#$#@#$#@
## MODELO SIR CON DISTANCIAMIENTO SOCIAL

Este modelo simula la propagación de una enfermedad infecciosa en una población usando el modelo epidemiológico SIR (Susceptible-Infectado-Recuperado) con la capacidad de implementar estrategias de distanciamiento social.

### CARACTERÍSTICAS PRINCIPALES

**Estados de los agentes:**
- **Sanos (Azul)**: Susceptibles de contagiarse
- **Enfermos (Rojo)**: Infectados que pueden contagiar a otros
- **Recuperados (Verde)**: Ya no pueden infectarse ni contagiar

**Reglas del modelo:**
1. **Contagio**: Si una persona sana tiene contacto con un enfermo en su vecindad de Moore, se contagia con probabilidad PC
2. **Recuperación**: Una persona enferma se recupera después de TE ticks
3. **Movimiento**: Caminata aleatoria con apertura de visión WIG (solo para agentes sin distanciamiento)
4. **Distanciamiento social**: Porcentaje DS de la población permanece estático

### PARÁMETROS

- **POB (10-100%)**: Densidad de población en el espacio
- **WIG (10-360°)**: Apertura del cono de visión para movimiento
- **PC (0-1)**: Probabilidad de contagio al tener contacto
- **TE (10-100)**: Tiempo que dura la enfermedad
- **DS (0-100%)**: Porcentaje de población que aplica distanciamiento

### CÓMO USAR

1. Ajustar los parámetros con los sliders
2. Presionar **Setup** para inicializar
3. Presionar **Go** para ejecutar la simulación
4. Observar las curvas SIR y los valores de pico

### ANÁLISIS

El modelo permite estudiar:
- Efecto del distanciamiento social en el pico de contagios
- Aplanamiento de la curva epidemiológica
- Dinámica temporal de la epidemia

### REFERENCIAS

Basado en el artículo de Harry Stevens sobre distanciamiento social y el modelo SIR clásico de epidemiología.
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
<experiments>
  <experiment name="Analisis_DS" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>pico-maximo</metric>
    <metric>tiempo-pico</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="densidad-pob">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiggle">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probabilidad-contagio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tiempo-enfermedad">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distanciamiento-social">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infectados-iniciales">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Analisis_DS_Mapa" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>pico-maximo</metric>
    <metric>tiempo-pico</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="usar-mapa?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poblacion-mapa">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiggle">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probabilidad-contagio">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tiempo-enfermedad">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distanciamiento-social">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
      <value value="60"/>
      <value value="65"/>
      <value value="70"/>
      <value value="75"/>
      <value value="80"/>
      <value value="85"/>
      <value value="90"/>
      <value value="95"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infectados-iniciales">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
