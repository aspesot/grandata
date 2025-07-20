# GRANDATA PROJECT


## Resultados de los ejercicios
### Ejercicio 1
- Punto 1: Monto total a facturar: $391367.00
- Punto 2: El dataset en formato parquet puedes encontrarlo en la carpeta output. Incluí una sentencia en el codigo para leerlo.
- Punto 3: El histograma se puede encontrar en la carpeta output.

### Ejercicio 2
Si bien no tengo experiencia directa con Hadoop, sí instalé y trabajé con un clúster Apache Spark en modo standalone sobre tres instancias virtuales. En esa configuración definí un nodo como master y dos como workers, y ejecuté pipelines desde Airflow hacia ese entorno distribuido. Para responder estas preguntas me basé tanto en esa experiencia como en una investigación puntual sobre Hadoop y YARN.

--------------- Punto 1 -----------------
Investigué cómo funciona YARN y los schedulers que ofrece. Si tuviera que priorizar procesos productivos, usaría colas diferenciadas en el scheduler CapacityScheduler. La cola del pipeline productivo tendría mayor capacidad mínima, prioridad más alta y posiblemente activaría la opción de pre-emption si usara FairScheduler, para garantizar que siempre tenga recursos disponibles. También limitaría la cantidad de tareas exploratorias concurrentes para evitar saturar el cluster.

Como estrategia, programaría los procesos productivos en ventanas de baja actividad, como la madrugada, para evitar competir por recursos con tareas exploratorias. También los aislaría temporalmente usando triggers o ventanas de ejecución programadas.

Para orquestar esto, tengo experiencia usando Airflow y Dagster que permiten definir dependencias y controlar el momento exacto de ejecución de cada job.

--------------- Punto 2 -----------------
Sobre este punto, pensando en mi experiencia pasada veo 2 posibles causas
- Esto se puede dar debido a una mala estrategia de particiones ya que las consultas podrían estar escaneando muchos más datos de los necesarios.
- Bajo rendimiento en la acumulación de archivos pequeños (incluso dentro de las particiones) generados por las actualizaciones diarias. Esto impacta negativamente en la performance porque Spark debe manejar y leer gran cantidad de metadatos y archivos individuales.

Para mejorar esto, sugeriría:
- Aplicar partitioning por una columna como fecha (por ejemplo, fecha_evento) para reducir el volumen de datos escaneados.
- Realizar compactación periódica para reducir small files
- Otra posible solución sería usar Delta Lake, que soporta actualizaciones eficientes, transacciones ACID y permiten aplicar optimizaciones como OPTIMIZE(para compactar) y ZORDER BY (ordenar los registros dentro de la partición lo que optimiza el corte en la busqueda mas rápido cuando encuentra el registro).

- Usar cache() con cuidado en tablas que se consultan mucho y no cambian durante la sesión.

- Otro solución, no tan frecuente, que use en el pasado fue generar una replicación actualizada de la tabla con diferentes tipos de particionados armados particularmente para responder a diferentes tipos de acceso a los datos. La única desventaja de este caso es mantener la consistencia e integridad de los datos ya que el espacio de disco es barato hoy en día. 

--------------- Punto 3 -----------------
Una posible configuración para cumplir con este punto sería:
```
spark = SparkSession.builder \
    .appName("ProcesoControlado") \
    .config("spark.executor.instances", "3") \
    .config("spark.executor.memory", "24g") \
    .config("spark.executor.cores", "6") \
    .config("spark.driver.memory", "3g") \
    .getOrCreate()
```
Explicación: Para usar solo la mitad del clúster, calcularía los recursos totales disponibles (150 GB y 36 cores) y luego limitaría el job a 3 ejecutores de 24 GB y 6 cores cada uno. Así, uso 72 GB y 18 cores, quedando la otra mitad libre.

Opción 2: Como vi en la investigación previa, usando CapacityScheduler en YARN podria usar una cola con un capacity del 50% y un maximium capacity de 50% asegurandome que no pueda superar el 50% de los recursos.

Otra opción: Si configuro cada executor con 6 cores y 24 GB de RAM, y habilito dynamic allocation con:

```
.config("spark.dynamicAllocation.enabled", "true")
.config("spark.dynamicAllocation.minExecutors", "1")
.config("spark.dynamicAllocation.maxExecutors", "3")
```
Entonces, el job podrá escalar dinámicamente, pero nunca va a usar más de 3 executors, lo que me garantiza que el consumo máximo será:
- 3 × 6 cores = 18 cores
- 3 × 24 GB = 72 GB

Eso representa aproximadamente la mitad del clúster. Pero esta opción no es ideal ya que implica reajustar los executor para estas situaciones especificas y es preferible asignar recursos fijos.

## 📁 Estructura de archivos del proyecto

- /data/ → para los archivos eventos.csv.gz y free_sms_destinations.csv.gz

- /notebooks/ → Jupyter o Zeppelin notebook

- /output/ → parquet y gráfico .png

Dockerfile, docker-compose.yml, README.md


## 🐳 Arquitectura Docker

El diseño de la solución utiliza un único contenedor definido mediante `docker-compose` y construido con un `Dockerfile` personalizado. Este contenedor incluye:

- Apache Spark 2.3.0 (instalado manualmente)
- Python 3.6
- PySpark 2.3.0
- Jupyter Lab para ejecución interactiva

La configuración está orientada a ejecutarse en modo local (`local[*]`), lo cual es completamente adecuado para los objetivos del ejercicio. Este enfoque evita la complejidad innecesaria de montar un cluster Spark en modo standalone que no aportaría valor adicional para este contexto.

### ▶️ Cómo correr el proyecto

1. Cloná el repositorio y ubicáte en la raíz del proyecto.

2. Construí la imagen y levantá el contenedor:

```bash
docker-compose up --build
```

Luego de la primera instalación se puede remover `--build`


