class_name AutoTester
extends Node

signal finished(passed : bool)
signal _next()

var test_targets : Array = []

var passed_array : Array[Node]
var failed_array : Array[Node]

func _ready() -> void:
	test_targets = get_tree().get_nodes_in_group("AutoTest")

func run() -> void:
	passed_array = []
	failed_array = []
	for target in test_targets:
		printt(">>>> Panel", target.puzzle_name)
		
		await wait_puzzle_answered(target)
	finished.emit(true)

func on_puzzle_answered(correct : bool, tag : int, errors, line_data : LineData, puzzle : PuzzlePanel) -> void:
	Debugger.print_tag("Test %s"%[puzzle.puzzle_name], "passed" if correct else "failed", Color.GREEN if correct else Color.RED)

func wait_puzzle_answered(puzzle : PuzzlePanel) -> bool:
	var player := GlobalData.get_player()
	var target_pos := puzzle.get_preferred_transform(player.get_current_transform())
	player.move_and_rotate_to_transform(target_pos)
	var data = GameSaver.get_puzzle(puzzle.puzzle_save_name)
	if data == null or data.line == null:
		Debugger.print_tag("Test %s"%[puzzle.puzzle_name], "not answer", Color.HOT_PINK)
		await get_tree().create_timer(0.2).timeout
		return false
	var line : LineData = PuzzleFunction.generate_line_from_idxs(puzzle.puzzle_data, data.line)
	puzzle.start_puzzle(line)
	var answer_func := on_puzzle_answered.bind(puzzle)
	puzzle.puzzle_answered.connect(answer_func)
	await get_tree().create_timer(0.2).timeout
	var ans = puzzle.check_puzzle()
	puzzle.puzzle_answered.disconnect(answer_func)
	await get_tree().create_timer(0.5).timeout
	puzzle.exit_puzzle()
	return true
