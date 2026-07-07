extends CharacterBody3D

var velocidad_actual: float = 20.0
var gravedad: float = 9.8
var freno_activado: bool = false

# --- VARIABLES DE RED ---
@onready var http_cliente = $ClienteHTTP
@onready var http_alertas = $HTTPAlertas
@onready var timer_alertas = $TimerAlertas
var token_jwt: String = ""

# --- VARIABLES DE INTERFAZ (HUD) ---
@onready var texto_velocidad = $HUD/TextoVelocidad
@onready var texto_estado = $HUD/TextoEstado


func _ready() -> void:
	http_cliente.request_completed.connect(_al_recibir_respuesta_login)
	http_alertas.request_completed.connect(_al_recibir_alertas)
	timer_alertas.timeout.connect(_consultar_alertas)

	texto_estado.text = "Estado: CONECTANDO CON EL BACKEND..."
	texto_estado.add_theme_color_override("font_color", Color(1, 1, 0))

	autenticar_backend()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta

	if freno_activado:
		# Desaceleración física progresiva hasta detenerse
		velocidad_actual = move_toward(velocidad_actual, 0.0, 15.0 * delta)
		texto_velocidad.text = "Velocidad: " + str(round(velocidad_actual)) + " km/h"

	var direccion_frente = transform.basis.z.normalized()
	velocity.x = direccion_frente.x * -velocidad_actual
	velocity.z = direccion_frente.z * -velocidad_actual
	move_and_slide()


# --- COMUNICACIÓN Y LÓGICA ---

func autenticar_backend() -> void:
	var url = "http://localhost:8000/token"
	var datos = "username=admin&password=safedriver123"
	var cabeceras = ["Content-Type: application/x-www-form-urlencoded"]
	http_cliente.request(url, cabeceras, HTTPClient.METHOD_POST, datos)


func _al_recibir_respuesta_login(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var json_respuesta = JSON.parse_string(body.get_string_from_utf8())
		token_jwt = json_respuesta["access_token"]

		texto_estado.text = "Estado: MONITOREO ACTIVO (NORMAL)"
		texto_estado.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		texto_estado.text = "Estado: ERROR DE AUTENTICACIÓN (" + str(response_code) + ")"
		texto_estado.add_theme_color_override("font_color", Color(1, 0, 0))


func _consultar_alertas() -> void:
	if token_jwt != "":
		var url = "http://localhost:8000/alertas/"
		var cabeceras = ["Authorization: Bearer " + token_jwt]
		http_alertas.request(url, cabeceras, HTTPClient.METHOD_GET)


func _al_recibir_alertas(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return

	var alertas = JSON.parse_string(body.get_string_from_utf8())
	if alertas == null or typeof(alertas) != TYPE_ARRAY or alertas.size() == 0:
		return

	# El backend devuelve las alertas en orden DESCENDENTE (más reciente primero),
	# por eso la última alerta real está en la posición [0], no al final del array.
	var ultima_alerta = alertas[0]

	# 1. EVALUAR LA FATIGA / NIVEL DE ALERTA
	var estado_conductor = ultima_alerta.get("nivel", "NORMAL")

	if estado_conductor != "NORMAL":
		freno_activado = true
		texto_estado.text = "¡ALERTA! FRENO AUTOMÁTICO ACTIVADO (" + estado_conductor + ")"
		texto_estado.add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		# RESET: si la última alerta ya es NORMAL, soltamos el freno
		if freno_activado:
			freno_activado = false
		texto_estado.text = "Estado: MONITOREO ACTIVO (NORMAL)"
		texto_estado.add_theme_color_override("font_color", Color(0, 1, 0))

	# 2. SINCRONIZAR LA VELOCIDAD DE TELEMETRÍA (solo si no hay emergencia)
	if not freno_activado:
		var vel_telemetria = ultima_alerta.get("valor_velocidad")  # 👈 ahora sí existe en el backend

		if vel_telemetria != null:
			var vel_float = float(vel_telemetria)

			# Actualizamos el texto en pantalla con el dato real del broker MQTT
			texto_velocidad.text = "Velocidad: " + str(round(vel_float)) + " km/h"

			# Ajustamos la velocidad física del camión virtual al dato recibido
			# (Se divide entre 3 para que visualmente no salga volando del mapa)
			velocidad_actual = vel_float / 3.0
