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

## `make model-test` (Parte I) y ajustes alrededor del test

### Qué pide el README

Que el modelo pase las pruebas con **`make model-test`**. En Windows a menudo no hay `make`; el equivalente es ejecutar desde la raíz del repo (con el venv activo):

```text
python -m pytest --cov-config=.coveragerc --cov-report term --cov-report html:reports/html --cov-report xml:reports/coverage.xml --junitxml=reports/junit.xml --cov=challenge tests/model
```

O, para ir rápido sin cobertura: `python -m pytest tests/model -v`.

### Modificaciones y por qué

| Qué | Por qué |
|-----|--------|
| **`challenge/model.py`**: implementación completa de `preprocess`, `fit` y `predict`; `LogisticRegression` con balanceo como en el notebook; constante `TOP_10_FEATURES`; helpers internos (`_ensure_delay`, `_raw_dummies`, `_features_only`). | El esqueleto solo tenía `return` y los tests necesitaban features de 10 columnas, target `delay` y métricas del `classification_report` dentro de rangos. El CSV no trae `delay`: se calcula con `Fecha-I` / `Fecha-O` y umbral de 15 minutos, igual que en `exploration.ipynb`. |
| **Anotación `Union[...]`** en el tipo de retorno de `preprocess` (antes estaba como `Union(...)`). | Con Python 3.10+ así se anota bien; si no, al importar el módulo fallaba. |
| **`requirements-test.txt`**: `pytest` ~7.4 y `pytest-cov` ~4.1. | **AnyIO 4** (FastAPI) registra un plugin de pytest incompatible con **pytest 6** (`_pytest.scope`). |
| **`.coveragerc` en la raíz** | El `Makefile` pasa `--cov-config=.coveragerc`; sin archivo, el comando fallaba. |
| **`tests/model/test_model.py`**: ruta a `data.csv` con `Path(__file__).resolve().parents[2]`; `read_csv(..., low_memory=False)`; en `test_model_predict`, **`fit` antes de `predict`**. | `../data/data.csv` con cwd en la raíz del proyecto apuntaba fuera del repo en Windows. El aviso de dtypes mixtos en columnas de vuelo se calmó con `low_memory=False`. El test original llamaba a `predict` sin entrenar: con `unittest`, cada test hace `setUp()` y el modelo es nuevo, así que hacía falta un `fit` explícito en ese caso (si no, `predict` no tiene coeficientes). |
| **`tests/model/test_model.py`** (solo lo anterior) | No toqué nombres de tests ni de clases del challenge; solo coherencia de rutas y flujo train → predict. |

### Resultado

**4 tests pasando** (`test_model_preprocess_for_training`, `test_model_preprocess_for_serving`, `test_model_fit`, `test_model_predict`). El de `fit` comprueba umbrales del `classification_report` en el conjunto de validación del split; el de `predict`, que la salida sea una lista de enteros del largo correcto.

### Cumplimiento de las notas del README (líneas 92–96)

Sobre los métodos **proporcionados** en `challenge/model.py`:

- **No eliminé ni renombré** `DelayModel`, ni **`__init__`**, **`preprocess`**, **`fit`**, **`predict`**, ni cambié sus **argumentos** (incluido `target_column: str = None` en `preprocess`).
- **Sí completé** el cuerpo de esos métodos y dejé **`self._model`** como sitio del estimador entrenado, como pedía el comentario del esqueleto.
- **Sí añadí** lo auxiliar que hacía falta: constante `TOP_10_FEATURES` y métodos privados **`_ensure_delay`**, **`_raw_dummies`**, **`_features_only`**; el README permite clases y métodos extra.

Lo único tocado fuera de `model.py` son **tests, requirements de pytest y `.coveragerc`**, para que el comando de cobertura y el entorno sean ejecutables; no cambié la estructura de carpetas del desafío.

## Parte II — API FastAPI (`api.py`)

### Objetivo del README

Desplegar el modelo en una **API con FastAPI** usando `api.py`, sin otro framework, y que pase **`make api-test`** (en la práctica, `pytest tests/api` con cobertura si sigues el `Makefile`).

### Qué construí y cómo

