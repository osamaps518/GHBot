from pydantic import BaseModel, Field

from ghbot.profiles.models import ActivityLevel, Goal, Sex


class ProfileBody(BaseModel):
    birth_year: int
    birth_month: int = Field(ge=1, le=12)
    sex: Sex
    height_cm: float = Field(ge=130, le=220)
    weight_kg: float = Field(ge=35, le=250)
    activity_level: ActivityLevel
    goal: Goal


class ProfileResponse(BaseModel):
    birth_year: int
    birth_month: int
    sex: str
    height_cm: float
    weight_kg: float
    activity_level: str
    goal: str
