extends Node

## Porcentagem mínima de acertos para "passar" em um objeto (0.0 a 1.0).
## Com 5 perguntas por objeto: 0.6 aprova a partir de 3/5 acertos.
const PASS_PERCENT: float = 0.6

# id (objectName) -> { "correct": int, "total": int, "passed": bool }
var results: Dictionary = {}
var registered: Array = []

# Estatísticas da última tentativa de cada estação, usadas na avaliação final.
# id (objectName) -> { "time_ms": int, "wrong": int, "total": int }
var session_stats: Dictionary = {}

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


## Registra o tempo gasto e os erros da última tentativa em uma estação
## (sobrescreve a tentativa anterior). Alimenta o resumo da tela de vitória.
func record_stats(id: String, time_ms: int, wrong: int, total: int) -> void:
	session_stats[id] = {"time_ms": time_ms, "wrong": wrong, "total": total}


func total_time_ms() -> int:
	var t: int = 0
	for id in session_stats:
		t += int(session_stats[id].get("time_ms", 0))
	return t


func total_wrong() -> int:
	var w: int = 0
	for id in session_stats:
		w += int(session_stats[id].get("wrong", 0))
	return w


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
	session_stats.clear()
	updated.emit()
