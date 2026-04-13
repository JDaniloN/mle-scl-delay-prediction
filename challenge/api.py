from pathlib import Path
from typing import List

import fastapi
import pandas as pd
from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel, validator

from challenge.model import DelayModel

_DATA_CSV = Path(__file__).resolve().parent.parent / "data" / "data.csv"
# Aerolíneas vistas en entrenamiento; se rellena al cargar el modelo.
_VALID_OPERA: set = set()


def _load_trained_model() -> DelayModel:
    global _VALID_OPERA
    data = pd.read_csv(_DATA_CSV, low_memory=False)
    _VALID_OPERA = set(data["OPERA"].astype(str).unique())
    model = DelayModel()
    features, target = model.preprocess(data, target_column="delay")
    model.fit(features, target)
    return model


class FlightIn(BaseModel):
    OPERA: str
    TIPOVUELO: str
    MES: int

    @validator("MES")
    def mes_en_rango(cls, v: int) -> int:
        if not 1 <= v <= 12:
            raise ValueError("MES fuera de rango")
        return v

    @validator("TIPOVUELO")
    def tipo_valido(cls, v: str) -> str:
        if v not in ("I", "N"):
            raise ValueError("TIPOVUELO debe ser I o N")
        return v

    @validator("OPERA")
    def opera_conocida(cls, v: str) -> str:
        if v not in _VALID_OPERA:
            raise ValueError("OPERA no reconocida")
        return v


class PredictIn(BaseModel):
    flights: List[FlightIn]


_MODEL = _load_trained_model()

app = fastapi.FastAPI()


@app.exception_handler(RequestValidationError)
async def validation_400(request: Request, exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(status_code=400, content={"detail": exc.errors()})


@app.get("/health", status_code=200)
async def get_health() -> dict:
    return {"status": "bien"}


@app.post("/predict", status_code=200)
async def post_predict(body: PredictIn) -> dict:
    df = pd.DataFrame([f.dict() for f in body.flights])
    features = _MODEL.preprocess(df)
    preds = _MODEL.predict(features)
    return {"predict": preds}
