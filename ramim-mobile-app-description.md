# Role define
Mobile app is available for General user types, Employee User types and Doctor user types. App name "Healthcare Unified". Some screens are for all user types, and some screens are specifically for doctor's usage. I will provide each screen's description, functionalities and API requests+responses. Your task is to generate flutter code, add necessary dependencies to their latest versions. My role is CEO and you are my flutter front-end engineer.

# Color Palette
Primary `#117c58` \
Secondary `#5cb190` \
Text/Border `#1a2823` \
App-Background `#f3f7f5` \
Success `#288756` \
Warning `#d97706` \
Alert/Fail `#dc2626`

# BASE - API endpoint
```bash
https://api.healthcareunified.com/
```
# Startup
When someone opens the app there is a splash screen for 2 seconds. There is a lottie animation in the splash screen. Background is App-Background from color palette. After 2 seconds of splash, user will be rredirected to either home page or login page depending on whether user is logged in or not.

# Login Flow (OTP Authentication)

## Overview

The application uses **OTP-based authentication**. Users log in using one of the following government-issued identification numbers:

* জাতীয় পরিচয়পত্র নম্বর (National ID / NID)
* জন্ম নিবন্ধন নম্বর (Birth Registration Number)
* পাসপোর্ট নম্বর (Passport Number)

Authentication consists of two steps:

1. Request an OTP.
2. Verify the OTP to receive JWT access and refresh tokens.

---

# Login Page

## UI

The Login page contains:

* ID Type selector

  * `nid`
  * `birth_registration`
  * `passport`
