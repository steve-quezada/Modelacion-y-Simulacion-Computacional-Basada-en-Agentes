# Práctica 1: Implementación y análisis de autómatas celulares

1. **ACE.nlogo** - Autómata Celular Elemental
2. **LIFE.nlogo** - Juego de la Vida

## Requisitos del Sistema

- **NetLogo 6.2.0 o superior**

## Ejecución

## 1. ACE.nlogo - Autómata Celular Elemental

### Controles Principales

#### Botones de Control
- **Setup**: Inicializa el modelo con los parámetros actuales
- **Go**: Ejecuta una generación del autómata
- **Go (forever)**: Ejecuta continuamente hasta detenerse manualmente

#### Parámetros Configurables

##### 1. Regla (0-255)
- **Descripción**: Define las reglas de transición del autómata
- **Rango**: 0 a 255
- **Valores interesantes**:
  - Regla 30: Comportamiento caótico
  - Regla 90: Triángulo de Sierpinski
  - Regla 110: Computacionalmente universal
  - Regla 184: Flujo de tráfico

##### 2. Longitud (50-500)
- **Descripción**: Ancho de la retícula (número de células por fila)
- **Rango**: 50 a 500 células

##### 3. Tiempo de Evolución (50-300)
- **Descripción**: Número de generaciones a simular
- **Rango**: 50 a 300 generaciones
- **Nota**: Determina la altura del mundo

##### 4. Condición Inicial
- **Descripción**: Estado inicial de la primera fila
- **Opciones**:
  - "Centro": Una sola célula activa en el centro
  - "Aleatoria": Distribución aleatoria de células activas
  - "Usuario": Permite ingresar coordenadas

##### 6. Tipo de Frontera
- **Descripción**: Comportamiento en los bordes del mundo
- **Opciones**:
  - "Periódica": Los bordes se conectan (mundo toroidal)
  - "No Periódica": Bordes fijos sin vecinos externos

#### Botones de Experimentos

##### REGLA 30
- **Setup Sensibilidad**: Configura experimento para análisis de sensibilidad
- **Aplicar Perturbación**: Introduce pequeños cambios en el estado inicial
- **Mostrar Diferencias**: Visualiza las diferencias entre evoluciones

##### REGLA 132
- **Setup Simple**: Configuración básica con patrón simple
- **Setup Complejo**: Configuración con patrón más elaborado

##### REGLA 22
- **Setup Simple**: Configuración básica con una célula central
- **Setup Aleatoria**: Configuración con distribución aleatoria

##### EXPLORACIÓN
- **Setup R110**: Configura automáticamente la Regla 110
- **Setup R90**: Configura automáticamente la Regla 90

---

## 2. LIFE.nlogo - Juego de la Vida de Conway

### Reglas del Juego
1. **Nacimiento**: Una célula muerta con exactamente 3 vecinos vivos nace
2. **Supervivencia**: Una célula viva con 2 o 3 vecinos vivos sobrevive
3. **Muerte**: Una célula viva con menos de 2 o más de 3 vecinos muere

### Controles Principales

#### Botones de Control
- **Setup**: Inicializa el juego con los parámetros actuales
- **Go**: Ejecuta una generación del juego
- **Go (forever)**: Ejecuta continuamente
- **Reiniciar Experimento**: Limpia completamente el mundo

#### Parámetros Configurables

##### 1. Tamaño de Retícula (100-200)
- **Descripción**: Dimensiones del mundo (NxN)
- **Rango**: 100 a 200 células por lado

##### 2. Densidad (0-100%)
- **Descripción**: Porcentaje inicial de células vivas
- **Rango**: 0 a 100%
- **Valores típicos**:
  - 35%: Configuración de control estable
  - 50%: Actividad moderada
  - 85%: Alta densidad con extinción rápida

##### 3. Tipo de Frontera
- **Descripción**: Comportamiento en los bordes del mundo
- **Opciones**:
  - "Periódica": Los bordes se conectan (mundo toroidal)
  - "No Periódica": Bordes fijos sin vecinos externos

### Experimentos Preconfigurados

#### Experimentos de Densidad
- **35%**: Configuración de control con evolución estable
- **50%**: Densidad moderada para observar patrones
- **85%**: Alta densidad que típicamente lleva a extinción

#### Patrones Clásicos
- **Demo: Glider**: Muestra el patrón móvil más simple
- **Demo: Eater**: Patrón que "come" gliders automáticamente
- **Demo: Gosper Gun**: Cañón que genera gliders infinitamente
- **Compuerta NOT (A=1)**: Demostración de computación con gliders
- **Compuerta NOT (A=0)**: Compuerta lógica sin entrada

### Monitores y Estadísticas
- **Población Actual**: Número de células vivas
- **Población Máxima**: Máximo histórico de células vivas
- **Población Mínima**: Mínimo histórico de células vivas
- **Generación**: Número de la generación actual
- **Densidad %**: Porcentaje actual de células vivas

### Gráfica de Población
El modelo incluye una gráfica que muestra:
- Evolución de la población a través del tiempo
- Población máxima y mínima alcanzadas
- Tendencias y patrones de crecimiento/decrecimiento

## Archivos Incluidos

```
Quezada_Ordoñez/
└── Practica1/
    │   README.md              # Este archivo
    │   solucion.pdf           # Documentación de la práctica
    |   MBA2026I_Practica1.pdf
    │
    └── Fuentes/
            ACE.nlogo      # Autómata Celular Elemental
            LIFE.nlogo     # Juego de la Vida de Conway
```