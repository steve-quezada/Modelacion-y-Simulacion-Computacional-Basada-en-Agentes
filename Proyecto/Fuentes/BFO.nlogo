;; ==========================================
;; BACTERIAL FORAGING OPTIMIZATION (BFO)
;; Modelo Basado en Agentes para Optimización
;; ==========================================

;; VARIABLES GLOBALES
globals [
  mejor-fitness           ;; Mejor valor de fitness encontrado
  mejor-posicion-x        ;; Coordenada X de la mejor solución
  mejor-posicion-y        ;; Coordenada Y de la mejor solución
  fitness-promedio        ;; Fitness promedio de la población
  paso-quimiotactico      ;; Contador de pasos quimiotácticos
  ciclo-reproduccion      ;; Contador de ciclos de reproducción
  ciclo-eliminacion       ;; Contador de ciclos eliminación-dispersión
  poblacion-inicial       ;; Número inicial de bacterias
  nutrientes-totales      ;; Suma total de nutrientes en el ambiente
  nutrientes-iniciales    ;; Nutrientes al inicio (para porcentaje)
]

;; ==========================
;; PROPIEDADES DE LOS AGENTES
;; ==========================
turtles-own [
  fitness                 ;; Valor de fitness actual de la bacteria
  fitness-anterior        ;; Fitness en la posición anterior
  salud-acumulada         ;; Suma de fitness durante quimiotaxis (para reproducción)
  direccion-x             ;; Componente X del vector de dirección
  direccion-y             ;; Componente Y del vector de dirección
  pasos-swim              ;; Contador de pasos en modo swim
  en-swim?                ;; ¿Está en modo swim (explotación)?
]

;; ==========================
;; PROPIEDADES DE LOS PATCHES
;; ==========================
patches-own [
  valor-funcion           ;; Valor de la función objetivo en este patch
  es-obstaculo?           ;; ¿Es un obstáculo infranqueable?
  nivel-nutrientes        ;; Cantidad de nutrientes disponibles (0-100)
  nutrientes-base         ;; Nivel original de nutrientes (para regeneración)
]

;; =================
;; FUNCIÓN PRINCIPAL
;; =================
;; Inicializa el modelo BFO con los parámetros configurados
to setup
  clear-all

  ;; Inicializar el paisaje de fitness (función objetivo)
  inicializar-paisaje

  ;; Crear población de bacterias
  crear-bacterias

  ;; Inicializar contadores
  set paso-quimiotactico 0
  set ciclo-reproduccion 0
  set ciclo-eliminacion 0
  set poblacion-inicial poblacion

  ;; Calcular fitness inicial
  ask turtles [
    calcular-fitness
    set salud-acumulada 0
  ]

  ;; Encontrar mejor solución inicial
  actualizar-mejor-global
  actualizar-estadisticas

  reset-ticks
end

;; ==============================
;; INICIALIZAR PAISAJE DE FITNESS
;; ==============================
;; Crea la función objetivo que las bacterias intentarán optimizar
to inicializar-paisaje
  ;; Configurar tamaño del mundo
  resize-world (- tamano-mundo / 2) (tamano-mundo / 2 - 1) (- tamano-mundo / 2) (tamano-mundo / 2 - 1)
  ;; Patch-size dinámico: 600/tamano-mundo (50→12, 100→6, 200→3)
  set-patch-size 600 / tamano-mundo

  ask patches [
    ;; Inicializar como no-obstáculo
    set es-obstaculo? false

    ;; Calcular valor de la función según la función seleccionada
    set valor-funcion calcular-funcion-objetivo pxcor pycor

    ;; Inicializar nutrientes - valor fijo para todos los patches
    ;; Esto hace más visible el efecto del consumo
    set nivel-nutrientes 100
    set nutrientes-base 100

    ;; Colorear según el valor (verde = bueno, rojo = malo)
    let valor-normalizado normalizar-valor valor-funcion
    set pcolor scale-color green valor-normalizado 1 0
  ]

  ;; Generar obstáculos si está habilitado
  if usar-obstaculos? [
    generar-obstaculos
  ]

  ;; Calcular nutrientes totales iniciales
  set nutrientes-totales sum [nivel-nutrientes] of patches with [not es-obstaculo?]
  set nutrientes-iniciales nutrientes-totales
end

