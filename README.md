# ResQintel: AI-Powered All-in-One Disaster App

### Group Name: Four Evermore


---

## 📌 Overview


**ResQintel (Rescue Intel)** is a full-stack mobile application designed to empower Filipino citizens with real-time information, preparedness guides, and emergency alerts for a wide range of disasters, including fires, typhoons, and earthquakes. Leveraging the power of artificial intelligence, image recognition, and cloud technologies, ResQintel serves as an intelligent, inclusive, and proactive disaster management platform.

---

## 🧠 Problem Statement

The Philippines faces frequent natural and man-made disasters such as typhoons, fires, and earthquakes. These catastrophes often result in loss of lives and property, especially in vulnerable communities, due to:

- Limited early warning systems
- Delayed emergency response
- Lack of localized, real-time data
- Fragmented disaster management operations

Current solutions tend to be reactive rather than proactive. ResQintel aims to bridge these gaps through a unified, AI-powered mobile application.

---

## 🎯 Project Objectives

1. **Fire Detection AI**  
   Develop an AI-based fire detection module using image classification technologies like YOLOv11 and TensorFlow.

2. **Educational Disaster Materials**  
   Provide localized and age-appropriate educational resources to teach pre- and post-disaster safety protocols.

3. **Typhoon Monitoring & Geo-mapping**  
   Monitor typhoon activity using weather APIs and visualize impact areas by province and municipality.

4. **Real-time Notifications & Alerts**  
   Automatically send alerts to users and responders during emergencies, reducing response time and potential casualties.

---

## 👥 Target Users

- **Students** (All levels)
- **Teenagers and Young Adults**
- **Middle-aged Individuals and Senior Citizens**
- **Civilians in both Urban and Rural Areas**
- **Local Government Units (LGUs) & Emergency Responders**

---

## 🔍 Project Scope

### ✅ Included Features
- AI-based fire detection through camera/image input
- Typhoon tracking with real-time map-based impact zones
- Earthquake risk awareness and safety checklists
- Educational modules tailored by age group
- Real-time alerts for nearby hazards
- Automated reports sent to responders
- Multi-language interface (Tagalog, English, Local Dialects)
- Configurable settings for user-specific disaster responses

### ❌ Excluded
- Direct integration with satellite communication systems
- Manual input of emergency data by users
- Government-level response dispatch integration (Phase 2)

---

## 🛠 Technologies To Be Used

| Layer             | Tools/Technologies                                  |
|------------------|------------------------------------------------------|
| Mobile Frontend  | Flutter                                              |
| Backend          | Firebase, YOLOv11, TensorFlow                        |
| Database         | Firebase Firestore, Google Cloud Platform            |
| APIs / Libraries | Google Maps API, Text Recognition API, Image Classifier, Gemma, Gemini |
| Dataset Source   | Kaggle                                               |

---

## ⚠️ Anticipated Challenges

1. **Training AI Fire Detection Model**
    - Difficulty in obtaining high-quality fire datasets
    - Balancing performance with resource constraints on mobile

2. **Data Collection & Curation**
    - Ensuring diverse and inclusive datasets for multiple disaster types
    - Processing accurate and verified local information

---

## 📅 Initial Timeline (8 Weeks Plan)

| Week       | Activity                            |
|------------|-------------------------------------|
| Week 1–2   | Planning & Requirements Gathering   |
| Week 3–4   | UI/UX Design                        |
| Week 5–6   | System Development                  |
| Week 7     | Testing & Debugging                 |
| Week 8     | Presentation & Final Output         |

---

## 📘 Getting Started (Flutter Project)

This repository contains the source code for the **ResQintel** mobile app built with Flutter.

### 🔧 Prerequisites

- Flutter SDK
- Android Studio or VS Code
- Firebase project setup

### 🚀 Run Locally

```bash
git clone https://github.com/darknecrocities/ResQintel.git
cd ResQintel
flutter pub get
flutter run
