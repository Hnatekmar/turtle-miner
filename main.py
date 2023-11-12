import json
import pathlib
from typing import List, Tuple, Optional

import fastapi
import pydantic
from pydantic import BaseModel

app = fastapi.FastAPI()


class Task(BaseModel):
    x: int
    y: int
    width: int
    height: int

    @pydantic.validator("width")
    def width_must_be_positive(cls, value):
        assert value > 0, "width must be positive"
        return value

    @pydantic.validator("height")
    def height_must_be_positive(cls, value):
        assert value > 0, "height must be positive"
        return value
    positions: List[Tuple[int, int]] = []

    def generate_next_position(self):
        for offset_x in range(0, self.width, 3):
            for offset_y in range(0, self.height, 3):
                arr = (self.x + offset_x, self.y + offset_y)
                if arr not in self.positions:
                    self.positions.append(arr)
                    return arr
        return None


class Tasks(BaseModel):
    tasks: List[Task] = []

    def get_next_arr(self) -> Optional[Tuple[int, int]]:
        for task in self.tasks:
            arr = task.generate_next_position()
            if arr:
                return arr
        with open("tasks.json", "w") as f:
            json.dump(self.dict(), f)
        return None


def load_tasks() -> Tasks:
    if pathlib.Path("tasks.json").exists():
        with open("tasks.json") as f:
            return Tasks.parse_obj(json.load(f))
    return Tasks()


tasks = load_tasks()

@app.get("/task")
async def get_task():
    print("Get task", tasks)
    position = tasks.get_next_arr()
    print(position)
    if position is None:
        return fastapi.Response(status_code=404)
    x, y = position
    return str(x) + "," + str(y)


@app.post("/task")
async def post_task(task: Task):
    tasks.tasks.append(task)
    return fastapi.Response(status_code=200)