;; ==============================
;; GENERAR OBSTÁCULOS EN EL MUNDO
;; ==============================
;; Crea zonas de obstáculos que las bacterias no pueden atravesar
to generar-obstaculos
  ;; Calcular número de obstáculos basado en densidad
  let num-obstaculos round ((count patches) * densidad-obstaculos / 100)

  ;; Crear obstáculos en posiciones aleatorias (evitando el centro donde está el óptimo)
  let patches-candidatos patches with [
    ;; Evitar poner obstáculos muy cerca del óptimo (centro)
    distancexy 0 0 > tamano-mundo / 6
  ]

  ask n-of (min list num-obstaculos count patches-candidatos) patches-candidatos [
    set es-obstaculo? true
    set nivel-nutrientes 0
    set pcolor gray

    ;; Expandir obstáculo a vecinos para crear bloques más grandes
    if tamano-obstaculos > 1 [
      ask n-of (min list (tamano-obstaculos - 1) count neighbors) neighbors [
        if distancexy 0 0 > tamano-mundo / 6 [
          set es-obstaculo? true
          set nivel-nutrientes 0
          set pcolor gray
        ]
      ]
    ]
  ]
end

;; =========================
;; CALCULAR FUNCIÓN OBJETIVO
;; =========================
;; Reporta el valor de la función objetivo en las coordenadas dadas
;; Valores MENORES son MEJORES (minimización)
to-report calcular-funcion-objetivo [x y]
  ;; Normalizar coordenadas al rango [-5, 5] para las funciones
  let x-norm (x / (tamano-mundo / 2)) * 5
  let y-norm (y / (tamano-mundo / 2)) * 5

  if funcion-objetivo = "Sphere" [
    ;; f(x,y) = x² + y² - Mínimo en (0,0)
    report (x-norm ^ 2) + (y-norm ^ 2)
  ]

  if funcion-objetivo = "Rastrigin" [
    ;; f(x,y) = 20 + x² + y² - 10(cos(2πx) + cos(2πy)) - Mínimo en (0,0)
    ;; NetLogo usa grados: convertir radianes a grados multiplicando por (180/pi)
    let angulo-x 2 * pi * x-norm * (180 / pi)
    let angulo-y 2 * pi * y-norm * (180 / pi)
    report 20 + (x-norm ^ 2) + (y-norm ^ 2) - 10 * (cos angulo-x + cos angulo-y)
  ]

  if funcion-objetivo = "Ackley" [
    ;; Función Ackley - Mínimo en (0,0)
    ;; NetLogo usa grados: convertir radianes a grados
    let sum1 (x-norm ^ 2) + (y-norm ^ 2)
    let angulo-x 2 * pi * x-norm * (180 / pi)
    let angulo-y 2 * pi * y-norm * (180 / pi)
    let sum2 cos angulo-x + cos angulo-y
    report -20 * exp (-0.2 * sqrt (sum1 / 2)) - exp (sum2 / 2) + 20 + exp 1
  ]

  if funcion-objetivo = "Himmelblau" [
    ;; f(x,y) = (x² + y - 11)² + (x + y² - 7)² - Cuatro mínimos
    report ((x-norm ^ 2) + y-norm - 11) ^ 2 + (x-norm + (y-norm ^ 2) - 7) ^ 2
  ]

  ;; Default: Sphere
  report (x-norm ^ 2) + (y-norm ^ 2)
end

;; ==============================
;; NORMALIZAR VALOR PARA COLOREAR
;; ==============================
to-report normalizar-valor [val]
  ;; Normaliza el valor al rango [0, 1] para colorear
  let max-val 50  ;; Valor máximo esperado
  let resultado 1 - (min list val max-val) / max-val
  report max list 0 (min list 1 resultado)
end

;; ============================
;; CREAR POBLACIÓN DE BACTERIAS
;; ============================
;; Crea las bacterias distribuidas aleatoriamente (evitando obstáculos)
to crear-bacterias
  create-turtles poblacion [
    ;; Buscar posición válida (no en obstáculo)
    mover-a-patch-valido
    set shape "bug"
    set size 1.5
    set color blue
    set fitness 0
    set fitness-anterior 0
    set salud-acumulada 0
    set direccion-x 0
    set direccion-y 0
    set pasos-swim 0
    set en-swim? false
  ]
end

