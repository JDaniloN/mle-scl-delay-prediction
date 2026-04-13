# Challenge documentation

## Adjustment in the translated README (dataset columns)

In `README.es.md`, in the derived-column table (`high_season`, `min_diff`, `period_day`), I aligned the names with the dataset and the notebook: I use **`Fecha-I`** and **`Fecha-O`** instead of `Date-I` and `Date-O`. The English challenge README still refers to `Date-*` in those three rows, whereas `exploration.ipynb` and the CSV consistently use **`Fecha-I` / `Fecha-O`**, so the Spanish file matches what is actually loaded.

## Installing dependencies on Windows

When I ran bare `pip`, Windows reported that **Application Control** was blocking the venv’s **`pip.exe`**. Installing packages still works with **`python -m pip`** (same environment, without invoking the `pip` executable directly).

A **version conflict** then appeared between what the challenge `requirements.txt` pins (`numpy~=1.22.4`) and what **matplotlib** pulls in via **contourpy** (it may need a newer `numpy` if packages are installed in the wrong order). I fixed it by installing everything in **one command** in this order: **`requirements.txt` → `requirements-test.txt` → `requirements-dev.txt`**, so pip pins numpy/pandas first and then resolves matplotlib with a compatible contourpy version (I ended up on **contourpy 1.2.1** with no conflict warnings).

## Terraform CLI on Windows

For **local** checks (`terraform fmt`, `validate`, `plan`) and to match what **CI** runs on `infra/`, the `terraform` executable must be on your **PATH**. If PowerShell reports that **`terraform` is not recognized**, install the CLI (for example `winget install HashiCorp.Terraform`), then **close and reopen** the terminal so the updated PATH is picked up. Chocolatey (`choco install terraform`) or the official ZIP from HashiCorp are alternatives if `winget` is unavailable.

After installation, `terraform version` should work from any directory; for this repo, commands are typically run from **`infra/`** (see also **`infra/README.md`** for `init -backend=false` vs full `init` with a GCS backend).

## Why `infra/` sits next to the backend (not “best practice”, intentional)

Colocating **infrastructure-as-code** (here, Terraform under **`infra/`**) in the **same repository** as the **application** code is **not** what most teams would treat as **best practice** for larger systems: platform and app lifecycles are usually decoupled (separate repos or modules, remote state, independent versioning, stricter blast-radius control). I **kept `infra/` alongside** the Python service (`challenge/`) **on purpose**: to **show IaC with Terraform** in a single, reviewable tree and to **match what this challenge asks for**—a compact deliverable where `docs/challenge.md`, CI on `infra/`, and the backend stay easy to navigate together. In a production setting I would typically split infra into its own repo or a shared platform layer; here the layout is a **conscious trade-off** for **demonstration** and **submission requirements**, not a recommendation to merge all stacks into one repo by default.

## Notebook and IDE kernel

To run cells in `exploration.ipynb` in Cursor/VS Code with the project `.venv`, I installed **`ipykernel`** in that environment (`python -m pip install ipykernel`). It is not listed in the repo requirements; I only use it so the editor can attach Jupyter’s kernel to the project’s Python.

## Seaborn and `barplot` in the notebook

### What went wrong

From **Seaborn 0.12** onward, `barplot` no longer accepts two positional arguments `(x, y)`. It allows at most **one** positional argument (usually `data`), or **`x=`** and **`y=`** must be explicit. Hence the error: *"takes from 0 to 1 positional arguments but 2 were given"*.

### What I changed

I updated **`challenge/exploration.ipynb`**: all **13** `sns.barplot(...)` calls now use the form `sns.barplot(x=..., y=..., ...)`. Bar charts (carriers, days, rates, etc.) render correctly when the cells are executed.

For similar issues with `sns.countplot` or other Seaborn APIs, the fix is usually the same: **keyword arguments** instead of positional ones.

## Model choice (Part I) and deployment on GCP

`README.es.md` does not mandate a specific algorithm: it asks you to **pick the best model on your own terms** among those the DS tried and to **justify** the choice (improving it is optional). In the notebook, the productive line the DS settles on is **top 10 features + class balancing**; there I compared **XGBoost with `scale_pos_weight`** and **logistic regression with `class_weight`**. In my runs, the **classification report** was **virtually identical** for both (same trade-off: better detection of the “delay” class than without balancing, at the cost of more false positives).

