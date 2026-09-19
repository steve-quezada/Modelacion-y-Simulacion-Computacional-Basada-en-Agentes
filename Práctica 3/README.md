# Práctica 3: Modelación de una dinámica de epidemias con MBA.

## Archivos Principales

1. **SIR.nlogo** - Modelo SIR con distanciamiento social y soporte para mapas reales

## Requisitos del Sistema

- **NetLogo 6.2.0 o superior**
- **Mapa requerido**: `media/5/mapa_anillo.png` (incluido en el directorio Fuentes/)

## Ejecución

## 1. SIR.nlogo - Modelo SIR

### Descripción del Modelo
Implementación de un modelo epidemiológico SIR (Susceptible-Infectado-Recuperado) basado en agentes que permite simular la propagación de una enfermedad en una población con la estrategia de distanciamiento social. El modelo puede ejecutarse tanto en retícula regular como en mapas urbanos reales.

### Estados de los Agentes
- **Sano (Azul)**: Agente susceptible que puede contagiarse
- **Enfermo (Rojo)**: Agente infectado que puede contagiar a otros
- **Recuperado (Verde)**: Agente que se recuperó y tiene inmunidad

### Reglas del Modelo

1. **Contagio**: Si una persona sana tiene una persona enferma en su vecindad de Moore (8-vecinos), se contagia con probabilidad PC y cambia su estado a enfermo
2. **Recuperación**: Una persona enferma se recupera después de TE ticks y cambia su estado a recuperado (inmune)
3. **Movimiento**: Los agentes son caminadores aleatorios con apertura de visión WIG (grados). En modo mapa, el movimiento está restringido a calles (patches blancos)
4. **Distanciamiento Social**: Un porcentaje DS de la población permanece inmóvil para reducir contactos

### Controles Principales

#### Botones de Control
- **Setup**: Inicializa el modelo con los parámetros actuales
  - En modo retícula: distribuye agentes uniformemente
  - En modo mapa: coloca agentes solo en calles (patches blancos)
- **Go**: Ejecuta un tick de simulación
- **Go (forever)**: Ejecuta continuamente hasta que no haya infectados
- **Reiniciar Mundo**: Limpia completamente la simulación

#### Parámetros Configurables

##### 1. Usar Mapa (usar-mapa?)
- **Descripción**: Activa/desactiva el modo de mapa urbano real
- **Opciones**:
  - OFF: Usa retícula regular homogénea
  - ON: Carga mapa de calles de CDMX (Anillo Periférico)

##### 2. Población

**Modo Retícula (usar-mapa? = OFF)**:
- **densidad-pob** (10-100%)
  - Porcentaje de patches ocupados por agentes
  - Valor típico: 60% (~6000 agentes en mundo 100×100)

**Modo Mapa (usar-mapa? = ON)**:
- **poblacion-mapa** (50-500)
  - Número fijo de agentes
  - Se colocan solo en calles (patches blancos)
  - Valor típico: 200 agentes

##### 3. Apertura de Visión (wiggle: 10-360°)
- **Descripción**: Rango angular de giro para el movimiento
- **Valores típicos**:
  - 150°: Movimiento semi-aleatorio (retícula)
  - 15°: Movimiento restringido siguiendo calles (mapa)
- **Efecto**: Mayor WIG → movimiento más errático

##### 4. Probabilidad de Contagio (probabilidad-contagio: 0-1)
- **Descripción**: Probabilidad de que un sano se contagie al estar cerca de un enfermo
- **Valores extremos**:
  - 0: Sin transmisión
  - 1: Transmisión segura
- **Valor típico**: 0.8 (80%)

##### 5. Tiempo de Enfermedad (tiempo-enfermedad: 10-100 ticks)
- **Descripción**: Duración que un agente permanece enfermo antes de recuperarse
- **Valor típico**: 25 ticks
- **Efecto**: Mayor TE → ventana de contagio más larga

##### 6. Distanciamiento Social (distanciamiento-social: 0-100%)
- **Descripción**: Porcentaje de la población que permanece inmóvil
- **Rango**: 0% (sin distanciamiento) a 100% (inmovilización total)
- **Valores de interés**:
  - 0%: Comportamiento base sin intervención
  - 25%, 50%, 75%: Niveles moderados de distanciamiento
  - 100%: Cuarentena total

##### 7. Infectados Iniciales (infectados-iniciales: 1-50)
- **Descripción**: Número de agentes infectados al inicio
- **Valor típico**: 5 agentes
- **Nota**: Se colocan aleatoriamente en el mundo

### Monitores y Estadísticas

