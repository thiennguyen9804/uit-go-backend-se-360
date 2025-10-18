# UIT Go Backend SE360

## Getting Started

### Prerequisites

Before running the application, ensure you have the following:

- **Docker** and **Docker Compose** installed on your machine.
- A **Firebase Project** set up with a Service Account Key for Firebase Cloud Messaging (FCM).

### Step 1: Obtain Firebase Service Account Key

To enable Firebase Cloud Messaging (FCM) for sending notifications, you need to download the `firebase-service-account.json` file from your Firebase project:

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Select your project (e.g., `uit-go-backend`).
3. Navigate to **Project settings** (click the gear icon in the top-left corner) > **Service accounts** tab.
4. Under **Firebase Admin SDK**, click **Generate new private key**.
5. Save the downloaded file as `firebase-service-account.json`.
6. Place this file in the `matching-service/src/main/resources/` directory of the project.
   - **Important**: Do not commit this file to Git. Ensure it is added to `.gitignore` to prevent accidental exposure.

### Step 2: Build and Run the Application

After setting up the Firebase Service Account Key, run the following command to build and start the application in detached mode:

```bash
docker compose up --build -d