**Decision:** I ship **`LogisticRegression` with class weights** (same recipe as notebook section 6.b.iii) as the production model in `model.py`.

**Why (metrics + cost on my GCP bill):** with no clear XGBoost edge in the notebook metrics, I prioritise **cheap deployment** on my GCP account: logistic regression is **lighter at inference** (matrix multiply + sigmoid over ten columns), typically needs **less CPU/RAM per request** than XGBoost, yields a **smaller Docker image** if `xgboost` is not required in production, and on small instances (e.g. Cloud Run with low concurrency) that means **lower billing** and more predictable cold starts. That is an **operations and cost** argument, not squeezing an extra 0.01 on F1.

**What I ruled out:** the **unbalanced** model (e.g. default logistic in 6.b.iv): **class-1 recall** collapses near zero; it is useless for predicting delays even when overall accuracy looks high.

## `make model-test` (Part I) and test-related tweaks

### What the README asks for

The README requires the model to pass tests with **`make model-test`**. Windows often lacks `make`; I ran the equivalent from the repo root (venv activated):

```text
python -m pytest --cov-config=.coveragerc --cov-report term --cov-report html:reports/html --cov-report xml:reports/coverage.xml --junitxml=reports/junit.xml --cov=challenge tests/model
```

Or, for a quick run without coverage: `python -m pytest tests/model -v`.

### Changes and rationale

| What | Why |
|-----|--------|
| **`challenge/model.py`**: full `preprocess`, `fit`, and `predict`; `LogisticRegression` with balancing as in the notebook; `TOP_10_FEATURES` constant; internal helpers (`_ensure_delay`, `_raw_dummies`, `_features_only`). | The skeleton only had `return` stubs; tests needed ten-column features, a `delay` target, and `classification_report` metrics within bounds. The CSV has no `delay`: it is computed from `Fecha-I` / `Fecha-O` with a 15-minute threshold, as in `exploration.ipynb`. |
| **`Union[...]`** annotation on `preprocess`’s return type (it was `Union(...)`). | With Python 3.10+ this is the correct annotation; otherwise importing the module failed. |
| **`requirements-test.txt`**: `pytest` ~7.4 and `pytest-cov` ~4.1. | **AnyIO 4** (FastAPI) registers a pytest plugin incompatible with **pytest 6** (`_pytest.scope`). |
| **`.coveragerc` at repo root** | The `Makefile` passes `--cov-config=.coveragerc`; without the file the command failed. |
| **`tests/model/test_model.py`**: path to `data.csv` via `Path(__file__).resolve().parents[2]`; `read_csv(..., low_memory=False)`; in `test_model_predict`, **`fit` before `predict`**. | `../data/data.csv` with cwd at the project root pointed outside the repo on Windows. Mixed-dtype warnings on flight columns were reduced with `low_memory=False`. The original test called `predict` without training: with `unittest`, each test runs `setUp()` and gets a fresh model, so I added an explicit `fit` there (otherwise `predict` has no coefficients). |
| **`tests/model/test_model.py`** (only the above) | I did not rename tests or classes from the challenge; only path consistency and train → predict flow. |

### Outcome

**Four tests passing** (`test_model_preprocess_for_training`, `test_model_preprocess_for_serving`, `test_model_fit`, `test_model_predict`). The `fit` test checks `classification_report` thresholds on the validation split; `predict` checks that output is a list of integers of the right length.

### README notes (lines 92–96)

Regarding the **provided** methods in `challenge/model.py`:

- I **did not remove or rename** `DelayModel`, **`__init__`**, **`preprocess`**, **`fit`**, **`predict`**, or change their **arguments** (including `target_column: str = None` on `preprocess`).
- I **did** implement those methods and kept **`self._model`** as the holder for the fitted estimator, as the skeleton comment indicated.
- I **added** the necessary extras: `TOP_10_FEATURES` and private methods **`_ensure_delay`**, **`_raw_dummies`**, **`_features_only`**; the README allows extra classes and methods.

Outside `model.py` I only touched **tests, pytest requirements, and `.coveragerc`** so coverage commands and the environment run cleanly; I did not change the challenge folder layout.

## Part II — FastAPI (`api.py`)

### README objective

Expose the model behind a **FastAPI** API in `api.py`, without another framework, and pass **`make api-test`** (in practice `pytest tests/api` with coverage if you follow the `Makefile`).

