class_name AutoTester
extends Node

var passed_array : Array[Node]
var failed_array : Array[Node]

var solutions : Array[LineData] = []

func solve() -> void:
	var current_panel : PuzzlePanel = GlobalData.get_preferred_puzzle_panel()
	if current_panel == null: current_panel = GlobalData.get_current_puzzle_panel()
	if current_panel == null:
		Debugger.print_tag("No Puzzle Found", "solver finished")
		return
	solutions.clear()
	var ans : LineData = await solve_puzzle(current_panel.puzzle_data, current_panel)

func advance_line_data(puzzle_data : PuzzleData, line_data : LineData, panel : PuzzlePanel, max_solutions : int = 100) -> void:
	if solutions.size() >= max_solutions: return
	var current_vertice := line_data.get_current_vertice()
	if current_vertice.type == Vertice.VerticeType.END:
		var ans = panel.check_puzzle_answer(line_data)
		if ans.tag >= 0: solutions.append(line_data)
		return
	var sround = current_vertice.neighbours
	for id in sround:
		var edge := puzzle_data.get_edge_by_id(id)
		if line_data.pass_through(edge.get_forward_vertice(current_vertice), true): continue
		var _line_data := line_data.duplicate()
		_line_data.add_edge_segment(edge)
		var _line_data_copy := _line_data.duplicate()
		panel.on_move_finished(_line_data_copy)
		if _line_data_copy.get_length() < line_data.get_length(): continue
		advance_line_data(puzzle_data, _line_data, panel)
	return

func solve_puzzle(puzzle_data : PuzzleData, panel : PuzzlePanel) -> LineData:
	for start_vert in puzzle_data.vertices_start:
		var line_data := LineData.new(start_vert)
		advance_line_data(puzzle_data, line_data, panel)
	if solutions.size() > 0:
		Debugger.print_tag(panel.puzzle_name, "found %d solution(s)" % [solutions.size()], Color.MEDIUM_PURPLE)
		for s in solutions.size():
			Debugger.print_tag(" >> Solution", "%d / %d" % [s + 1, solutions.size()], Color.MEDIUM_PURPLE)
			var solution := solutions[s]
			panel.start_puzzle(solution)
			panel.commit_move_line(solution)
			panel.confirm()
			await get_tree().create_timer(0.2).timeout
	solutions.clear()
	return null
