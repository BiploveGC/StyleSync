# StyleSync

** StyleSync is an ioS app designed to help users visualize how clothing items will look on their body shape and type, eliminating the time and uncertainty spent trying on outfits. The app will allow users to experiment with different clothing combinations and instantly see how they would look in specific outfits. 

#### 🚀 Features

- 🔁 Switch between multiple avatars
- 🧍 Adjust avatar height and weight in real-time
- 🧢 Add clothing items with texture support
- 🎚️ Fine-tune clothing position, tilt, pitch, and scale
- 🖐️ Use gestures to rotate, scale, and drag models

## 🧰 Requirements

- Xcode 14+
- iOS 15+
- iPhone 12 or newer

## 🔧 Setup Instructions

1. **Clone the repo**
   ```bash
   git clone https://github.com/BiploveGC/StyleSync.git
   ```
2. **Build and Run**
   - Open `StyleSync.xcodeproj`
   - Select an ioS device that is connected to your MAC computer
   - Hit ▶️ Run

## 📱 Running on iPhone

To run the StyleSync app on your iPhone:

1. **Connect Your iPhone**
   - Plug your iPhone into your Mac using a USB or USB-C cable.
   - If prompted on your iPhone, tap **"Trust This Computer"** and enter your passcode.

2. **Open Xcode and Project**
   - Open `StyleSync.xcodeproj` in Xcode.
   - Wait for Xcode to index your project.

3. **Configure Signing and Team**
   - Select the project in the left Project Navigator.
   - Click on the `StyleSync` target > **Signing & Capabilities** tab.
   - Under **Team**, select your Apple ID (or add it if it's not listed):
     - Go to `Xcode > Settings > Accounts` to log into your Apple ID.
     - Use a free or paid developer account.
   - Enable **Automatically manage signing**.
   - Ensure **Bundle Identifier** is unique (e.g., `com.yourname.stylesync`).

4. **Select Your Device**
   - Connect your iPhone and wait until it appears in the top device bar.
   - Choose your iPhone as the build target instead of the simulator.

5. **Build and Run the App**
   - Click the **Run ▶️** button or press `Cmd + R`.
   - Xcode will compile, sign, and install the app on your iPhone.

6. **Trust the Developer Profile** (first-time only)
   - On your iPhone, go to:
     - `Settings > General > VPN & Device Management`
     - Tap your **Apple Developer ID** > Tap **Trust**

7. **Launch StyleSync**
   - Find the StyleSync app icon on your iPhone.
   - Tap to launch and grant any camera or RealityKit permissions when prompted.

##Screenshots
![image](https://github.com/user-attachments/assets/852640d9-88ea-41f6-a51e-3b89ca147afa)
