<div align="center">
  <h1> WorkWell </h1>
  <p>Posture Monitoring Powered by AirPods Motion Sensors</p>
  <p>Straighten up your workday - real-time feedback to build better work habits.</p>
  <p>
    <a href="https://github.com/wizenheimer/workwell/tree/main/media"><strong>Explore the app »</strong></a>
  </p>
</div>

![image](https://github.com/user-attachments/assets/329fb965-d520-41fe-a024-dcfcb76fc1e5)

We spend hours working — often hunched, slouched, or craning our necks without realizing it. **WorkWell** is an iOS app that uses AirPods motion sensors to monitor your head posture in real-time. Get real-time feedback, detailed session reports, and gentle nudges to hold your head high and wear confidence daily.

## Overview

WorkWell continuously tracks your head’s position by leveraging the motion sensors embedded in AirPods Pro. The app detects when your head is tilted too far down or back, signaling poor posture, and provides immediate visual feedback.

![image](https://github.com/user-attachments/assets/a3ffcb93-c423-4b74-9f7c-6057344a157e)


## How It Works

Tracking head orientation involves accurately determining the 3D rotation of the head relative to the world. This process uses data from multiple sensors and applies advanced mathematical techniques to produce stable, precise orientation measurements.

![image](https://github.com/user-attachments/assets/5e92f4a5-06fb-44c5-8b84-5eeec1476e0d)

Your AirPods Pro are packed with:

- **Gyroscope:** Measures angular velocity (how fast the head rotates).
- **Accelerometer:** Measures linear acceleration and gravity.
- **Magnetometer:** Measures magnetic field direction to establish heading relative to magnetic north.

![image](https://github.com/user-attachments/assets/53a1d909-c6d5-41be-9528-bf88639c6d03)

Combining these sensors gives you a 9-axis Inertial Measurement Unit (IMU), which supplies rich, precise motion data.

### Sensor Fusion and Filtering

![image](https://github.com/user-attachments/assets/f7c12a78-3c94-490c-82bb-81086f90796d)


Raw data from these sensors is noisy and prone to errors if used independently:

- Gyroscopes drift over time.
- Accelerometers are sensitive to vibrations.
- Magnetometers can be disturbed by nearby metal objects.

To resolve this, the data is combined using sensor fusion algorithms implemented by Apple’s CoreMotion framework, including:

- **Kalman Filtering:** A recursive algorithm that predicts the system state (head orientation), compares it with actual sensor measurements, and corrects errors, resulting in a smooth and accurate estimate.
- **Coordinate System Alignment:** Sensor data is transformed into a consistent coordinate system relative to the Earth, using gravity and magnetic field references.

### Orientation Representation: Quaternions and Euler Angles

Internally, the orientation is represented using **quaternions** — four-dimensional vectors that encode rotation without suffering from issues like gimbal lock that can affect Euler angles. Quaternions enable smooth interpolation and stable rotation tracking.

These quaternions are then converted to **Euler angles** for interpretation:

- **Pitch:** Rotation around the lateral axis (head nodding up/down).
- **Roll:** Rotation around the longitudinal axis (head tilting side-to-side).
- **Yaw:** Rotation around the vertical axis (head turning left/right).

![image](https://github.com/user-attachments/assets/6babfef4-f998-4bf5-8ba9-29720eb83b5d)

WorkWell primarily monitors the **pitch angle** to determine if the user’s head is tilted forward beyond a defined threshold (e.g., -22°), indicating poor posture.

## Features
![image](https://github.com/user-attachments/assets/a7515e0d-b7e5-4626-976a-65d4cea02c84)

- Real-time head posture monitoring with live visual feedback.
- Posture quality detection based on head pitch thresholds.

![image](https://github.com/user-attachments/assets/604a3fe3-f79e-40ee-b4d0-636250b69551)

- Session tracking with historical posture data.

![image](https://github.com/user-attachments/assets/0ccf3c21-6591-4654-9017-375a43357940)

- Visualizations including pitch graphs and progress indicators.
- Low-latency, smooth updates running at 60 FPS.

## Technical Details

![image](https://github.com/user-attachments/assets/06a337b2-ff3d-4b48-9f8d-8870ee94d324)

- Uses `CMHeadphoneMotionManager` for accessing AirPods Pro motion data.
- Applies low-pass filtering to reduce jitter.
- Processes sensor data on a background thread to maintain UI responsiveness.
- Persists session data using UserDefaults.

## Requirements

- iOS device with AirPods Pro (2nd generation or later).
- iOS 15.0 or higher.

## Installation

Clone the repo and open the Xcode project. Build and run on a compatible device paired with AirPods.

## License

MIT License