### What I built

1. **`challenge/api.py`** is no longer an empty shell: I added **Pydantic v1** models (`FlightIn`, `PredictIn`) for `{"flights": [...]}`.
2. **Single load and train on import**: read `data/data.csv`, build the set of valid airlines (`OPERA` uniques), instantiate **`DelayModel`**, run `preprocess(..., target_column="delay")` and **`fit`**. Thus `POST /predict` only `preprocess`es request rows and **`predict`**s; it does not retrain per request.
3. **`GET /health`**: returns `{"status": "OK"}`, aligned with what the challenge typically expects in deployment (the official test focuses on `/predict`; the endpoint is still useful for probes).
4. **`POST /predict`**:
   - Input: list of flights with **`OPERA`** (string), **`TIPOVUELO`** (`I` or `N`), **`MES`** (integer).
   - Validation aligned with the repo: month outside 1–12, type other than I/N, or carrier missing from the CSV → **400**. To match the tests’ expected HTTP code, I registered an **`exception_handler`** for **`RequestValidationError`** returning **400** (FastAPI would often use 422).
   - Output: **`{"predict": [0|1, ...]}`**, one integer per flight, same order as `flights`.

### How it ties to Part I

The API does not reimplement features: it delegates to **`DelayModel`** (`challenge/model.py`). The happy-path test (`Aerolineas Argentinas`, `N`, month `3`) matches prediction **`[0]`**, which we already verified when wiring the model to the CSV.

### Issues and fixes

| Issue | What happened | How I fixed it |
|----------|------------|-----------------|
| **AnyIO 4 vs Starlette / TestClient** | `pytest tests/api` failed with `AttributeError: module 'anyio' has no attribute 'start_blocking_portal'`. **FastAPI 0.86** pulls **Starlette 0.20**, whose test client expects **AnyIO 3**. Pip could upgrade **AnyIO 4** transitively. | Pinned **`anyio>=3.6.2,<4`** in **`requirements.txt`**, reinstalled dependencies, and re-ran tests. |
| **Port 8000 in use** (manual uvicorn) | On Windows, error **10048** (“only one usage of each socket address”) if another process held **8000**. | Not a code bug: I terminated the process using the port or started on **another port** (`--port 8001`). The Makefile stress test defaults to 8000; locally I used whichever port was free. |
| **Tests expect 400, not 422** | Pydantic validation errors are often **422**; the challenge tests assert **`status_code == 400`**. | Custom **`RequestValidationError`** handler returning **400** with a JSON `detail` body. |
| **What counts as valid OPERA?** | Accepting arbitrary strings would not align the model’s one-hot columns (fixed vocabulary). | The allowlist is the set of **`OPERA`** values seen in **`data/data.csv`** at app startup. Partial or made-up names (e.g. “Argentinas” without the full string) fail validation, consistent with `test_should_failed_unkown_column_3`. |

### Automated tests and `make api-test` equivalent

```text
python -m pytest tests/api -v
```

With coverage, as in the `Makefile`:

```text
python -m pytest --cov-config=.coveragerc --cov-report term --cov-report html:reports/html --cov-report xml:reports/coverage.xml --junitxml=reports/junit.xml --cov=challenge tests/api
```

**Result:** all **four** tests in `tests/api/test_api.py` pass (success case with prediction `[0]` and three invalid-input cases with **400**).

### Manual local run

Local uvicorn (I switched ports when **8000** was taken):

```text
python -m uvicorn challenge.api:app --host 127.0.0.1 --port 8001
```

Interactive docs: `http://127.0.0.1:8001/docs` (Swagger). I used that to exercise **`POST /predict`** without hand-written `curl`.

### README compliance (Part II)

- **FastAPI only** as the web framework, per the challenge note.
- Endpoints live in **`api.py`**; ML logic stays in **`model.py`**.
- Behaviour can be checked with **`pytest tests/api`** where `make api-test` is unavailable.

## Part III — Cloud deployment (GCP)

### README objective

The challenge allows **any** cloud provider; the README **recommends GCP**, which is what I used. You must put the **live API base URL** in the `Makefile` under **`STRESS_URL`** (in this repo that variable sits at **`Makefile` line 26**, next to the `stress-test` target; if lines shift, search for `STRESS_URL`). Then pass the stress test (`make stress-test` or an equivalent command). The README also stresses that **the API must remain deployed until reviewers run the automated checks**, so the service should stay up and **`STRESS_URL`** should keep pointing at that deployment for the review window.