* ID Number input
* **"ওটিপি পাঠান"** (Send OTP) button
* **"একাউন্ট নেই? রেজিস্টার করুন"** (Don't have an account? Register) link that navigates to the Registration page.

---

# Step 1 — Request Login OTP

## Request

**POST** `/login`

```json
{
    "id_type": "nid",
    "id_number": "1234567890"
}
```

### Validation

* `id_type` is required.
* `id_number` is required.
* Trim leading and trailing whitespace.
* Reject empty values.

---

## Success Response

If a matching user exists:

**HTTP 200**

```json
{
    "status": "ok",
    "id_type": "nid",
    "id_number": "1234567890",
    "last_digits": "7747"
}
```

### Backend Actions

* Verify that a user exists for the supplied `id_type` and `id_number`.
* Generate a secure OTP.
* Store the OTP in Redis using the combination of `id_type` and `id_number`.
* Send the OTP to the user's registered mobile number.
* Return:

  * `id_type`
  * `id_number`
  * the last four digits of the registered mobile number.

The Flutter application should navigate to the OTP Verification page.

Example UI message:

> OTP has been sent to your mobile number ending with **7747**.

---

## User Not Found

If no user matches the supplied `id_type` and `id_number`:

**HTTP 404**

```json
{
    "status": "error",
    "message": "User not found."
}
```

Flutter displays:

> **দুঃখিত! ব্যবহারকারী খুঁজে পাওয়া যায়নি।**

The user remains on the Login page.

---

## Invalid Request

**HTTP 400**

```json
{
    "status": "error",
    "message": "Invalid request."
}
```

Examples include:

* Missing required fields
* Empty ID number
* Unsupported ID type

---

# Step 2 — Verify Login OTP

## UI

The OTP Verification page contains:

* OTP input
* Verify button
* Resend OTP button
* Countdown timer

---

## Request

**POST** `/login/verify`

```json
{
    "id_type": "nid",
    "id_number": "1234567890",
    "otp": "428193"
}
```

### Backend Actions

* Retrieve the OTP from Redis using `id_type` and `id_number`.
* Verify that the OTP exists, matches, and has not expired.
* Delete the OTP after successful verification.
* Generate JWT access and refresh tokens.

---

## Success Response

**HTTP 200**

```json
{
    "status": "ok",
    "access_token": "<jwt_access_token>",
    "refresh_token": "<jwt_refresh_token>",
    "user_type": "General",
    "expires_in": 3600,
    "token_type": "Bearer"
}
```

The Flutter application should:

* Store the both jwt tokens and user_type securely using flutter_secure_storage.
* Navigate to the Home page.

---

## Invalid OTP

**HTTP 401**

```json
{
    "status": "error",
    "message": "Invalid OTP."
}
```

Flutter displays:

> ভুল OTP। আবার চেষ্টা করুন।

---

## Expired OTP

**HTTP 401**

```json
{
    "status": "error",
    "message": "OTP has expired."
}
```

Flutter displays:

> OTP-এর মেয়াদ শেষ হয়েছে। নতুন OTP পাঠান।

---

## Too Many Attempts

**HTTP 429**

```json
{
    "status": "error",
    "message": "Too many verification attempts."
}
```

---

# Resend OTP

## Request

**POST** `/login/resend`

```json
{
    "id_type": "nid",
    "id_number": "1234567890"
}
```

### Backend Actions

* Verify that a pending login OTP exists.
* Generate a new OTP.
* Invalidate the previous OTP.
* Update the Redis entry.
* Send the new OTP to the user's registered mobile number.

---

## Success Response

**HTTP 200**

```json
{
    "status": "ok",
    "last_digits": "7747"
}
```

# Registration Flow

## Overview

The Registration page allows a new user to create an account using a government-issued identification number.

The user provides:

* ID Type
* ID Number
* Mobile Phone Number
* Blood Group
* Date of Birth

After validating the submitted information, the backend generates an OTP, stores it temporarily, and sends it to the provided mobile number.

The user account is created only after successful OTP verification.

---

# Registration Page

## UI

The Registration page contains:

* ID Type selector

  * `nid`
  * `birth_registration`
  * `passport`
* ID Number input
* Mobile Phone Number input
* Blood Group selector

  * `A+`
  * `A-`
  * `B+`
  * `B-`
  * `AB+`
  * `AB-`
  * `O+`
  * `O-`
* Date of Birth picker
* **"রেজিস্টার করুন"** (Register) button
* **"আগেই একাউন্ট আছে? লগইন করুন"** (Already have an account? Log In) link that navigates to the Login page.

---

# Step 1 — Request Registration OTP

## Request

**POST** `/register`

```json
{
    "id_type": "nid",
    "id_number": "1234567890",
    "phone_number": "01712345678",
    "blood_group": "A+",
    "birth_date": "1998-04-12"
}
```

### Validation

* `id_type` is required.
* `id_number` is required.
* `phone_number` is required.
* `blood_group` is required.
* `birth_date` is required.
* Trim leading and trailing whitespace.
* Reject empty values.
* Validate phone number format.
* Validate blood group.
* Validate birth date.

### Notes

* The same phone number **may be used for multiple accounts** (for example, members of the same family).
* The combination of **ID Type + ID Number** must be unique.

---

## Success Response

**HTTP 200**

```json
{
    "status": "ok",
    "id_type": "nid",
    "id_number": "1234567890",
    "last_digits": "5678"
}
```

### Backend Actions

* Validate the submitted information.
* Ensure the ID is not already registered.
* Generate a secure OTP.
* Store the OTP in Redis using the combination of `id_type` and `id_number`.
* Store the submitted registration information temporarily until OTP verification succeeds.
* Send the OTP to the provided mobile number.
* Return the `id_type`, `id_number`, and the last four digits of the mobile number.

The Flutter application should navigate to the OTP Verification page.

Example UI message:

> OTP has been sent to your mobile number ending with **5678**.

---

## ID Already Registered

**HTTP 409**

```json
{
    "status": "error",
    "message": "This ID is already registered."
}
```

Flutter displays:

> এই পরিচয়পত্র দিয়ে ইতোমধ্যে একটি একাউন্ট নিবন্ধিত হয়েছে।

---

## Invalid Request

**HTTP 400**

```json
{
    "status": "error",
    "message": "Invalid request."
}
```

---

# Step 2 — Verify Registration OTP

## UI

The OTP Verification page contains:

* OTP input
* Verify button
* Resend OTP button
* Countdown timer

---

## Request

**POST** `/register/verify`

```json
{
    "id_type": "nid",
    "id_number": "1234567890",
    "otp": "428193"
}
```

### Backend Actions

* Retrieve the pending registration from Redis using `id_type` and `id_number`.
* Verify that the OTP exists, matches, and has not expired.
* Create the user account using the temporarily stored registration data.
* Delete the OTP and pending registration data from Redis.
* Generate JWT access and refresh tokens.

---

## Success Response

**HTTP 200**

```json
{
    "status": "ok",
    "access_token": "<jwt_access_token>",
    "refresh_token": "<jwt_refresh_token>",
    "user_type": "General",
    "expires_in": 3600,
    "token_type": "Bearer"
}
```

The Flutter application should:

* Store both JWT tokens and user_type securely using flutter_secure_storage.
* Navigate to the Home page.

---

## Invalid OTP

**HTTP 401**

```json
{
    "status": "error",
    "message": "Invalid OTP."
}
```

Flutter displays:

> ভুল OTP। আবার চেষ্টা করুন।

---

## Expired OTP

**HTTP 401**

```json
{
    "status": "error",
    "message": "OTP has expired."
}
```

Flutter displays:

> OTP-এর মেয়াদ শেষ হয়েছে। নতুন OTP পাঠান।

---

## Too Many Attempts

**HTTP 429**

```json
{
    "status": "error",
    "message": "Too many verification attempts."
}
```

---

# Resend OTP

## Request

**POST** `/register/resend`

```json
{
    "id_type": "nid",
    "id_number": "1234567890"
}
```

The backend retrieves the pending registration from Redis, generates a new OTP, invalidates the previous OTP, and sends the new OTP to the registered mobile number.

---

## Success Response

```json
{
    "status": "ok",
    "last_digits": "5678"
}
```

# Feature: Application Skeleton and Screen Distribution

## Objective

Implement a common application skeleton that is used across all authenticated screens after a successful login. The skeleton consists of a shared top app bar and a bottom navigation bar. The navigation items displayed depend on the authenticated user's `user_type`, which is retrieved from `flutter_secure_storage`.

---

## Context

After a successful login, the backend returns a `user_type` field in the response. This value has already been securely stored in `flutter_secure_storage` during the login process.

Every authenticated screen must use the same application skeleton to provide a consistent user experience.

The skeleton includes:

- A common top app bar.
- A bottom navigation bar.
- A content area where individual screens are displayed.
- Navigation between screens without requiring users to log in again.

---

## UI Requirements

### Top App Bar

The top app bar must contain:

- The text **"Healthcare"** aligned to the left.
- A notification icon aligned to the right.
- Empty space between the title and the notification icon.
- Use Flutter's built-in notification icon.

When the notification icon is tapped:

- Navigate to the Notifications screen.

---

### Bottom Navigation Bar

The navigation bar displayed depends on the authenticated user's `user_type`.

### General User

Display exactly three navigation items:

| Navigation | Flutter Icon |
|------------|--------------|
| Home | `Icons.home_rounded` |
| Explore | `Icons.explore_rounded` |
| Settings | `Icons.settings` |

---

### Employee User

Display exactly three navigation items:

| Navigation | Flutter Icon |
|------------|--------------|
| Home | `Icons.home_rounded` |
| Explore | `Icons.explore_rounded` |
| Settings | `Icons.settings` |

---

### Doctor User

Display exactly five navigation items:

| Navigation | Flutter Icon |
|------------|--------------|
| Home | `Icons.home_rounded` |
| Explore | `Icons.explore_rounded` |
| Prescription | `Icons.medication` |
| Appointment | `Icons.format_list_bulleted` |
| Settings | `Icons.settings` |

---

### Navigation Behavior

- The currently selected navigation item must be visually highlighted.
- Selecting a navigation item must display the corresponding screen.
- The bottom navigation bar must remain visible while switching between pages.
- The application skeleton must remain persistent across all authenticated screens.

---

## Functional Requirements

1. Read the authenticated user's `user_type` from `flutter_secure_storage` during application initialization.

2. Based on the stored `user_type`, construct the appropriate bottom navigation bar.

3. Maintain the currently selected navigation index.

4. Tapping a navigation item should:
   - Update the selected index.
   - Display the corresponding screen.
   - Preserve the application skeleton.

5. Tapping the notification icon should navigate to the Notifications screen.

6. Every authenticated page must be rendered inside this shared application skeleton instead of creating separate app bars or bottom navigation bars.

---

## State Management

Manage the following application state:

- Current authenticated user's `user_type`.
- Current selected bottom navigation index.

Changing the selected navigation index should update only the displayed content while preserving the common skeleton.

---

## Local Storage

Read the following value from `flutter_secure_storage`:

- `user_type`

This value determines which navigation items are displayed.

---

## Validation Rules

- Ensure `user_type` exists before constructing the navigation bar.
- Only supported user types should be accepted:
  - General
  - Employee
  - Doctor
- If an unsupported or missing `user_type` is encountered, prevent rendering the authenticated application until the issue is resolved.

---

## Navigation

### General User

```
Home
Explore
Settings
```

### Employee User

```
Home
Explore
Settings
```

### Doctor User

```
Home
Explore
Prescription
Appointment
Settings
```

Additionally:

```
Notification Icon
        ↓
Notifications Screen
```

---

## Error Handling

- If `user_type` cannot be read from secure storage, do not build the authenticated application skeleton.
- If the stored `user_type` is invalid or unsupported, prevent navigation and handle the state gracefully.
- If navigation to the Notifications screen fails, keep the user on the current screen without crashing the application.

# Home navigation
After successful login, user is redirected to homepage. On top of homepage, a card visualizes data that is retrieved from `https://api.healthcareunified.com/fetch-my-basic-info/`.  
Sample request:
```json
{
  "access_token": "access-token-from-flutter-secure-storage"
}
```
Sample Response:
```json
{
  "full_name": "John Doe",
  "last_blood_donation": "19-06-2026",
  "balance": "516.97"
}
```
There is a button also "ব্যালেন্স যোগ করুন". Which redirects to AddBalance screen.  

---
Below the card, there is a TabBar that contains four tabs "প্রেসক্রিপশন", "পরীক্ষাসমূহ", "এপয়েন্টমেন্ট" and "ভর্তির তথ্য".
### Prescription Tab
Prescription Tab fetches data from `https://api.healthcareunified.com/fetch-my-prescription/` endpoint.  
Sample Request:
```json
{
  "access_token": "access-token-from-flutter-secure-storage"
}
```
Sample Response:
```json
{
  "users": [
    "self",
    "father",
    "mother"
  ],
  "prescription_list": [
    {
      "prescription_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "doctor_user_id": "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
      "prescription_date": "2026-07-02",
      "prescription_time": "16:00:00",
      "prescription_address": "General Hospital, Chamber 402, Dhaka",
      "prescription_cc": "Persistent dry cough for 3 days, mild fever.",
      "prescritpion_rf": "Seasonal allergies, mild asthma.",
      "prescription_dx": "Acute Bronchitis",
      "prescription_drugs": [
        "Napa Extra (500mg)",
        "Seclo (20mg)"
      ],
      "prescription_drugs_frequency": [
        "1+0+1",
        "0+0+1"
      ],
      "prescription_drugs_duration": [
        "7 days",
        "5 days"
      ],
      "prescription_drugs_instructions": [
        "After meal",
        "Before sleep"
      ],
      "prescription_notes": "Drink plenty of warm water and rest."
    },
    {
      "prescription_id": "8c2ef5e5-4c8e-5cbe-0cee-3c1e8c4eec7e",
      "doctor_user_id": "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
      "prescription_date": "2026-07-02",
      "prescription_time": "16:00:00",
      "prescription_address": "General Hospital, Chamber 402, Dhaka",
      "prescription_cc": "Persistent dry cough for 3 days, mild fever.",
      "prescritpion_rf": "Seasonal allergies, mild asthma.",
      "prescription_dx": "Acute Bronchitis",
      "prescription_drugs": [
        "Napa Extra (500mg)",
        "Seclo (20mg)"
      ],
      "prescription_drugs_frequency": [
        "1+0+1",
        "0+0+1"
      ],
      "prescription_drugs_duration": [
        "7 days",
        "5 days"
      ],
      "prescription_drugs_instructions": [
        "After meal",
        "Before sleep"
      ],
      "prescription_notes": "Drink plenty of warm water and rest."
    },
    {
      "prescription_id": "7a0cda3c-2b6d-3aca-abdd-1b9d6b2dba5d",
      "doctor_user_id": "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
      "prescription_date": "2026-07-02",
      "prescription_time": "16:00:00",
      "prescription_address": "General Hospital, Chamber 402, Dhaka",
      "prescription_cc": "Persistent dry cough for 3 days, mild fever.",
      "prescritpion_rf": "Seasonal allergies, mild asthma.",
      "prescription_dx": "Acute Bronchitis",
      "prescription_drugs": [
        "Napa Extra (500mg)",
        "Seclo (20mg)"
      ],
      "prescription_drugs_frequency": [
        "1+0+1",
        "0+0+1"
      ],
      "prescription_drugs_duration": [
        "7 days",
        "5 days"
      ],
      "prescription_drugs_instructions": [
        "After meal",
        "Before sleep"
      ],
      "prescription_notes": "Drink plenty of warm water and rest."
    }
  ]
}
```
Flutter should map drugs,frequency,duration,instructions for each user so that this can be seen as traditional Rx. Also, flutter should calculate and build a temporary database of drugs to send medication alert notification even when offline. Suppose prescription date is 2026-07-02 and a drug's duration is 7 days and frequency is 1+0+1. So flutter will  set medication alert everyday 8am in the morning and 10pm at night till 2026-07-09. Duration can be "X days", "X months" or "Continued". Continued means endless duration. Frequency can be "X+X+X" or "X+X+X+X" formatted. Alert times are 8am, 2pm, 6pm and 10pm.  

---

### Tests Tab
This tab fetches test from `https://api.healthcareunified.com/fetch-my-tests/` endpoint.  
Sample request:
```json
{
  "access_token": "access-token-from-flutter-secure-storage"
}
```
Sample response:
```json
{
  "users": ["self", "father", "mother"],
  "tests": [
    [
      {
        "test_id": "7a0cda3c-2b6d-3aca-abdd-1b9d6b2dba5d",
        "test_name": "CBC",
        "test_assigned": "2026-07-02",
        "test_status": "Completed",
      },
      {
        "test_id": "7a0cda3c-2b6d-3aca-abdd-1b9d6b2dba5d",
        "test_name": "CBC",
        "test_assigned": "2026-07-02",
        "test_status": "Sample Collected",
      },
      {
        "test_id": "7a0cda3c-2b6d-3aca-abdd-1b9d6b2dba5d",
        "test_name": "CBC",
        "test_assigned": "2026-07-02",
        "test_status": "Pending",
      }
    ],
    [
      {
        "test_id": "7a0cda3c-2b6d-3aca-abdd-1b9d6b2dba5d",
        "test_name": "CBC",
        "test_assigned": "2026-07-02",
        "test_status": "Completed",
      },
      {
        "test_id": "7a0cda3c-2b6d-3aca-abdd-1b9d6b2dba5d",
        "test_name": "CBC",
        "test_assigned": "2026-07-02",
        "test_status": "Sample Collected",
      },
      {
        "test_id": "7a0cda3c-2b6d-3aca-abdd-1b9d6b2dba5d",
        "test_name": "CBC",
        "test_assigned": "2026-07-02",
        "test_status": "Pending",
      }
    ],
    [
      {
        "test_id": "7a0cda3c-2b6d-3aca-abdd-1b9d6b2dba5d",
        "test_name": "CBC",
        "test_assigned": "2026-07-02",
        "test_status": "Completed",
      },
      {
        "test_id": "7a0cda3c-2b6d-3aca-abdd-1b9d6b2dba5d",
        "test_name": "CBC",
        "test_assigned": "2026-07-02",
        "test_status": "Sample Collected",
      },
      {
        "test_id": "7a0cda3c-2b6d-3aca-abdd-1b9d6b2dba5d",
        "test_name": "CBC",
        "test_assigned": "2026-07-02",
        "test_status": "Pending",
      }
    ]
  ]
}
```

Flutter will list these 