#### Contadores Principales
- **Sanos**: Número actual de agentes susceptibles
- **Enfermos**: Número actual de agentes infectados
- **Recuperados**: Número actual de agentes con inmunidad
- **Pico Máximo (Emax)**: Máximo número de infectados simultáneos alcanzado
- **Tiempo del Pico (t*)**: Tick en el que ocurrió Emax

#### Estadísticas Epidemiológicas
- **Tasa de Ataque**: Porcentaje de población que se infectó
- **R₀ Efectivo**: Número promedio de contagios por infectado
- **Duración de la Epidemia**: Tiempo total hasta extinción

### Gráficas

El modelo incluye gráficas en tiempo real:

1. **Evolución Temporal SIR**
   - Eje X: Tiempo (ticks)
   - Eje Y: Número de agentes
   - Curvas:
     - Azul: Susceptibles (decreciente)
     - Roja: Infectados (curva en campana)
     - Verde: Recuperados (creciente)

2. **Distribución Espacial**
   - Vista del mundo mostrando posición y estado de cada agente
   - En modo mapa: visualización de calles y distribución urbana

### Configuraciones Experimentales Recomendadas

#### Ejercicio 1: Escenario Base
```
densidad-pob = 30%
distanciamiento-social = 0%
tiempo-enfermedad = 10 ticks
wiggle = 60°
probabilidad-contagio = 0.5
infectados-iniciales = 5
```

#### Ejercicio 2: Curvas SIR Características
```
densidad-pob = 60%
wiggle = 150°
probabilidad-contagio = 0.8
tiempo-enfermedad = 25 ticks
distanciamiento-social = 0%
```

#### Ejercicio 3: Análisis de Distanciamiento
- Usar parámetros del Ejercicio 2
- Variar DS: 0%, 25%, 50%, 75%
- Observar aplanamiento de curva de infectados

#### Ejercicio 4: Espacio de Parámetros DS vs Emax
- Usar BehaviorSpace
- Experimento: `Analisis_DS`

#### Ejercicio 5: Mapa Urbano CDMX
```
usar-mapa? = ON
poblacion-mapa = 200
wiggle = 15°
probabilidad-contagio = 0.8
tiempo-enfermedad = 25 ticks
distanciamiento-social = 0%
```

#### Ejercicio Optativo: DS vs Emax en Mapa
- Usar BehaviorSpace
- Experimento: `Analisis_DS_Mapa`

---

## Uso de BehaviorSpace

### Experimentos Predefinidos

#### 1. Analisis_DS (Retícula Regular)
```
Parámetros variables:
  - distanciamiento-social: [0 5 100] (21 valores)

Parámetros fijos:
  - usar-mapa? = false
  - densidad-pob = 60%
  - wiggle = 150°
  - probabilidad-contagio = 0.8
  - tiempo-enfermedad = 25
  - infectados-iniciales = 5

Repeticiones: 10
Total de simulaciones: 210
```

**Cómo ejecutar:**
1. Tools → BehaviorSpace
2. Seleccionar experimento "Analisis_DS"
3. Click en "Run"
4. Seleccionar formato de salida: Table
5. Guardar CSV en: `csv/Analisis_DS-table.csv`

#### 2. Analisis_DS_Mapa (Mapa Urbano)
```
Parámetros variables:
  - distanciamiento-social: [0 5 100] (21 valores)

Parámetros fijos:
  - usar-mapa? = true
  - poblacion-mapa = 200
  - wiggle = 15°
  - probabilidad-contagio = 0.8
  - tiempo-enfermedad = 25
  - infectados-iniciales = 5

Repeticiones: 10
Total de simulaciones: 210
```

**Cómo ejecutar:**
1. Tools → BehaviorSpace
2. Seleccionar experimento "Analisis_DS_Mapa"
3. Click en "Run"
4. Guardar CSV en: `csv/Analisis_DS_Mapa-table.csv`

---

## Archivos Incluidos

```
Quezada_Ordoñez/
└── Practica3/
    │   README.md                         # Este archivo
    │   SolucionEjercicios.pdf            # Documentación de la práctica
    |   MBA2026I_Practica3.pdf
    │
    └── Fuentes/
        │    SIR.nlogo                    #  Modelo SIR
        │
        ├─── csv/
        │        Analisis_DS-table.csv             # Resultados BehaviorSpace (retícula)
        │        Analisis_DS_spreadsheet.csv
        │        Analisis_DS_Mapa-table.csv        # Resultados BehaviorSpace (mapa)
        │        Analisis_DS_Mapa_spreadsheet.csv
        │
        └── media/
            └── 5/
                └── mapa_anillo.png                # Mapa del Anillo Periférico CDMX
```