extends Node

## Porcentagem mínima de acertos para "passar" em um objeto (0.0 a 1.0).
## Com 3 perguntas por objeto: 0.6 aprova com 2/3; 0.7 exige 3/3 (pois 2/3 = 0,667).
const PASS_PERCENT: float = 0.6

# id (objectName) -> { "correct": int, "total": int, "passed": bool }
var results: Dictionary = {}
var registered: Array = []

signal updated
signal completed


func register(id: String) -> void:
	if not registered.has(id):
		registered.append(id)
		# Avisa a HUD para que o contador/barra reflita o total assim que as
		# estações entram na cena (senão começa em 0/0 em vez de 0/8).
		updated.emit()


func set_result(id: String, correct: int, total: int) -> void:
	var passed: bool = total > 0 and float(correct) / float(total) >= PASS_PERCENT

	# Guardar sempre o melhor resultado (não rebaixa um objeto já aprovado).
	var prev: Dictionary = results.get(id, {})
	var prev_correct: int = prev.get("correct", -1)
	if correct >= prev_correct:
		results[id] = {"correct": correct, "total": total, "passed": passed or prev.get("passed", false)}
	elif prev.get("passed", false):
		results[id]["passed"] = true

	updated.emit()
	if all_passed():
		completed.emit()


func is_passed(id: String) -> bool:
	return results.get(id, {}).get("passed", false)


func passed_count() -> int:
	var n: int = 0
	for id in registered:
		if is_passed(id):
			n += 1
	return n


func total_count() -> int:
	return registered.size()


func all_passed() -> bool:
	return registered.size() > 0 and passed_count() == registered.size()


func reset() -> void:
	results.clear()
	updated.emit()