;; ==============================
;; FUNCIÓN PRINCIPAL DE EVOLUCIÓN
;; ==============================
;; Ejecuta un tick del modelo BFO
to go
  ;; Verificar condición de parada
  if ticks >= max-ticks [
    stop
  ]

  ;; === FASE DE QUIMIOTAXIS ===
  ask turtles [
    ejecutar-quimiotaxis
  ]

  set paso-quimiotactico paso-quimiotactico + 1

  ;; === FASE DE SWARMING (opcional) ===
  if usar-swarming? [
    aplicar-swarming
  ]

  ;; === EXTENSIÓN: REGENERACIÓN DE NUTRIENTES ===
  if usar-nutrientes-agotables? [
    regenerar-nutrientes
    actualizar-nutrientes-totales
  ]

  ;; === FASE DE REPRODUCCIÓN ===
  if paso-quimiotactico >= Nc [
    ejecutar-reproduccion
    set paso-quimiotactico 0
    set ciclo-reproduccion ciclo-reproduccion + 1

    ;; Reiniciar salud acumulada
    ask turtles [
      set salud-acumulada 0
    ]
  ]

  ;; === FASE DE ELIMINACIÓN-DISPERSIÓN ===
  if ciclo-reproduccion >= Nre [
    ejecutar-eliminacion-dispersion
    set ciclo-reproduccion 0
    set ciclo-eliminacion ciclo-eliminacion + 1
  ]

  ;; Actualizar estadísticas
  actualizar-mejor-global
  actualizar-estadisticas

  tick
end

;; ===============================
;; EXTENSIÓN: REGENERAR NUTRIENTES
;; ===============================
;; Los nutrientes se regeneran lentamente con el tiempo
to regenerar-nutrientes
  ask patches with [not es-obstaculo? and nivel-nutrientes < nutrientes-base] [
    ;; Regenerar según tasa (0 = sin regeneración, 2 = rápida)
    set nivel-nutrientes min list nutrientes-base (nivel-nutrientes + tasa-regeneracion)
    actualizar-color-patch
  ]
end

;; =============================
;; ACTUALIZAR NUTRIENTES TOTALES
;; =============================
to actualizar-nutrientes-totales
  set nutrientes-totales sum [nivel-nutrientes] of patches with [not es-obstaculo?]
end

;; ===================
;; FASE 1: QUIMIOTAXIS
;; ===================
;; Implementa el comportamiento run-and-tumble de cada bacteria
to ejecutar-quimiotaxis
  ;; Guardar fitness anterior
  set fitness-anterior fitness

  ifelse en-swim? [
    ;; === MODO SWIM: continuar en la misma dirección ===
    ejecutar-swim
  ]
  [
    ;; === MODO TUMBLE: generar nueva dirección aleatoria ===
    ejecutar-tumble
  ]

  ;; Calcular nuevo fitness
  calcular-fitness

  ;; Acumular salud para reproducción
  set salud-acumulada salud-acumulada + fitness

  ;; Colorear según estado
  actualizar-color-bacteria
end

