extends CSGBox3D
@export var Display: TextEdit
@export var OtherDisplay: TextEdit
@export var RotationGuy: Node3D

var wiimoteConnected: bool = false;
var myWiimote: GDWiimote
var prevAccel: Vector3
var SPEED: float = 100;

var accelThreshold: float = 0.09;
var calibrationTimer: float = -0.1;
var gyroThreshold: float = 5.0;

var gravityAccel: Vector3 = Vector3(0, 0, -1);
func _ready():
	Thread.new().start(Callable(self,  "_connect_wiimotes_thread"),1)

func _physics_process(delta: float) -> void:
	if wiimoteConnected:
		var currentAccel: Vector3 = myWiimote.get_accel();
		currentAccel = Vector3(currentAccel.z, currentAccel.x, currentAccel.y) - gravityAccel * RotationGuy.global_basis;
		currentAccel = currentAccel.snapped(Vector3(0.01, 0.01, 0.01))
		
		
		var gyroInfo: Vector3 = myWiimote.get_raw_gyro();
		gyroInfo = Vector3(gyroInfo.x, gyroInfo.z, gyroInfo.y)
		gyroInfo = gyroInfo.snapped(Vector3(0.01, 0.01, 0.01))
		
		Display.text = str(gyroInfo) + "\n" + str(gyroInfo.length()).pad_decimals(2) + "\n" +str(currentAccel) + "\n" + str(currentAccel.length()).pad_decimals(2);
		currentAccel = _CleanWiiVector(currentAccel, accelThreshold)
		gyroInfo = _CleanWiiVector(gyroInfo, gyroThreshold);
		OtherDisplay.text = str(gyroInfo) + "\n" + str(gyroInfo.length()).pad_decimals(2) + "\n" +str(currentAccel) + "\n" + str(currentAccel.length()).pad_decimals(2);
		
		RotationGuy.rotation = lerp(RotationGuy.rotation, RotationGuy.rotation + gyroInfo * delta * 0.02, 0.8);
		position = lerp(position, position + currentAccel * delta * 3, 0.8);
		prevAccel = currentAccel;
		#position.z = 0;
		if Input.is_joy_button_pressed(0, JOY_BUTTON_A):
			RotationGuy.rotation = Vector3(0, PI*0.5, PI*0.5)
			gyroThreshold = myWiimote.get_raw_gyro().length();
			gravityAccel = Vector3(myWiimote.get_accel().z, myWiimote.get_accel().x, myWiimote.get_accel().y);
			accelThreshold = (myWiimote.get_accel() - gravityAccel).length();
			
			print(str(gravityAccel));
			print(str(myWiimote.get_accel()));
			
			position = Vector3.ZERO;
		if Input.is_key_pressed(KEY_K):
			myWiimote.set_gyro_calibration_mode(1);
			myWiimote.reset_gyro_calibration()
			myWiimote.start_gyro_calibration()
			print("Starting Calibration")
			calibrationTimer = 5;
		if calibrationTimer > 0:
			calibrationTimer -= delta;
			if calibrationTimer <=0:
				gyroThreshold = myWiimote.get_raw_gyro().length();
				accelThreshold = myWiimote.get_accel().length();
				print("Finished Calibration")
				myWiimote.stop_gyro_calibration();


func _CleanWiiVector(input: Vector3, threshold: float):
	if input.length() > threshold:
		if input.length() > threshold * 1.5:
			input = input;
		else:
			var difference: float = (input.length() - threshold)*3
			input = input.normalized() * difference;
	else:
		input = Vector3.ZERO;
	return input;



func _connect_wiimotes_thread():
	GDWiimoteServer.initialize_connection(true)
	call_deferred("_on_connection_complete")

func _on_connection_complete():
	var connected_wiimotes = GDWiimoteServer.finalize_connection()
	myWiimote = connected_wiimotes[0];
	await get_tree().create_timer(1.5).timeout
	myWiimote.set_motion_sensing(true);
	myWiimote.set_motion_plus(true);
	myWiimote.set_motion_processing(true);
	await get_tree().create_timer(1.5).timeout
	myWiimote.reset_gyro_calibration()
	await get_tree().create_timer(3.0).timeout
	
	#myWiimote.set_accel_threshold();
	wiimoteConnected = true;
