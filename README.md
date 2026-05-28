# Wub Drive

A Flutter car rental app with Firebase authentication, Firestore database, and Cloudinary image storage. Users can browse and book cars, owners can list and manage their vehicles, and both can chat in real time.

## Setup

1. Clone the repo and install dependencies:
   ```
   flutter pub get
   ```

2. Create a `.env` file in the project root with your credentials:
   ```
   FIREBASE_API_KEY=your_key
   FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_STORAGE_BUCKET=your_project.appspot.com
   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   FIREBASE_APP_ID=your_app_id
   GOOGLE_WEB_CLIENT_ID=your_web_client_id
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   ```

3. Run the app:
   ```
   flutter run
   ```