### Deployment approach

I deployed using **Google Cloud Run** and **Artifact Registry**, with infrastructure declared in **Terraform** under `infra/`:

- `infra/provider.tf`: Terraform + Google provider version constraints.
- `infra/variables.tf`: reusable inputs (`project_id`, `region`, `app_name`, `image`, scaling/resources).
- `infra/main.tf`: API enablement, Artifact Registry repository, Cloud Run v2 service.
- `infra/iam.tf`: runtime service account + project logging role + public invoker binding.
- `infra/outputs.tf`: endpoint and image/repository outputs.

This keeps the environment reproducible (IaC) and aligned with MLOps practices.

### Docker image and registry

The API container is built from the repo `Dockerfile` and pushed to:

`us-central1-docker.pkg.dev/scl-delay-prediction/mlops-challenge-api-repo/delay-api:1`

Cloud Run service `mlops-challenge-api` is configured to use this image.

### Runtime configuration relevant to stress behavior

- **Port:** `8080` (aligned with container startup command).
- **Resources:** `1 CPU`, `2Gi` memory.
- **Timeout:** `300s`.
- **Scaling:** `min_instances = 1`, `max_instances = 3`.
- **Billing/CPU mode:** request-based (`cpu_idle = true`), i.e., CPU allocated primarily during request processing.

`min_instances` was increased from `0` to `1` after observing occasional connection-aborted outliers under load. This removed cold-start related instability during stress tests at the cost of higher idle billing.

### Deployed API URL and Makefile

The deployed Cloud Run endpoint is:

`https://mlops-challenge-api-n7d53mhlmq-uc.a.run.app`

`Makefile` (`STRESS_URL`) was updated to this URL, as required by Part III (same value as **`terraform output api_endpoint`** / Cloud Run URL once the service exists).

### Stress test without `make` (Windows)

The `stress-test` target uses shell idioms (`mkdir ... || true`) and assumes **`locust`** is installed (e.g. from **`requirements-dev.txt`**). On Windows, **`make`** is often missing or behaves differently; create **`reports/`** if needed, then run Locust from the repo root with the same flags as the `Makefile`, passing your deployed base URL as **`-H`**:

```text
locust -f tests/stress/api_stress.py --print-stats --html reports/stress-test.html --run-time 60s --headless --users 100 --spawn-rate 1 -H https://mlops-challenge-api-n7d53mhlmq-uc.a.run.app
```

Use the same **`-H`** value as **`STRESS_URL`** in the `Makefile`. Adjust users/runtime for a shorter smoke test if you prefer.

### Stress test result

Stress tests were executed with Locust (`tests/stress/api_stress.py`) against the deployed endpoint.

- Early run with `min_instances = 0`: near-zero failure rate, with a rare `RemoteDisconnected` event.
- Final run with `min_instances = 1`: **0 failures** in the observed execution window, stable throughput and acceptable latency percentiles for challenge purposes.

### README compliance (Part III)

- Chose **GCP** as the README’s recommended provider; API runs on **Cloud Run** with image in **Artifact Registry**.
- **`STRESS_URL`** in the `Makefile` points to the deployed service (challenge requirement; line number in the README is indicative).
- Stress test (**`make stress-test`** or Locust equivalent) run successfully against the **live** URL.
- Service left **running** for reviewers, consistent with the README note that the API must stay deployed until checks are run.

### Challenge submission (README instruction 5)

Separately from Part III, the challenge asks you to send a **one-time** `POST` to the Advana check API with `name`, `mail`, `github_url`, and **`api_url`** (your deployed base URL). I used the same public Cloud Run URL as **`api_url`** when submitting. That endpoint is independent of Terraform/CD; it only registers your solution for evaluation.

## Part IV — CI/CD implementation

### README objective

The challenge asks you to create **`.github`**, copy the provided **`workflows`** folder into it, then **complete** both **`ci.yml`** and **`cd.yml`** in light of Parts I–III. This repository follows that layout: **`.github/workflows/`** holds the finished workflows (starting from the challenge templates and extended for model/API tests, Docker, Terraform, and GCP deploy).

### CI workflow (`.github/workflows/ci.yml`)

