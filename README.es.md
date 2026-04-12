# Desafío Software Engineer (ML y LLMs)

## Descripción general

Bienvenido al **Desafío de aplicación Software Engineer (ML y LLMs)**. En él tendrás la oportunidad de acercarte a una parte de la realidad del rol y demostrar tus habilidades y conocimientos en aprendizaje automático y cloud.

## Problema

Se ha proporcionado un notebook de Jupyter (`exploration.ipynb`) con el trabajo de un Data Scientist (en adelante, el DS). El DS entrenó un modelo para predecir la probabilidad de **retraso** de un vuelo que despega o aterriza en el aeropuerto de SCL. El modelo se entrenó con datos públicos y reales; a continuación te damos la descripción del conjunto de datos:

|Columna|Descripción|
|-----|-----------|
|`Fecha-I`|Fecha y hora programadas del vuelo.|
|`Vlo-I`|Número de vuelo programado.|
|`Ori-I`|Código de ciudad de origen programado.|
|`Des-I`|Código de ciudad de destino programado.|
|`Emp-I`|Código de aerolínea del vuelo programado.|
|`Fecha-O`|Fecha y hora de operación del vuelo.|
|`Vlo-O`|Número de operación del vuelo.|
|`Ori-O`|Código de ciudad de origen de la operación.|
|`Des-O`|Código de ciudad de destino de la operación.|
|`Emp-O`|Código de aerolínea del vuelo operado.|
|`DIA`|Día del mes de la operación del vuelo.|
|`MES`|Número del mes de la operación del vuelo.|
|`AÑO`|Año de la operación del vuelo.|
|`DIANOM`|Día de la semana de la operación del vuelo.|
|`TIPOVUELO`|Tipo de vuelo: I = internacional, N = nacional.|
|`OPERA`|Nombre de la aerolínea que opera.|
|`SIGLAORI`|Nombre de la ciudad de origen.|
|`SIGLADES`|Nombre de la ciudad de destino.|

Además, el DS consideró relevante la creación de las siguientes columnas:

|Columna|Descripción|
|-----|-----------|
|`high_season`|1 si `Fecha-I` está entre el 15-dic y el 3-mar, o entre el 15-jul y el 31-jul, o entre el 11-sep y el 30-sep; 0 en caso contrario.|
|`min_diff`|Diferencia en minutos entre `Fecha-O` y `Fecha-I`.|
|`period_day`|Mañana (entre 5:00 y 11:59), tarde (entre 12:00 y 18:59) y noche (entre 19:00 y 4:59), según `Fecha-I`.|
|`delay`|1 si `min_diff` > 15, 0 si no.|

## Desafío

### Instrucciones

1. Crea un repositorio en **GitHub** y copia todo el contenido del desafío en él. Recuerda que el repositorio debe ser **público**.

2. Usa la rama **main** para cualquier entrega oficial que debamos revisar. Se recomienda encarecidamente seguir prácticas de desarrollo con [GitFlow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow). **NOTA: no elimines tus ramas de desarrollo.**

3. Por favor, no cambies la estructura del desafío (nombres de carpetas y archivos).

4. Toda la documentación y explicaciones que debas entregarnos deben ir en el archivo `challenge.md` dentro de la carpeta `docs`.

5. Para enviar tu desafío, debes hacer una petición `POST` a:
    `https://advana-challenge-check-api-cr-k4hdbggvoq-uc.a.run.app/software-engineer`
    Este es un ejemplo del `body` que debes enviar:
    ```json
    {
      "name": "Juan Perez",
      "mail": "juan.perez@example.com",
      "github_url": "https://github.com/juanperez/latam-challenge.git",
      "api_url": "https://juan-perez.api"
    }
    ```
    ##### ***POR FAVOR, ENVÍA LA PETICIÓN UNA SOLA VEZ.***

    Si tu petición fue exitosa, recibirás este mensaje:
    ```json
    {
      "status": "OK",
      "detail": "your request was received"
    }
    ```


***NOTA: Recomendamos enviar el desafío aunque no hayas logrado terminar todas las partes.***

### Contexto

Necesitamos operativizar el trabajo de ciencia de datos para el equipo del aeropuerto. Para ello, hemos decidido habilitar una `API` en la que puedan consultar la predicción de retraso de un vuelo.

*Recomendamos leer el desafío completo (todas sus partes) antes de empezar a desarrollar.*

### Parte I

Para operativizar el modelo, transcribe el archivo `.ipynb` al archivo `model.py`:

- Si encuentras algún error, corrígelo.
- El DS propuso varios modelos al final. Elige el mejor modelo a tu criterio y argumenta por qué. **No es necesario mejorar el modelo.**
- Aplica todas las buenas prácticas de programación que consideres necesarias en este ítem.
- El modelo debe pasar las pruebas ejecutando `make model-test`.

> **Nota:**
> - **No puedes** eliminar ni cambiar el nombre ni los argumentos de los métodos **proporcionados**.
> - **Puedes** cambiar o completar la implementación de los métodos proporcionados.
> - **Puedes** crear las clases y métodos extra que consideres necesarios.

### Parte II

Despliega el modelo en una `API` con `FastAPI` usando el archivo `api.py`.

- La `API` debe pasar las pruebas ejecutando `make api-test`.

> **Nota:**
> - **No puedes** usar otro framework.

### Parte III

Despliega la `API` en tu proveedor de cloud favorito (recomendamos usar GCP).

- Pon la URL de la `API` en el `Makefile` (`línea 26`).
- La `API` debe pasar las pruebas ejecutando `make stress-test`.

> **Nota:**
> - **Es importante que la API siga desplegada hasta que revisemos las pruebas.**

### Parte IV

Buscamos una implementación adecuada de `CI/CD` para este desarrollo.

- Crea una carpeta nueva llamada `.github` y copia dentro la carpeta `workflows` que te proporcionamos.
- Completa tanto `ci.yml` como `cd.yml` (ten en cuenta lo que hiciste en las partes anteriores).
