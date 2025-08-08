class_name PartyColors
extends RefCounted

# Core party colors
const GREEN = Color(0.2, 0.8, 0.2)
const ORANGE = Color(1.0, 0.5, 0.0)
const GRAY = Color(0.5, 0.5, 0.5)
const BLUE = Color(0.2, 0.4, 0.8)  # Default/neutral color

# Alpha variations for fills
const FILL_ALPHA = 0.3
const BORDER_ALPHA = 0.8
const HIGHLIGHT_ALPHA = 1.0

# UI Colors
const PROGRESS_RED = Color(1.0, 0.4, 0.4)
const PROGRESS_YELLOW = Color(1.0, 0.8, 0.0)
const PROGRESS_BLUE = Color(0.4, 0.8, 1.0)
const DELETION_RED = Color(1.0, 0.2, 0.2)

# Highlight factor for pip selection
const PIP_HIGHLIGHT_FACTOR = 1.5

static func get_party_color(party: PipArea.Party, alpha: float = 1.0) -> Color:
	var color: Color
	match party:
		PipArea.Party.GREEN:
			color = GREEN
		PipArea.Party.ORANGE:
			color = ORANGE
		_:
			color = GRAY
	color.a = alpha
	return color

static func get_party_border_color(party: PipArea.Party) -> Color:
	return get_party_color(party, BORDER_ALPHA)

static func get_party_fill_color(party: PipArea.Party) -> Color:
	return get_party_color(party, FILL_ALPHA)

static func get_default_border_color() -> Color:
	var color = BLUE
	color.a = 0.5
	return color

static func get_default_fill_color() -> Color:
	var color = BLUE
	color.a = FILL_ALPHA
	return color