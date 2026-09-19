# Proyecto Final: Bacterial Foraging Optimization (BFO)

1. **BFO.nlogo** - Modelo de Optimización por Forrajeo Bacteriano

## Requisitos del Sistema

- **NetLogo 6.2.0 o superior**

### Descripción del Modelo
Implementación del algoritmo Bacterial Foraging Optimization (BFO) propuesto por Kevin M. Passino (2002). Simula el comportamiento de búsqueda de alimento de la bacteria *Escherichia coli* para resolver problemas de optimización.

### Fases del Algoritmo
1. **Quimiotaxis**: Movimiento tumble (volteo aleatorio) y swim (nado en dirección favorable)
2. **Swarming**: Interacción célula-célula mediante señales químicas
3. **Reproducción**: Las bacterias más saludables se duplican
4. **Eliminación-Dispersión**: Reubicación aleatoria de algunas bacterias

### Extensiones Implementadas

#### 1. Obstáculos en el Entorno
- Se generan zonas infranqueables (color gris) en el ambiente
- Las bacterias deben navegar alrededor de los obstáculos
- Si una bacteria encuentra un obstáculo, intenta 3 direcciones alternativas
- Los obstáculos no se generan cerca del óptimo (centro del mundo)

#### 2. Nutrientes Agotables
- Cada patch tiene un nivel de nutrientes (0-100)
- Las bacterias consumen nutrientes al pasar por un patch
- Patches con nutrientes agotados cambian de color (verde → amarillo)
- Los nutrientes se regeneran lentamente con el tiempo

### Controles Principales

#### Botones de Control
- **Setup**: Inicializa el modelo con los parámetros actuales
- **Go**: Ejecuta la simulación continuamente
- **Paso**: Avanza un tick de la simulación
- **Marcar Mejor**: Resalta la mejor solución encontrada

#### Parámetros Configurables

##### 1. Población (10-100)
- **Descripción**: Número de bacterias en la simulación
- **Rango**: 10 a 100 bacterias
- **Valor típico**: 50

##### 2. Tamaño de Mundo (50-200)
- **Descripción**: Dimensiones del espacio de búsqueda (NxN)
- **Rango**: 50 a 200 celdas por lado
- **Valor típico**: 100

##### 3. Función Objetivo
- **Descripción**: Función a optimizar (minimizar)
- **Opciones**:
  - **Sphere**: Función unimodal simple
  - **Rastrigin**: Función multimodal con muchos óptimos locales
  - **Ackley**: Función con región casi plana y mínimo central
  - **Himmelblau**: Función con cuatro mínimos globales

##### 4. Parámetros de Quimiotaxis
- **Nc (5-50)**: Número de pasos quimiotácticos por ciclo de reproducción
- **Ns (1-10)**: Máximo de pasos de swim consecutivos
- **paso-C (0.1-5)**: Tamaño del paso de movimiento

##### 5. Parámetros de Reproducción
- **Nre (1-10)**: Número de ciclos de reproducción por ciclo de eliminación

##### 6. Parámetros de Eliminación-Dispersión
- **Ped (0-0.5)**: Probabilidad de eliminación-dispersión

##### 7. Parámetros de Swarming (opcional)
- **usar-swarming?**: Activar/desactivar interacción entre bacterias
- **d-attract (0.01-0.5)**: Profundidad de atracción
- **w-attract (0.01-1)**: Ancho de la señal atractora
- **h-repellant (0.01-0.5)**: Altura de repulsión
- **w-repellant (1-20)**: Ancho de la señal repelente

##### 8. Tipo de Frontera
- **Descripción**: Comportamiento en los bordes del mundo
- **Opciones**:
  - "Periódica": Los bordes se conectan (mundo toroidal)
  - "No Periódica": Bordes fijos

##### 9. Parámetros de Obstáculos
- **usar-obstaculos?**: Activar/desactivar generación de obstáculos
- **densidad-obstaculos (0-15%)**: Porcentaje del mundo cubierto por obstáculos
- **tamano-obstaculos (1-5)**: Tamaño de cada bloque de obstáculo

##### 10. Parámetros de Nutrientes
- **usar-nutrientes-agotables?**: Activar/desactivar sistema de nutrientes
- **tasa-consumo (1-100)**: Nutrientes consumidos por visita de bacteria
- **tasa-regeneracion (0-2)**: Velocidad de regeneración de nutrientes

##### 11. Control de Simulación
- **max-ticks (100-5000)**: Número máximo de iteraciones

### Monitores y Estadísticas
- **Mejor Fitness**: Valor del mejor fitness encontrado
- **Fitness Promedio**: Media del fitness de la población
- **Población**: Número actual de bacterias
- **Mejor X, Mejor Y**: Coordenadas de la mejor solución
- **Ciclo Reprod.**: Contador de ciclos de reproducción
- **Nutrientes (%)**: Porcentaje de nutrientes restantes en el ambiente

### Visualización

#### Paisaje de Fitness
- **Verde claro**: Zonas con buen fitness (valores bajos, cerca del óptimo)
- **Verde oscuro**: Zonas con mal fitness (valores altos)

#### Color de Bacterias
- **Azul claro**: Bacterias con buen fitness (cerca del óptimo)
- **Azul oscuro**: Bacterias con fitness bajo
- **Cyan**: Bacteria en modo SWIM (explotando dirección favorable)

#### Estados del Ambiente
- **Verde**: Zona con nutrientes disponibles
- **Amarillo**: Zona con nutrientes agotados (< 30%)
- **Gris**: Obstáculo infranqueable

### Gráficas
El modelo incluye gráficas que muestran:
- Evolución del mejor y promedio fitness a través del tiempo
- Histograma de distribución de fitness de la población
- Dinámica de nutrientes (porcentaje restante en el ambiente)

---

## Archivos Incluidos

```
Quezada_Ordoñez/
└── ProyectoFinal/
    │   Documento.pdf                            # Reporte Proyecto Final
    │   Presentacion.pdf                         # Presentación del proyecto
    │   README.md                                # Este archivo
    |   MBA2026I_ProyectoFinal_Lineamientos.pdf  # Lineamientos del Proyecto
    │
    ├── CSV/                                     # Resultados experimentos
    │       BFO Exp1-Poblacion-table.csv
    │       BFO Exp2-TamanoPaso-table.csv
    │       BFO Exp3-Dispersion-table.csv
    │       BFO Exp4-Funciones-table.csv
    │       BFO Exp5-Swarming-table.csv
    │       BFO Exp6-Obstaculos-table.csv
    │       BFO Exp7-Nutrientes-table.csv
    │
    └── Fuentes/
            BFO.nlogo                            # Modelo de optimización BFO
```