1. **`challenge/api.py`** dejó de ser un esqueleto vacío: añadí modelos **Pydantic v1** (`FlightIn`, `PredictIn`) para el cuerpo `{"flights": [...]}`.
2. **Carga y entrenamiento una sola vez** al importar el módulo: leo `data/data.csv`, construyo el conjunto de aerolíneas válidas (`OPERA` únicos del CSV), instancio **`DelayModel`**, hago `preprocess(..., target_column="delay")` y **`fit`**. Así `POST /predict` solo hace `preprocess` sobre las filas del request y **`predict`**; no reentrena por petición.
3. **`GET /health`**: se mantiene la respuesta `{"status": "OK"}` que ya venían los tests esperando indirectamente (el test oficial se centra en `/predict`, pero el endpoint queda útil para probes en despliegue).
4. **`POST /predict`**:
   - Entrada: lista de vuelos con **`OPERA`** (string), **`TIPOVUELO`** (`I` o `N`), **`MES`** (entero).
   - Validaciones alineadas con lo que comprueba el repo: mes fuera de 1–12, tipo distinto de I/N, u operador que no exista en el CSV → respuesta **400**. Para unificar el código HTTP con lo que piden los tests, registré un **`exception_handler`** de **`RequestValidationError`** que devuelve **400** (FastAPI por defecto usaría 422 en muchos de esos casos).
   - Salida: **`{"predict": [0|1, ...]}`**, un entero por vuelo, mismo orden que en `flights`.

### Cómo encaja con la Parte I

La API no reimplementa features: delega en **`DelayModel`** (`challenge/model.py`). El caso feliz del test (`Aerolineas Argentinas`, `N`, mes `3`) coincide con la predicción **`[0]`** que ya habíamos comprobado al cablear el modelo con el CSV.

### Problemas y soluciones

| Problema | Qué pasaba | Cómo lo resolví |
|----------|------------|-----------------|
| **AnyIO 4 vs Starlette / TestClient** | Al correr `pytest tests/api`, fallaba con `AttributeError: module 'anyio' has no attribute 'start_blocking_portal'`. El **FastAPI 0.86** trae **Starlette 0.20**, que en el cliente de pruebas espera la API de **AnyIO 3**. Pip había podido subir **AnyIO 4** como dependencia transitiva. | Fijar en **`requirements.txt`** la versión: **`anyio>=3.6.2,<4`**, reinstalar dependencias y volver a ejecutar los tests. |
| **Puerto 8000 ocupado** (al probar a mano con uvicorn) | En Windows, error **10048** (“solo se permite un uso de cada dirección de socket”) si ya había otro proceso en **8000**. | No es un bug del código: o se **mata el proceso** que usa el puerto o se arranca en **otro puerto** (`--port 8001`). El stress test del Makefile apunta por defecto a 8000; para desarrollo local importa poco. |
| **Tests esperan 400, no 422** | Pydantic suele traducir errores de validación en **422**; los tests del challenge comprueban **`status_code == 400`**. | Handler personalizado de **`RequestValidationError`** devolviendo **400** con un cuerpo JSON con `detail`. |
| **¿Qué cuenta como OPERA válida?** | Si aceptamos cualquier string, no podríamos alinear con one-hot del modelo (columnas conocidas). | La lista permitida es el conjunto de **`OPERA`** observados en **`data/data.csv`** al cargar la app. Textos parciales o inventados (p. ej. “Argentinas” sin el nombre completo) quedan fuera y devuelven error, coherente con el test `test_should_failed_unkown_column_3`. |

### Pruebas automáticas y comando equivalente a `make api-test`

```text
python -m pytest tests/api -v
```

Con cobertura, como en el `Makefile`:

```text
python -m pytest --cov-config=.coveragerc --cov-report term --cov-report html:reports/html --cov-report xml:reports/coverage.xml --junitxml=reports/junit.xml --cov=challenge tests/api
```

**Resultado:** los **4** tests de `tests/api/test_api.py` en verde (caso OK con predicción `[0]` y tres casos de entrada inválida con **400**).

### Prueba manual local

Levantar el servidor (ajusta el puerto si 8000 está ocupado):

```text
python -m uvicorn challenge.api:app --host 127.0.0.1 --port 8001
```

Documentación interactiva: `http://127.0.0.1:8001/docs` (Swagger). Ahí se puede probar **`POST /predict`** sin escribir `curl` a mano.

### Cumplimiento del README (Parte II)

- **Solo FastAPI** como framework web (tal cual la nota del desafío).
- Endpoints en **`api.py`**; la lógica de ML sigue en **`model.py`**.
- Comportamiento verificable con **`pytest tests/api`** como sustituto de `make api-test` en entornos sin `make`.

