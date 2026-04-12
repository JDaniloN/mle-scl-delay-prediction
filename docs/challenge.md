# Documentación del desafío

## Ajuste en el README traducido (columnas del dataset)

En `README.es.md`, en la tabla de columnas derivadas (`high_season`, `min_diff`, `period_day`), alineé los nombres con el dataset y el notebook: uso **`Fecha-I`** y **`Fecha-O`** en lugar de `Date-I` y `Date-O`. En el README en inglés del challenge esas tres líneas aún hablan de `Date-*`, pero en `exploration.ipynb` y en el CSV todo va con **`Fecha-I` / `Fecha-O`**, así que el español queda coherente con lo que realmente se usa al cargar datos.

## Instalación de dependencias en Windows

Al instalar con el comando `pip` suelto, Windows devolvió que **Control de aplicaciones** bloqueaba **`pip.exe`** del venv. La instalación de paquetes sí funciona usando **`python -m pip`** (mismo entorno, pero sin ejecutar el `.exe` de pip directamente).

Después apareció un **conflicto de versiones** entre lo que pide el `requirements.txt` del challenge (`numpy~=1.22.4`) y lo que arrastra **matplotlib** vía **contourpy** (necesita `numpy` más nuevo si se instala en el orden equivocado). Lo resolví instalando todo en **un solo comando** y con el orden **`requirements.txt` → `requirements-test.txt` → `requirements-dev.txt`**, para que pip fije primero numpy/pandas y luego resuelva matplotlib con una versión de contourpy compatible (en mi caso quedó **contourpy 1.2.1** sin avisos de conflicto al final).

## Notebook y kernel en el IDE

Para ejecutar celdas del `exploration.ipynb` en Cursor/VS Code con el intérprete del `.venv`, hacía falta instalar **`ipykernel`** en ese mismo entorno (`python -m pip install ipykernel`). No venía en los requirements del repo; es solo para que el editor pueda lanzar el kernel de Jupyter apuntando al Python del proyecto.

## Seaborn y `barplot` en el notebook

### Qué pasaba

A partir de **Seaborn 0.12**, `barplot` dejó de aceptar dos argumentos posicionales `(x, y)`. Solo admite como mucho **uno** posicional (normalmente `data`) o hay que usar **`x=`** e **`y=`** explícitos. Por eso el error: *"takes from 0 to 1 positional arguments but 2 were given"*.

### Qué hice

Actualicé **`challenge/exploration.ipynb`**: las **13** llamadas a `sns.barplot(...)` pasan a la forma `sns.barplot(x=..., y=..., ...)`. Con eso los gráficos de barras (aerolíneas, días, tasas, etc.) vuelven a generarse bien al ejecutar las celdas.

Si más adelante aparece un error parecido en `sns.countplot` u otra función de Seaborn, el arreglo suele ser el mismo: **argumentos con nombre** en lugar de posicionales.

## Elección del modelo (Parte I) y despliegue en GCP

El `README.es.md` no impone un algoritmo concreto: pide **elegir el mejor modelo a tu criterio** entre los que el DS probó y **argumentar** (no es obligatorio mejorarlo). En el notebook, la línea productiva que el DS cierra es **top 10 características + balanceo de clases**; ahí comparamos **XGBoost con `scale_pos_weight`** y **regresión logística con `class_weight`**. En mis corridas, el **classification report** salió **prácticamente igual** en ambos (misma idea: detectar mejor la clase “retraso” que el modelo sin balanceo, a costa de más falsos positivos).

**Decisión:** implemento **`LogisticRegression` con balanceo de clases** (misma receta que la sección 6.b.iii del notebook) como modelo productivo en `model.py`.

**Por qué (métricas + coste en GCP personal):** como no hay ventaja clara de XGBoost en las métricas del notebook, priorizo **despliegue barato** desde mi cuenta de GCP: la regresión logística es **inferencia más ligera** (multiplicación matricial + sigmoide sobre 10 columnas), suele necesitar **menos CPU/RAM** por petición que XGBoost, imagen Docker **más pequeña** si evitas depender de `xgboost` en producción, y en instancias pequeñas (p. ej. Cloud Run con poca concurrencia) eso se traduce en **menos facturación** y arranques más predecibles. Es un argumento de **operación y coste**, no de “subir un 0.01 el F1”.

**Qué descarto:** el modelo **sin balanceo** (p. ej. logística por defecto en 6.b.iv): el **recall de la clase 1** cae casi a cero; para predecir retrasos es inútil aunque la accuracy global parezca alta.

