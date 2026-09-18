extends RefCounted
## Состояние одного слота флота.

var active: bool = false
var color: int = -1
var launch_timer: float = 0.0
var blocked: bool = false
var launch_quota: int = 0
var initial_quota: int = 0
var ships_in_flight: int = 0