;; ========================
;; EJECUTAR TUMBLE (VOLTEO)
;; ========================
;; Genera una nueva dirección aleatoria y se mueve
to ejecutar-tumble
  ;; Generar vector de dirección aleatorio unitario
  let angulo random-float 360
  set direccion-x cos angulo
  set direccion-y sin angulo

  ;; Calcular nueva posición propuesta
  let nuevo-x xcor + (paso-C * direccion-x)
  let nuevo-y ycor + (paso-C * direccion-y)

  ;; Verificar límites del mundo (para frontera no periódica)
  if tipo-frontera = "No Periódica" [
    set nuevo-x max list min-pxcor (min list max-pxcor nuevo-x)
    set nuevo-y max list min-pycor (min list max-pycor nuevo-y)
  ]

  ;; Para frontera periódica, normalizar coordenadas para verificar obstáculo
  let check-x nuevo-x
  let check-y nuevo-y
  if tipo-frontera = "Periódica" [
    ;; Wrap-around manual para la verificación
    let ancho (max-pxcor - min-pxcor + 1)
    let alto (max-pycor - min-pycor + 1)
    set check-x min-pxcor + ((nuevo-x - min-pxcor) mod ancho)
    set check-y min-pycor + ((nuevo-y - min-pycor) mod alto)
    if check-x < min-pxcor [ set check-x check-x + ancho ]
    if check-y < min-pycor [ set check-y check-y + alto ]
  ]

  ;; === EXTENSIÓN: VERIFICAR OBSTÁCULOS ===
  let patch-destino patch check-x check-y
  ifelse patch-destino != nobody and [es-obstaculo?] of patch-destino [
    ;; Hay obstáculo: la bacteria rebota (intenta otra dirección)
    ;; Intentar 3 direcciones alternativas antes de quedarse
    let intentos 0
    let movimiento-exitoso? false
    while [intentos < 3 and not movimiento-exitoso?] [
      set angulo random-float 360
      set direccion-x cos angulo
      set direccion-y sin angulo
      set nuevo-x xcor + (paso-C * direccion-x)
      set nuevo-y ycor + (paso-C * direccion-y)
      if tipo-frontera = "No Periódica" [
        set nuevo-x max list min-pxcor (min list max-pxcor nuevo-x)
        set nuevo-y max list min-pycor (min list max-pycor nuevo-y)
      ]
      ;; Recalcular check para frontera periódica
      set check-x nuevo-x
      set check-y nuevo-y
      if tipo-frontera = "Periódica" [
        let ancho (max-pxcor - min-pxcor + 1)
        let alto (max-pycor - min-pycor + 1)
        set check-x min-pxcor + ((nuevo-x - min-pxcor) mod ancho)
        set check-y min-pycor + ((nuevo-y - min-pycor) mod alto)
        if check-x < min-pxcor [ set check-x check-x + ancho ]
        if check-y < min-pycor [ set check-y check-y + alto ]
      ]
      set patch-destino patch check-x check-y
      if patch-destino != nobody and not [es-obstaculo?] of patch-destino [
        set movimiento-exitoso? true
      ]
      set intentos intentos + 1
    ]

    ;; Solo moverse si encontró camino libre
    if movimiento-exitoso? [
      setxy nuevo-x nuevo-y
      consumir-nutrientes
    ]
  ]
  [
    ;; No hay obstáculo: moverse normalmente
    setxy nuevo-x nuevo-y
    consumir-nutrientes
  ]

  ;; Después del tumble, reiniciar estado de swim
  set pasos-swim 0
  set en-swim? false
end

;; ====================
;; EJECUTAR SWIM (NADO)
;; ====================
;; Continúa moviéndose en la misma dirección si hay mejora
to ejecutar-swim
  ;; Incrementar contador de pasos swim
  set pasos-swim pasos-swim + 1

  ;; Calcular nueva posición propuesta
  let nuevo-x xcor + (paso-C * direccion-x)
  let nuevo-y ycor + (paso-C * direccion-y)

  ;; Verificar límites del mundo
  if tipo-frontera = "No Periódica" [
    set nuevo-x max list min-pxcor (min list max-pxcor nuevo-x)
    set nuevo-y max list min-pycor (min list max-pycor nuevo-y)
  ]

  ;; Para frontera periódica, normalizar coordenadas para verificar obstáculo
  let check-x nuevo-x
  let check-y nuevo-y
  if tipo-frontera = "Periódica" [
    let ancho (max-pxcor - min-pxcor + 1)
    let alto (max-pycor - min-pycor + 1)
    set check-x min-pxcor + ((nuevo-x - min-pxcor) mod ancho)
    set check-y min-pycor + ((nuevo-y - min-pycor) mod alto)
    if check-x < min-pxcor [ set check-x check-x + ancho ]
    if check-y < min-pycor [ set check-y check-y + alto ]
  ]

  ;; === EXTENSIÓN: VERIFICAR OBSTÁCULOS ===
  let patch-destino patch check-x check-y
  ifelse patch-destino != nobody and [es-obstaculo?] of patch-destino [
    ;; Hay obstáculo: detener swim y forzar tumble
    set en-swim? false
    set pasos-swim 0
  ]
  [
    ;; No hay obstáculo: moverse
    setxy nuevo-x nuevo-y

    ;; Consumir nutrientes al llegar
    consumir-nutrientes

    ;; Calcular fitness en nueva posición
    let nuevo-fitness [valor-funcion] of patch-here

    ;; Decidir si continuar swim o volver a tumble
    ifelse nuevo-fitness < fitness-anterior and pasos-swim < Ns [
      ;; Mejoró y no alcanzó límite: continuar swim
      set en-swim? true
    ]
    [
      ;; No mejoró o alcanzó límite Ns: siguiente será tumble
      set en-swim? false
      set pasos-swim 0
    ]
  ]
end

