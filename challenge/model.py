import pandas as pd
from sklearn.linear_model import LogisticRegression

from typing import List, Tuple, Union

# Mismas 10 columnas que el notebook (importancia) y que exigen los tests.
TOP_10_FEATURES = [
    "OPERA_Latin American Wings",
    "MES_7",
    "MES_10",
    "OPERA_Grupo LATAM",
    "MES_12",
    "TIPOVUELO_I",
    "MES_4",
    "MES_11",
    "OPERA_Sky Airline",
    "OPERA_Copa Air",
]


class DelayModel:
    def __init__(self):
        # El estimador entrenado debe vivir aquí (lo usan los tests vía _model.predict).
        self._model = None

    def _ensure_delay(self, data: pd.DataFrame) -> pd.DataFrame:
        """El CSV del challenge trae Fecha-I / Fecha-O; delay se deriva como en exploration.ipynb."""
        df = data.copy()
        if "delay" in df.columns:
            return df
        if "Fecha-I" not in df.columns or "Fecha-O" not in df.columns:
            raise ValueError(
                "Faltan columnas: se necesita 'delay' o bien 'Fecha-I' y 'Fecha-O' para calcularlo."
            )
        df["Fecha-I"] = pd.to_datetime(df["Fecha-I"])
        df["Fecha-O"] = pd.to_datetime(df["Fecha-O"])
        min_diff = (df["Fecha-O"] - df["Fecha-I"]).dt.total_seconds() / 60.0
        df["delay"] = (min_diff > 15).astype(int)
        return df

    def _raw_dummies(self, data: pd.DataFrame) -> pd.DataFrame:
        df = data.copy()
        if "MES" in df.columns:
            df["MES"] = pd.to_numeric(df["MES"], errors="coerce").fillna(0).astype(int)
        return pd.concat(
            [
                pd.get_dummies(df["OPERA"], prefix="OPERA"),
                pd.get_dummies(df["TIPOVUELO"], prefix="TIPOVUELO"),
                pd.get_dummies(df["MES"], prefix="MES"),
            ],
            axis=1,
        )

    def _features_only(self, data: pd.DataFrame) -> pd.DataFrame:
        wide = self._raw_dummies(data)
        # Solo las 10 columnas productivas; el resto se ignora como en el notebook.
        return wide.reindex(columns=TOP_10_FEATURES, fill_value=0).astype(float)

    def preprocess(
        self,
        data: pd.DataFrame,
        target_column: str = None,
    ) -> Union[Tuple[pd.DataFrame, pd.DataFrame], pd.DataFrame]:
        if target_column is None:
            return self._features_only(data)
        df = self._ensure_delay(data)
        if target_column not in df.columns:
            raise ValueError(f"Columna objetivo ausente: {target_column}")
        features = self._features_only(df)
        target = df[[target_column]].copy()
        return features, target

    def fit(self, features: pd.DataFrame, target: pd.DataFrame) -> None:
        y = target.iloc[:, 0].values
        n_y0 = int((y == 0).sum())
        n_y1 = int((y == 1).sum())
        n = len(y)
        # Igual que en exploration.ipynb (sección logística con balanceo).
        class_weight = {1: n_y0 / n, 0: n_y1 / n}
        self._model = LogisticRegression(
            random_state=42,
            class_weight=class_weight,
            max_iter=1000,
        )
        self._model.fit(features, y)

    def predict(self, features: pd.DataFrame) -> List[int]:
        if self._model is None:
            raise ValueError("El modelo no está entrenado.")
        preds = self._model.predict(features)
        return [int(x) for x in preds]
