class_name NumberFormat
extends RefCounted
## GDD §5: até 999.999 por extenso; depois "1,23 mi", "bi", "tri", "qua" e notação aa, ab…

const SUFFIXES: Array[String] = ["mi", "bi", "tri", "qua"]


static func format(value: float) -> String:
	var negative := value < 0.0
	var v := absf(value)
	var text: String
	if v < 1000000.0:
		text = _group_thousands(int(floorf(v + 0.000001)))
	else:
		var exp3 := 2
		while v >= pow(1000.0, exp3 + 1):
			exp3 += 1
		var scaled := v / pow(1000.0, exp3)
		var suffix := _suffix(exp3)
		# Trunca para 2 casas: 999,999 mi nunca vira "1.000,00 mi".
		var truncated := floorf(scaled * 100.0 + 0.000000001) / 100.0
		text = ("%.2f" % truncated).replace(".", ",") + " " + suffix
	return ("-" if negative else "") + text


## Inteiro com separador de milhar pt-BR ("1.234").
static func _group_thousands(n: int) -> String:
	var s := str(n)
	var out := ""
	var count := 0
	for i: int in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return out


## exp3 = 2 → mi (1e6), 3 → bi, 4 → tri, 5 → qua, 6 → aa, 7 → ab …
static func _suffix(exp3: int) -> String:
	var i := exp3 - 2
	if i < SUFFIXES.size():
		return SUFFIXES[i]
	var k := i - SUFFIXES.size()
	var first := char(97 + int(k / 26.0) % 26)
	var second := char(97 + k % 26)
	return first + second