;; ==============================
;; EXTENSIÓN: CONSUMIR NUTRIENTES
;; ==============================
;; Las bacterias consumen nutrientes del patch donde están
to consumir-nutrientes
  if usar-nutrientes-agotables? [
    ask patch-here [
      if not es-obstaculo? and nivel-nutrientes > 0 [
        ;; Consumir nutrientes directamente (tasa-consumo unidades)
        set nivel-nutrientes max list 0 (nivel-nutrientes - tasa-consumo)

        ;; Actualizar color del patch según nutrientes restantes
        actualizar-color-patch
      ]
    ]
  ]
end

;; =========================
;; ACTUALIZAR COLOR DE PATCH
;; =========================
;; Colorea el patch según sus nutrientes restantes
to actualizar-color-patch
  if not es-obstaculo? [
    ;; Mezclar color de fitness con nivel de nutrientes
    let valor-normalizado normalizar-valor valor-funcion
    let factor-nutrientes nivel-nutrientes / 100

    ;; Si hay pocos nutrientes, el patch se vuelve más marrón/amarillo
    ifelse factor-nutrientes < 0.3 [
      ;; Casi agotado: amarillo-marrón
      set pcolor scale-color yellow (1 - factor-nutrientes) 0 1
    ]
    [
      ;; Nutrientes suficientes: verde normal
      set pcolor scale-color green valor-normalizado 1 0
    ]
  ]
end

;; ================
;; CALCULAR FITNESS
;; ================
;; Calcula el valor de fitness de la bacteria en su posición actual
to calcular-fitness
  set fitness [valor-funcion] of patch-here

  ;; Después de un tumble, decidir si hacer swim en el siguiente paso
  ;; Solo si mejoró Y no estábamos ya en swim Y no alcanzamos límite
  if not en-swim? and fitness < fitness-anterior and pasos-swim < Ns [
    set en-swim? true
  ]
end

;; ===========================
;; FASE 2: SWARMING (ENJAMBRE)
;; ===========================
;; Aplica interacción célula-célula (atracción-repulsión)
to aplicar-swarming
  ask turtles [
    let mi-x xcor
    let mi-y ycor
    let fuerza-x 0
    let fuerza-y 0

    ask other turtles [
      let diff-x xcor - mi-x
      let diff-y ycor - mi-y
      let dist sqrt ((diff-x ^ 2) + (diff-y ^ 2))

      if dist > 0 [
        ;; Atracción a distancia media, repulsión cercana
        let atraccion d-attract * exp (- w-attract * (dist ^ 2))
        let repulsion h-repellant * exp (- w-repellant * (dist ^ 2))
        let fuerza-neta (atraccion - repulsion) / dist

        set fuerza-x fuerza-x + (fuerza-neta * diff-x)
        set fuerza-y fuerza-y + (fuerza-neta * diff-y)
      ]
    ]

    ;; Aplicar fuerza de swarming (pequeña influencia)
    let factor-swarming 0.1
    let nuevo-x xcor + (factor-swarming * fuerza-x)
    let nuevo-y ycor + (factor-swarming * fuerza-y)

    ;; Verificar límites
    set nuevo-x max list min-pxcor (min list max-pxcor nuevo-x)
    set nuevo-y max list min-pycor (min list max-pycor nuevo-y)
    setxy nuevo-x nuevo-y
  ]
end

;; ====================
;; FASE 3: REPRODUCCIÓN
;; ====================
;; Las bacterias más saludables se reproducen, las menos saludables mueren
to ejecutar-reproduccion
  ;; Ordenar bacterias por salud (menor es mejor en minimización)
  let bacterias-ordenadas sort-on [salud-acumulada] turtles
  let mitad floor (length bacterias-ordenadas / 2)

  ;; La mitad con MAYOR salud acumulada (peor fitness) muere
  let bacterias-a-morir sublist bacterias-ordenadas mitad (length bacterias-ordenadas)

  ;; La mitad con MENOR salud acumulada (mejor fitness) se reproduce
  let bacterias-a-reproducir sublist bacterias-ordenadas 0 mitad

  ;; Eliminar bacterias con mala salud
  foreach bacterias-a-morir [ bacteria ->
    ask bacteria [ die ]
  ]

  ;; Reproducir bacterias con buena salud
  foreach bacterias-a-reproducir [ bacteria ->
    ask bacteria [
      hatch 1 [
        ;; La copia aparece en la misma posición
        set salud-acumulada 0
        set pasos-swim 0
        set en-swim? false
      ]
    ]
  ]
end

