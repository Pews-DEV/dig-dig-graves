class_name TitleTimeline
extends RefCounted
## Tempos da abertura da tela-título (UI/UX §9.3), puros e testáveis. Tudo é função do tempo
## desde a abertura, então "pular" é só saltar para o fim (estado final idêntico).

## 1. Preto → céu com a lua.
const FADE := 0.6
## 2. Descida da câmera, ease-in-out, com parallax por camada.
const DESCENT := 2.0
## 3. Letras caindo uma a uma.
const LETTER_STEP := 0.04
const LETTER_FALL := 0.16
const LETTER_SQUASH := 0.1
const LETTER_COUNT := 12
## A pá crava no G ~60–100 ms depois do pouso da última letra (AUDIO_MANIFEST logo_thunk).
const SHOVEL_DELAY := 0.0
const SHOVEL_FALL := 0.08
const THUNK_SHAKE := 0.15
## 4. Botões sobem escalonados.
const BUTTONS_DELAY := 0.2
const BUTTON_STEP := 0.06
const BUTTON_TIME := 0.25


static func ease_in_out(p: float) -> float:
	var x := clampf(p, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


## Opacidade do preto (1 → 0 em FADE).
static func fade_alpha(t: float) -> float:
	return clampf(1.0 - t / FADE, 0.0, 1.0)


static func descent_start() -> float:
	return FADE


## Progresso 0→1 da descida (já com ease-in-out).
static func descent_progress(t: float) -> float:
	return ease_in_out((t - descent_start()) / DESCENT)


## Deslocamento (px inteiros, para baixo) de uma camada: drop × (1 − p) × fator (UI/UX §9.6).
static func layer_offset(t: float, factor: float, drop: float = 240.0) -> float:
	return roundf(drop * (1.0 - descent_progress(t)) * factor)


static func letters_start() -> float:
	return descent_start() + DESCENT


static func letter_start(i: int) -> float:
	return letters_start() + i * LETTER_STEP


static func letter_land(i: int) -> float:
	return letter_start(i) + LETTER_FALL


static func shovel_start() -> float:
	return letter_land(LETTER_COUNT - 1) + SHOVEL_DELAY


static func thunk_time() -> float:
	return shovel_start() + SHOVEL_FALL


static func button_start(i: int) -> float:
	return thunk_time() + BUTTONS_DELAY + i * BUTTON_STEP


## Fim da abertura (último botão parado).
static func total(button_count: int) -> float:
	return button_start(maxi(button_count, 1) - 1) + BUTTON_TIME


## Queda com aceleração (ease-in): 1 = no alto, 0 = pousou.
static func fall_remaining(t: float, start: float, duration: float) -> float:
	var q := clampf((t - start) / duration, 0.0, 1.0)
	return 1.0 - q * q
