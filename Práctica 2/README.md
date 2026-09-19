# Práctica 2: Implementación y análisis de modelos basados en agentes

1. **Schelling.nlogo** - Modelo de segregación de Schelling
2. **Schelling[Ejercicio4].nlogo** - Modelo de Schelling con tres tipos de agentes
3. **termitas.nlogo** - Termitas apiladoras

## Requisitos del Sistema

- **NetLogo 6.2.0 o superior**

## Ejecución

## 1. Schelling.nlogo - Modelo de segregación de Schelling

### Descripción del Modelo
Modelo propuesto por Thomas Schelling que consiste en dos grupos de agentes que localmente tratan de satisfacer la necesidad de estar con los de su mismo grupo, generando patrones de segregación.

### Reglas del Modelo
1. **Satisfacción**: Si el agente cumple con el porcentaje de similitud requerida en su vecindad de Moore (8-vecinos), permanece en su posición
2. **Mudanza**: Si no cumple con el porcentaje de similitud, se muda a una celda vacía

### Controles Principales

#### Botones de Control
- **Setup**: Inicializa el modelo con los parámetros actuales
- **Go**: Ejecuta una generación del modelo
- **Go (forever)**: Ejecuta continuamente hasta detenerse manualmente
- **Reiniciar Experimento**: Limpia completamente el mundo

#### Parámetros Configurables

##### 1. Tamaño de Retícula (50-100)
- **Descripción**: Dimensiones del mundo (NxN)
- **Rango**: 50 a 100 células por lado
- **Valor típico**: 50

##### 2. Densidad (0-100%)
- **Descripción**: Porcentaje de celdas ocupadas
- **Rango**: 0 a 100%
- **Valor típico**: 90%

##### 3. Porcentaje de Similitud (0-100%)
- **Descripción**: Porcentaje mínimo de vecinos del mismo tipo requerido para la satisfacción del agente
- **Rango**: 0 a 100%
- **Valores interesantes**:
  - Menor a S_max: Genera segregación
  - Igual a S_max: Sistema en el límite de segregación
  - Mayor a S_max: No hay segregación estable

##### 4. Tipo de Frontera
- **Descripción**: Comportamiento en los bordes del mundo
- **Opciones**:
  - "Periódica": Los bordes se conectan (mundo toroidal)
  - "No Periódica": Bordes fijos sin vecinos externos

### Monitores y Estadísticas
- **Agentes Satisfechos**: Número de agentes que cumplen con su porcentaje de similitud
- **% Satisfacción**: Porcentaje de agentes satisfechos
- **Tiempo de Convergencia**: Número de generaciones hasta que el sistema se estabiliza
- **Número de Cúmulos**: Cantidad de agrupaciones del mismo tipo

### Gráficas
El modelo incluye gráficas que muestran:
- Evolución de la satisfacción a través del tiempo
- Análisis de convergencia

---

## 2. Schelling[Ejercicio4].nlogo - Modelo de Schelling con tres tipos de agentes

### Descripción del Modelo
Extensión del modelo de Schelling que considera tres tipos de agentes con parámetros de similitud independientes para cada grupo.

### Controles Principales

#### Botones de Control
- **Setup**: Inicializa el modelo con los parámetros actuales
- **Go**: Ejecuta una generación del modelo
- **Go (forever)**: Ejecuta continuamente hasta detenerse manualmente

#### Parámetros Configurables

##### 1. Tamaño de Retícula (50-100)
- **Descripción**: Dimensiones del mundo (NxN)

##### 2. Densidad (0-100%)
- **Descripción**: Porcentaje de celdas ocupadas

##### 3. Distribución de Población
- **% Rojos**: Porcentaje de agentes rojos
- **% Verdes**: Porcentaje de agentes verdes
- **% Azules**: Porcentaje de agentes azules

##### 4. Parámetros de Similitud por Tipo
- **S_x**: Porcentaje de similitud requerida para agentes x
- **σ_x**: Desviación estándar de similitud para x

### Monitores y Estadísticas
- **Satisfacción por Tipo**: Porcentaje de agentes satisfechos de cada color
- **Cúmulos por Tipo**: Número de agrupaciones de cada color
- **Tiempo de Convergencia**: Generaciones hasta estabilización

---

## 3. termitas.nlogo - Termitas apiladoras

### Descripción del Modelo
Modelo propuesto por Mitchel Resnick que simula una estrategia descentralizada para apilar astillas de madera a través de simples reglas ejecutadas por termitas.

### Reglas del Modelo
1. **Recoger**: Si la termita no está cargando nada y se encuentra una astilla, la recoge
2. **Soltar**: Si está cargando una astilla y se encuentra otra, suelta la astilla
3. **Movimiento**: Caminador aleatorio con apertura de visión de -50 a 50 grados

### Controles Principales

#### Botones de Control
- **Setup**: Inicializa el modelo con los parámetros actuales
- **Go**: Ejecuta un paso del modelo
- **Go (forever)**: Ejecuta continuamente hasta detenerse manualmente

#### Parámetros Configurables

##### 1. Tamaño de Retícula
- **Descripción**: Dimensiones del mundo (NxN)
- **Valor típico**: 100

##### 2. Número de Termitas
- **Descripción**: Cantidad de agentes termitas
- **Rango**: Configurable según experimento

##### 3. Densidad de Astillas (0-100%)
- **Descripción**: Porcentaje de celdas con astillas inicialmente
- **Rango**: 0 a 100%

##### 4. Tipos de Astillas
- **Descripción**: Número de tipos diferentes de astillas
- **Opciones**:
  - 1 tipo: Astillas amarillas únicamente
  - 2 tipos: Astillas amarillas y cafés

##### 5. Comportamiento al Soltar
- **Descripción**: Acción después de soltar una astilla
- **Opciones**:
  - "Normal": Continúa desde la misma posición
  - "Salto": Salta a una posición aleatoria

### Monitores y Estadísticas
- **Número de Cúmulos**: Cantidad total de agrupaciones de astillas
- **Cúmulos por Tipo**: Agrupaciones separadas por color
- **Termitas Cargando**: Número de termitas que llevan astillas

### Gráficas
El modelo incluye gráficas que muestran:
- Evolución del número de cúmulos en el tiempo
- Número de termitas cargando astillas

---

## Archivos Incluidos

```
Quezada_Ordoñez/
└── Practica2/
    │   README.md                         # Este archivo
    │   solucion.pdf                      # Documentación de la práctica
    |   MBA2026I_Practica2.pdf
    │
    └── Fuentes/
            Schelling.nlogo               # Modelo de segregación de Schelling
            Schelling[Ejercicio4].nlogo   # Schelling con tres tipos de agentes
            termitas.nlogo                # Termitas apiladoras
```