;; ==============================
;; FASE 4: ELIMINACIÓN-DISPERSIÓN
;; ==============================
;; Algunas bacterias son eliminadas y reubicadas aleatoriamente
to ejecutar-eliminacion-dispersion
  ask turtles [
    if random-float 1 < Ped [
      ;; Dispersar: mover a ubicación aleatoria (evitando obstáculos)
      mover-a-patch-valido
      calcular-fitness
      set salud-acumulada 0
      set pasos-swim 0
      set en-swim? false
    ]
  ]
end

;; ====================
;; MOVER A PATCH VÁLIDO
;; ====================
;; Mueve la bacteria a un patch aleatorio que no sea obstáculo
to mover-a-patch-valido
  let patches-validos patches with [not es-obstaculo?]
  if any? patches-validos [
    move-to one-of patches-validos
  ]
end

;; ================================
;; ACTUALIZAR MEJOR SOLUCIÓN GLOBAL
;; ================================
to actualizar-mejor-global
  if any? turtles [
    let mejor-bacteria min-one-of turtles [fitness]
    if mejor-bacteria != nobody [
      let fitness-actual [fitness] of mejor-bacteria
      if fitness-actual < mejor-fitness or mejor-fitness = 0 [
        set mejor-fitness fitness-actual
        set mejor-posicion-x [xcor] of mejor-bacteria
        set mejor-posicion-y [ycor] of mejor-bacteria
      ]
    ]
  ]
end

;; =======================
;; ACTUALIZAR ESTADÍSTICAS
;; =======================
to actualizar-estadisticas
  if any? turtles [
    set fitness-promedio mean [fitness] of turtles
  ]
end

;; ============================
;; ACTUALIZAR COLOR DE BACTERIA
;; ============================
to actualizar-color-bacteria
  ;; Color según fitness relativo
  let min-fit mejor-fitness
  let max-fit fitness-promedio * 2
  let rango max-fit - min-fit

  ifelse rango > 0 [
    let valor-norm (fitness - min-fit) / rango
    set color scale-color blue valor-norm 1 0
  ]
  [
    set color blue
  ]

  ;; Marcar si está en swim
  if en-swim? [
    set color cyan
  ]
end

;; =====================
;; MARCAR MEJOR SOLUCIÓN
;; =====================
to marcar-mejor
  ;; Limpiar marcas anteriores
  ask patches with [pcolor = red] [
    set pcolor scale-color green (normalizar-valor valor-funcion) 1 0
  ]

  ;; Marcar posición del mejor
  if mejor-posicion-x != 0 or mejor-posicion-y != 0 [
    ask patch (round mejor-posicion-x) (round mejor-posicion-y) [
      set pcolor red
    ]
  ]
end

;; =====================
;; REINICIAR EXPERIMENTO
;; =====================
to reiniciar
  clear-all
  setup
end
@#$#@#$#@
GRAPHICS-WINDOW
10
45
607
643
-1
-1
5.89
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
30.0

TEXTBOX
10
10
1142
32
 BACTERIAL FORAGING OPTIMIZATION (BFO)
18
73.0
1

BUTTON
630
45
720
85
▶ SETUP
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
725
45
815
85
▶▶ GO
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
820
45
910
85
▶ PASO
go
NIL
1
T
OBSERVER
NIL
P
NIL
NIL
1

MONITOR
920
45
1040
90
★ Mejor Fitness
mejor-fitness
6
1
11

MONITOR
1045
45
1140
90
Tick
ticks
0
1
11

TEXTBOX
632
100
782
118
━━━ CONFIGURACIÓN ━━━
12
0.0
1

CHOOSER
630
118
785
163
funcion-objetivo
funcion-objetivo
"Sphere" "Rastrigin" "Ackley" "Himmelblau"
0

SLIDER
790
118
960
151
poblacion
poblacion
10
100
50.0
5
1
bacterias
HORIZONTAL

SLIDER
965
118
1140
151
tamano-mundo
tamano-mundo
50
200
100.0
10
1
patches
HORIZONTAL

SLIDER
630
168
785
201
max-ticks
max-ticks
100
5000
1000.0
100
1
NIL
HORIZONTAL

CHOOSER
790
155
960
200
tipo-frontera
tipo-frontera
"Periódica" "No Periódica"
1

TEXTBOX
632
215
782
233
━━━ QUIMIOTAXIS ━━━
12
105.0
1

SLIDER
630
233
785
266
Nc
Nc
5
50
20.0
5
1
pasos quimiotaxis
HORIZONTAL

