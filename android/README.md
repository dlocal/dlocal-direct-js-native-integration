# Android dLocal Direct SDK Integration

This Android project demonstrates integration with the dLocal Direct SDK using traditional Android Views and Activities.

## 🚀 Project Structure

### Navigation Architecture
- **MainActivity**: Main screen with three navigation buttons
- **CreateTokenActivity**: Form for creating payment tokens
- **BinInfoActivity**: Form for retrieving BIN information
- **InstallmentsActivity**: Form for getting installment plans

Each screen has its own dedicated activity with a form interface and WebView integration.

## 📱 Screen Details

### 1. Main Screen (MainActivity)
- Three navigation buttons
- Simple launcher screen
- Uses traditional Android Views (ConstraintLayout)

### 2. Create Token Screen (CreateTokenActivity)
**Form Fields:**
- Public Key
- Card Holder Name
- Card Number (PAN)
- CVV
- Expiration Month
- Expiration Year
- Country Code

**Features:**
- Input validation
- WebView integration with dLocal SDK
- Real-time response display
- Action bar with back button

### 3. Get Bin Information Screen (BinInfoActivity)
**Form Fields:**
- Public Key
- BIN (Bank Identification Number)
- Country Code

**Features:**
- Simple form with validation
- WebView integration
- Response display area
- Navigation support

### 4. Get Installments Plan Screen (InstallmentsActivity)
**Form Fields:**
- Public Key
- Amount
- Currency
- Country Code
- BIN

**Features:**
- Amount input validation
- Complete form interface
- WebView SDK integration
- Professional response display

## 🔧 Technical Implementation

### Navigation
- Uses traditional Android Intents for navigation
- Each activity is registered in AndroidManifest.xml
- Back button support with proper parent activity configuration

### WebView Integration
- Each activity has its own WebView instance
- JavaScript bridge for communication between native and web
- dLocal SDK loaded from CDN
- Error handling and response parsing

### UI Components
- Material Design TextInputLayout for forms
- ScrollView for better content organization
- Responsive layouts that work on different screen sizes
- Consistent styling across all screens

## 🔑 Configuration

Currently, the public key is configured directly in the form fields. To use your own key:

1. **Replace the default values** in the layout XML files:
   - `activity_create_token.xml`
   - `activity_bin_info.xml`
   - `activity_installments.xml`

2. **Find and update the default text**:
   ```xml
   android:text="YOUR_PUBLIC_KEY"  <!-- Replace with your actual key -->
   ```

## 🛠️ Development

### Building the Project
```bash
./gradlew clean build
```

### Running on Device/Emulator
```bash
./gradlew installDebug
```

### Project Structure
```
android/
├── app/
│   ├── src/main/
│   │   ├── java/com/dlocal/directwebview/
│   │   │   ├── MainActivity.kt              # Main navigation screen
│   │   │   ├── CreateTokenActivity.kt       # Create token functionality
│   │   │   ├── BinInfoActivity.kt          # Bin information retrieval
│   │   │   └── InstallmentsActivity.kt     # Installments plan retrieval
│   │   ├── res/
│   │   │   └── layout/
│   │   │       ├── activity_main.xml        # Main screen layout
│   │   │       ├── activity_create_token.xml # Create token form
│   │   │       ├── activity_bin_info.xml    # Bin info form
│   │   │       └── activity_installments.xml # Installments form
│   │   └── AndroidManifest.xml             # App configuration
│   └── build.gradle.kts                    # Build configuration
└── README.md                               # This file
```

## 📱 Features

- **Native Android UI** with Material Design components
- **Form validation** for all input fields
- **WebView integration** with dLocal SDK
- **Real-time response display** with JSON formatting
- **Navigation support** with proper back button handling
- **Error handling** with user-friendly messages
- **Professional layout** with scrollable content

## 🚨 Important Notes

- **Update the public key** before testing with real dLocal services
- **Internet permission** is required for SDK loading
- **JavaScript is enabled** in WebView for SDK functionality
- **Each screen is independent** with its own WebView instance

## 🐛 Troubleshooting

### Build Issues
- Make sure all dependencies are properly resolved
- Clean and rebuild if you encounter compilation errors

### Runtime Issues
- Verify your dLocal public key is correct
- Check internet connectivity for SDK loading
- Ensure WebView has proper JavaScript support

### Navigation Issues
- Verify all activities are registered in AndroidManifest.xml
- Check that parent activities are properly configured

## 📄 License

This project is part of the dLocal Direct SDK integration examples.
