extends CharacterBody2D

const SPEED:float= 130.0
const JUMP_VELOCITY:float = -300.0
const ROLL_BURST_SPEED:float= 400.0  # 蹬地瞬间的爆发初速度
const ROLL_FRICTION:float	 = 800.0     # 地面摩擦阻力

@onready var animated_sprite_2d: AnimatedSprite2D = $Pivot/AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pivot: Node2D = $Pivot

var MAX_JUMPS:int= 3  
var JUMPS_MADE:int= 0 
# 状态机定义区
enum State {
	IDLE,   # 待机
	RUN,    # 跑步
	JUMP,   # 跳跃
	ROLL    # 翻滚
}

# 角色出生默认是待机状态
var current_state = State.IDLE 

# 主函数
func _physics_process(delta: float) -> void:
	# 重力与落地恢复 (不受状态机限制的全局物理)
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		JUMPS_MADE = 0
		# 只有在非翻滚状态落地，才强制归零旋转
		if pivot and current_state != State.ROLL:
			pivot.rotation_degrees = 0

	# 获取玩家输入方向
	var direction := Input.get_axis("move_left", "move_right")

	# 翻转人物图像 
	if current_state != State.ROLL:
		if direction > 0:
			pivot.scale.x = 1
		elif direction < 0:
			pivot.scale.x = -1

	# 状态机分发
	match current_state:
		State.IDLE:
			handle_idle_state(direction)
		State.RUN:
			handle_run_state(direction)
		State.JUMP:
			handle_jump_state(direction)
		State.ROLL:
			handle_roll_state(delta)

	move_and_slide()



#  待机
func handle_idle_state(direction: float) -> void:
	animated_sprite_2d.play("idle")
	velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# 离开待机的条件：
	if Input.is_action_just_pressed("roll") and is_on_floor():
		enter_roll_state()
	elif Input.is_action_just_pressed("jump"):
		perform_jump()
	elif direction != 0:
		current_state = State.RUN

# 跑步
func handle_run_state(direction: float) -> void:
	animated_sprite_2d.play("run")
	velocity.x = direction * SPEED
	
	# 离开跑步房间的条件：
	if Input.is_action_just_pressed("roll") and is_on_floor():
		enter_roll_state()
	elif Input.is_action_just_pressed("jump"):
		perform_jump()
	elif direction == 0:
		current_state = State.IDLE

# 跳跃
func handle_jump_state(direction: float) -> void:
	# 播放基础的空中跳跃切图 (第三跳的旋转由 perform_jump 里的 AnimationPlayer 负责)
	animated_sprite_2d.play("jump")
	
	# 空中允许左右移动
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# 多段跳检测
	if Input.is_action_just_pressed("jump") and JUMPS_MADE < MAX_JUMPS:
		perform_jump()
		
	# 落地检测：脚沾地了，就根据有没有按方向键，切换到待机或跑步
	if is_on_floor():
		if direction == 0:
			current_state = State.IDLE
		else:
			current_state = State.RUN

# 翻滚
func handle_roll_state(delta:float) -> void:
	# 每一帧都让 velocity.x 向 0 靠近，模拟地面阻力
	velocity.x = move_toward(velocity.x,0,ROLL_FRICTION * delta)

# 专门处理跳跃数值和特效的函数
func perform_jump() -> void:
	current_state = State.JUMP # 强制进入跳跃状态
	JUMPS_MADE += 1
	
	if JUMPS_MADE == 1:
		velocity.y = JUMP_VELOCITY
	elif JUMPS_MADE == 2:
		velocity.y = JUMP_VELOCITY * 0.9 
	elif JUMPS_MADE == 3:
		velocity.y = JUMP_VELOCITY * 1.2 
		if animation_player:
			animation_player.play("TripleJumpSpin") # 播放三段跳动画

# 专门处理触发翻滚的函数
func enter_roll_state() -> void:
	current_state = State.ROLL 
	animated_sprite_2d.play("roll") 
	
	# 检查按下翻滚瞬间，玩家有没有按方向键
	var input_diretion := Input.get_axis("move_left", "move_right")
	
	# 如果按了，就瞬间让角色转过去
	if input_diretion != 0:
		pivot.scale.x = input_diretion
	# 如果没按，pivot.scale.x 依然保留着之前的朝向
		
	# 极简爆发逻辑:当前的脸朝向 × 爆发速度
	velocity.x = pivot.scale.x * ROLL_BURST_SPEED 
	
	# 翻滚倒计时 (建议稍微调短一点，比如 0.5秒)
	await get_tree().create_timer(0.4).timeout
	
	# 倒计时结束，解锁状态
	var end_direction := Input.get_axis("move_left", "move_right")
	if end_direction == 0:
		current_state = State.IDLE
	else:
		current_state = State.RUN