SLIDER
790
233
960
266
Ns
Ns
1
10
4.0
1
1
pasos swim
HORIZONTAL

SLIDER
965
233
1140
266
paso-C
paso-C
0.1
5
1.0
0.1
1
tamaño paso
HORIZONTAL

TEXTBOX
632
280
782
298
━━━ REPRODUCCIÓN ━━━
12
13.0
1

SLIDER
630
298
785
331
Nre
Nre
1
10
4.0
1
1
ciclos reprod.
HORIZONTAL

SLIDER
790
298
960
331
Ped
Ped
0
0.5
0.25
0.05
1
prob. dispersión
HORIZONTAL

TEXTBOX
632
345
832
363
━━━ SWARMING (interacción) ━━━
12
94.0
1

SWITCH
630
363
755
396
usar-swarming?
usar-swarming?
1
1
-1000

SLIDER
760
363
875
396
d-attract
d-attract
0.01
0.5
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
880
363
995
396
w-attract
w-attract
0.01
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
1000
363
1092
396
h-repellant
h-repellant
0.01
0.5
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
1096
363
1188
396
w-repellant
w-repellant
1
20
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
632
410
832
428
━━━ EXTENSIONES ━━━
12
25.0
1

SWITCH
630
428
755
461
usar-obstaculos?
usar-obstaculos?
0
1
-1000

SLIDER
760
428
875
461
densidad-obstaculos
densidad-obstaculos
0
15
5.0
1
1
%
HORIZONTAL

SLIDER
880
428
995
461
tamano-obstaculos
tamano-obstaculos
1
5
2.0
1
1
NIL
HORIZONTAL

SWITCH
630
468
755
501
usar-nutrientes-agotables?
usar-nutrientes-agotables?
0
1
-1000

SLIDER
760
468
875
501
tasa-consumo
tasa-consumo
1
100
50.0
5
1
NIL
HORIZONTAL

SLIDER
880
468
995
501
tasa-regeneracion
tasa-regeneracion
0
2
0.1
0.1
1
NIL
HORIZONTAL

MONITOR
1000
428
1140
473
Nutrientes (%)
(nutrientes-totales / nutrientes-iniciales) * 100
1
1
11

TEXTBOX
632
520
832
538
━━━ MÉTRICAS ━━━
12
0.0
1

MONITOR
630
538
725
583
Fitness Prom.
fitness-promedio
4
1
11

MONITOR
730
538
825
583
Mejor X
mejor-posicion-x
2
1
11

MONITOR
830
538
925
583
Mejor Y
mejor-posicion-y
2
1
11

MONITOR
930
538
1025
583
Población
count turtles
0
1
11

MONITOR
1030
538
1140
583
Ciclo Reprod.
ciclo-reproduccion
0
1
11

BUTTON
631
596
801
629
⊕ Marcar Mejor Posición
marcar-mejor
NIL
1
T
OBSERVER
NIL
M
NIL
NIL
1

PLOT
841
665
1171
815
Evolución del Fitness
Ticks
Fitness
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Mejor" 1.0 0 -2674135 true "" "plot mejor-fitness"
"Promedio" 1.0 0 -13345367 true "" "plot fitness-promedio"

PLOT
10
665
420
815
Distribución de Fitness
Fitness
Frecuencia
0.0
50.0
0.0
10.0
true
false
"set-histogram-num-bars 20" ""
PENS
"default" 1.0 1 -13840069 true "" "histogram [fitness] of turtles"

PLOT
425
665
835
815
Dinámica de Nutrientes
Ticks
% Restante
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -10899396 true "" "if nutrientes-iniciales > 0 [plot (nutrientes-totales / nutrientes-iniciales) * 100]"

@#$#@#$#@
## BACTERIAL FORAGING OPTIMIZATION (BFO)

### Descripción del Modelo
Implementación del algoritmo de optimización BFO (Bacterial Foraging Optimization) propuesto por Kevin M. Passino en 2002. El modelo simula el comportamiento de búsqueda de alimento de la bacteria *Escherichia coli* para resolver problemas de optimización.