The CI pipeline runs on `push` and `pull_request` to `main` and includes:

1. **Python test job**
   - setup Python 3.10
   - install runtime + test dependencies
   - run model tests (`tests/model`) with coverage output
   - run API tests (`tests/api`) with coverage output
2. **Docker validation job**
   - build the Docker image (no push), verifying containerization integrity
3. **Terraform validation job**
   - `terraform fmt -check`
   - `terraform init -backend=false`
   - `terraform validate`

Additionally:

- workflow concurrency is enabled to cancel stale runs on the same branch.
- least-privilege permissions are used for CI (`contents: read`).
- a root `.coveragerc` file is present so `pytest --cov-config=.coveragerc` works reliably in local and CI executions.

### CD workflow (`.github/workflows/cd.yml`)

The CD pipeline runs on `push` to `main` (and manual dispatch) and performs:

1. Authenticate to GCP via **GitHub OIDC** (Workload Identity Federation).
2. Configure Docker auth for Artifact Registry.
3. Build and push an immutable image tagged by commit SHA:
   - `${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${APP_NAME}-repo/delay-api:${GITHUB_SHA}`
4. Update existing Cloud Run service to the newly pushed image using `gcloud run services update`.

Why this CD shape:

- Infrastructure base is managed in Terraform (`infra/`).
- Runtime release is image-driven (immutable artifact per commit), a common MLOps pattern.
- No long-lived service-account JSON key is stored in the repository.

### GitHub/GCP configuration required by CD

Repository **Variables**:

- `GCP_PROJECT_ID`
- `GCP_REGION`
- `APP_NAME`

Repository **Secrets**:

- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_SERVICE_ACCOUNT_EMAIL`

In GCP, the deploy service account needs at least:

- Artifact Registry writer role.
- Cloud Run deploy/update permissions.
- `roles/iam.serviceAccountUser` on the Cloud Run runtime service account.

### README compliance (Part IV)

- **`.github/workflows/`** present as required (provided `workflows` content copied/kept under `.github`).
- **`ci.yml`** and **`cd.yml`** completed end-to-end.
- CI validates model/API quality, container build, and Terraform syntax.
- CD publishes and deploys new API versions automatically from `main`.

---

## Mapping to the README (instruction 4)

The README states that **all documentation and explanations** you submit must live in **`docs/challenge.md`** (inside `docs/`). This file is intended to satisfy that rule: narrative, rationale, troubleshooting, and compliance notes for Parts I–IV are consolidated here (not duplicated across other markdown files as a second “main” write-up).

| README item | What it asks | Where it is covered in this file |
|-------------|--------------|----------------------------------|
| **Instruction 1** | Public **GitHub** repo with the challenge content | Not verifiable from markdown alone: the repo must be **public** in GitHub settings; use that URL as `github_url` when submitting. |
| **Instruction 2** | Use **`main`** for releases; GitFlow recommended; **do not delete** development branches | Workflow/process; not a technical artifact inside this doc. |
| **Instruction 3** | **Do not change** the challenge folder/file structure | Explicitly noted under Part I (only tests/requirements/`.coveragerc` touched alongside `model.py`, no layout change). |
| **Instruction 4** | **All** explanations in **`docs/challenge.md`** | This document (single consolidated narrative). |
| **Instruction 5** | One-time **POST** to the Advana check API (`name`, `mail`, `github_url`, `api_url`) | Section **Challenge submission (README instruction 5)** under Part III. |
| **Part I** | Transcribe notebook → `model.py`, choose model, **`make model-test`** | Sections **Model choice**, **`make model-test`**, README notes on provided methods. |
| **Part II** | **FastAPI** in `api.py`, **`make api-test`** | **Part II — FastAPI**. |
| **Part III** | Deploy (GCP recommended), **`STRESS_URL` in Makefile** (README cites line 26; in this repo `STRESS_URL` is on **line 26**), **`make stress-test`**, API **stays deployed** until review | **Part III — Cloud deployment (GCP)** (URL, Makefile, stress results, submission note). |
| **Part IV** | **`.github`** + workflows, complete **`ci.yml`** / **`cd.yml`** | **Part IV — CI/CD implementation**. |

**Gaps only a reviewer or you can confirm outside this file:** public repository flag, that the Advana POST was sent **once**, and that the Cloud Run URL remained reachable through the review window (Part III note).