### Autor
Kevin Steve Quezada Ordoñez
Modelación Basada en Agentes 2026-I
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
Polygon -7500403 true true 245 133 268 164 269 180 264 198 244 209 230 209 215 198 210 175 222 155 240 143
Polygon -7500403 true true 87 136 63 150 50 166 48 182 53 201 74 212 90 212 105 201 110 178 98 158 85 143

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
  <experiment name="Exp1-Poblacion" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mejor-fitness</metric>
    <metric>fitness-promedio</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="poblacion">
      <value value="10"/>
      <value value="30"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="funcion-objetivo">
      <value value="&quot;Sphere&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paso-C">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nc">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ns">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nre">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ped">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-mundo">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-swarming?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-obstaculos?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-nutrientes-agotables?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tipo-frontera">
      <value value="&quot;No Periódica&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="densidad-obstaculos">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-obstaculos">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-consumo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-regeneracion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-attract">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-attract">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="h-repellant">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-repellant">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Exp2-TamanoPaso" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mejor-fitness</metric>
    <metric>fitness-promedio</metric>
    <enumeratedValueSet variable="paso-C">
      <value value="0.5"/>
      <value value="1"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poblacion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="funcion-objetivo">
      <value value="&quot;Sphere&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nc">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ns">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nre">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ped">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-mundo">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-swarming?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-obstaculos?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-nutrientes-agotables?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tipo-frontera">
      <value value="&quot;No Periódica&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="densidad-obstaculos">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-obstaculos">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-consumo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-regeneracion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-attract">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-attract">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="h-repellant">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-repellant">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Exp3-Dispersion" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mejor-fitness</metric>
    <metric>fitness-promedio</metric>
    <enumeratedValueSet variable="Ped">
      <value value="0.05"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poblacion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="funcion-objetivo">
      <value value="&quot;Sphere&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paso-C">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nc">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ns">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nre">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-mundo">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-swarming?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-obstaculos?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-nutrientes-agotables?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tipo-frontera">
      <value value="&quot;No Periódica&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="densidad-obstaculos">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-obstaculos">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-consumo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-regeneracion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-attract">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-attract">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="h-repellant">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-repellant">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Exp4-Funciones" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mejor-fitness</metric>
    <metric>fitness-promedio</metric>
    <metric>mejor-posicion-x</metric>
    <metric>mejor-posicion-y</metric>
    <enumeratedValueSet variable="funcion-objetivo">
      <value value="&quot;Sphere&quot;"/>
      <value value="&quot;Himmelblau&quot;"/>
      <value value="&quot;Ackley&quot;"/>
      <value value="&quot;Rastrigin&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poblacion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paso-C">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nc">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ns">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nre">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ped">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-mundo">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-swarming?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-obstaculos?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-nutrientes-agotables?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tipo-frontera">
      <value value="&quot;No Periódica&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="densidad-obstaculos">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-obstaculos">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-consumo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-regeneracion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-attract">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-attract">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="h-repellant">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-repellant">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Exp5-Swarming" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mejor-fitness</metric>
    <metric>fitness-promedio</metric>
    <enumeratedValueSet variable="usar-swarming?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poblacion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="funcion-objetivo">
      <value value="&quot;Sphere&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paso-C">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nc">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ns">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nre">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ped">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-mundo">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-attract">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-attract">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="h-repellant">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-repellant">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-obstaculos?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-nutrientes-agotables?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tipo-frontera">
      <value value="&quot;No Periódica&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="densidad-obstaculos">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-obstaculos">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-consumo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-regeneracion">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Exp6-Obstaculos" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mejor-fitness</metric>
    <metric>fitness-promedio</metric>
    <enumeratedValueSet variable="usar-obstaculos?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="densidad-obstaculos">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-obstaculos">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poblacion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="funcion-objetivo">
      <value value="&quot;Sphere&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paso-C">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nc">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ns">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nre">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ped">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-mundo">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-swarming?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-nutrientes-agotables?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tipo-frontera">
      <value value="&quot;No Periódica&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-consumo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-regeneracion">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-attract">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-attract">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="h-repellant">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-repellant">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Exp7-Nutrientes" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>mejor-fitness</metric>
    <metric>(nutrientes-totales / nutrientes-iniciales) * 100</metric>
    <enumeratedValueSet variable="usar-nutrientes-agotables?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-consumo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tasa-regeneracion">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poblacion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="funcion-objetivo">
      <value value="&quot;Sphere&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paso-C">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nc">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ns">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nre">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ped">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-mundo">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-swarming?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="usar-obstaculos?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tipo-frontera">
      <value value="&quot;No Periódica&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="densidad-obstaculos">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tamano-obstaculos">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="d-attract">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-attract">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="h-repellant">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="w-repellant">
      <value value="10"/>
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
