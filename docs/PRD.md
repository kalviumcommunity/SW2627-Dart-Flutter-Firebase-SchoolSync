**# SchoolSync — Product Requirements Document (PRD)**

**## 1. Product Overview**

****SchoolSync**** is a centralized mobile application designed for school district administrators to monitor important information across multiple schools from a single platform.

The application provides a district-level view of:

* Student attendance

* Fee collections and pending payments

* Examination schedules and progress

* Performance status of individual schools

* Operational alerts

* District-wide insights

The primary goal of SchoolSync is to reduce fragmented information and give district administrators a simple, centralized dashboard for monitoring the overall operational status of their schools.

**---**

**# 2. Problem Statement**

A school district may manage multiple schools, with each school maintaining separate information related to attendance, fees, and examinations.

This can make it difficult for district administrators to quickly answer questions such as:

* Which schools have low attendance?

* Which schools have pending fee collections?

* Are examinations progressing as planned?

* Which schools require immediate attention?

* What is the overall operational status of the district?

SchoolSync solves this problem by bringing this information into one centralized mobile dashboard and evaluating it using predefined business rules.

**---**

**# 3. Product Goal**

The main goal of SchoolSync is to provide district administrators with a quick and clear overview of the operational status of all schools under their district.

The application should allow administrators to:

1. Monitor district-wide performance.

2. Compare information between schools.

3. Identify schools that require attention.

4. Track daily, weekly, and monthly attendance.

5. Monitor fee collection and pending amounts.

6. Track examination schedules.

7. Identify whether examination activities are ****On Track****, ****Approaching****, or ****Lagging****.

8. View operational alerts generated from attendance, fee, and examination conditions.

**---**

**# 4. Target User**

**## Primary User**

**### District Administrator**

The primary user of SchoolSync is a district-level administrator responsible for monitoring multiple schools.

The administrator can access:

* District Overview

* Attendance Overview

* Fee Overview

* Examination Overview

* Account/Profile

* School Details

**---**

**# 5. Application Navigation**

Based on the provided UI design, SchoolSync will use a ****bottom navigation bar**** with five primary sections.

| Navigation Item | Page                 |

| --------------- | -------------------- |

| 🏠 Board        | District Overview    |

| ✓ Attendance    | Attendance Overview  |

| ₹ Fees          | Fee Overview         |

| 📅 Exams        | Examination Overview |

| 👤 Profile      | Account              |

The navigation should remain easily accessible throughout the application.

**---**

**# 6. Application Pages**

The MVP will contain the following primary pages:

1. ****District Overview****

2. ****Attendance — District Overview****

3. ****Fees — District Overview****

4. ****Exams****

5. ****Account / Profile****

The application will also require authentication pages:

6. Login

7. Signup

8. Forgot Password

The application also provides school-level detail views that can be accessed from the district-level screens.

**---**

**# 7. Authentication Module**

**## 7.1 Login**

The Login page allows a district administrator to securely access the SchoolSync application.

**### Fields**

* Email

* Password

**### Actions**

* Login

* Forgot Password

* Navigate to Signup

**### Expected Behaviour**

After successful authentication, the user should be redirected to the ****District Overview**** page.

The application monitors the Firebase Authentication state and maintains the appropriate authenticated or unauthenticated application flow.

**---**

**## 7.2 Signup**

The Signup page allows a new administrator account to be created.

**### Fields**

* Full Name

* Email

* Password

* Confirm Password

**### Actions**

* Create Account

* Navigate to Login

**### Expected Behaviour**

The system creates the user's Firebase Authentication account and stores the user's display name.

The user's profile information can be associated with their authenticated Firebase UID.

**---**

**## 7.3 Forgot Password**

The Forgot Password page allows users to reset their password.

**### Flow**

1. User enters their registered email.

2. System sends a password reset request/link using Firebase Authentication.

3. User creates a new password.

4. User logs in using the new password.

**---**

**# 8. District Overview Page**

The District Overview acts as the ****main home dashboard**** of the application.

The page gives administrators a quick summary of the entire district.

**## 8.1 Welcome Section**

The page displays a personalized greeting.

Example:

> Good morning, Priya

The administrator's initials or profile avatar can also be displayed.

**---**

**## 8.2 Summary Cards**

The dashboard contains three main summary cards.

**### Attendance**

Displays the current district attendance percentage.

Example:

```text

92%

Attendance Today

```

The district attendance value is calculated using the latest available attendance data from schools that have attendance records.

**### Fees Collected**

Displays the total fee amount collected across the district.

Example:

```text

₹18.4L

Fees Collected

```

**### Exams**

Displays the number of examinations scheduled during the current week.

Example:

```text

6

Exams This Week

```

**---**

**## 8.3 Pinned Schools**

The administrator can view important or selected schools directly on the dashboard.

Each school card should display:

* School Name

* Number of Students

* Attendance Percentage

* Examination Status

* Overall School Status

* Relevant Operational Alerts

**### Example**

```text

Greenwood Public School

1,240 Students · Attendance 94%

[ ON TRACK ]

```

Another example:

```text

Riverdale High

980 Students · Attendance 72%

[ CRITICAL ]

```

**---**

**## 8.4 School Status Indicators**

Schools use a three-level KPI status system.

**### Healthy**

Indicates that the school's relevant KPI is meeting the defined operational target.

**### Warning**

Indicates that the KPI is below the healthy target but has not reached the critical threshold.

**### Critical**

Indicates that the KPI has crossed the critical threshold and requires attention.

For examinations, the status can also be displayed using user-facing labels:

* **On Track**

* **Approaching**

* **Lagging**

**---**

**# 9. Attendance — District Overview**

The Attendance page provides a school-wise overview of student attendance across the district.

The page title should be:

```text

DISTRICT OVERVIEW

Attendance

```

**---**

**## 9.1 Attendance School Cards**

Each school should have an attendance card.

**### Information Displayed**

* School Name

* Total Number of Students

* Attendance Percentage

* Attendance Progress Bar

* Attendance KPI Status

**### Example**

```text

Greenwood Public School

1,240 Students

94%

████████████████

HEALTHY

```

**---**

**## 9.2 Attendance Status**

Attendance performance is evaluated using the implemented KPI rules:

| Attendance    | Status          |

| ------------- | --------------- |

| 85% and above | Healthy         |

| 75% – 84.9%   | Warning         |

| Below 75%     | Critical        |

The goal is to allow the district administrator to quickly identify schools with attendance concerns.

Missing attendance records should not automatically be treated as 0% attendance.

**---**

**## 9.3 Attendance Periods**

The application supports attendance calculations for:

* Daily attendance

* Weekly attendance

* Monthly attendance

The weekly period is calculated from Monday through Sunday.

The monthly period is calculated from the first day through the last day of the month.

**---**

**# 10. Fees — District Overview**

The Fees page provides a centralized overview of fee collection across all schools.

The page title should be:

```text

DISTRICT OVERVIEW

Fees

```

**---**

**## 10.1 District Fee Summary**

The top of the page displays two main cards.

**### Total Collected**

Example:

```text

₹18.4L

Collected district-wide

```

**### Total Pending**

Example:

```text

₹5.6L

Pending district-wide

```

**---**

**## 10.2 School-wise Fee Information**

Each school should display:

* School Name

* Amount Collected

* Amount Pending

* Fee Submission Rate

* Payment Status

**### Example**

```text

Greenwood Public School

₹6.1L collected · ₹0.9L due

[ HEALTHY ]

```

Another example:

```text

Riverdale High

₹3.8L collected · ₹2.1L due

[ WARNING ]

```

**---**

**## 10.3 Fee Status**

Fee performance is evaluated using the implemented KPI rules:

| Fee Submission Rate | Status   |

| ------------------- | -------- |

| 90% and above       | Healthy  |

| 75% – 89.9%         | Warning  |

| Below 75%           | Critical |

The fee submission rate is calculated as:

```text

Submission Rate =

(Total Submitted / Total Due) × 100

```

The pending amount is calculated as:

```text

Pending Amount =

Total Due - Total Submitted

```

If there is no fee amount due, the system handles the value separately rather than treating the absence of fees as a collection failure.

**---**

**## 10.4 Fee Alerts**

The system generates fee alerts when the fee KPI indicates a problem and there is a pending amount.

| Condition                             | Alert                     |

| ------------------------------------ | ------------------------- |

| Critical rate + pending amount       | Critical Fee Deficit      |

| Warning rate + pending amount        | Fee Collection Lag        |

These alerts help administrators identify schools requiring fee-related attention.

**---**

**# 11. Exams — District Overview**

The Exams page provides a centralized view of upcoming examinations across all schools.

The page title should be:

```text

DISTRICT OVERVIEW

Exams

```

**---**

**## 11.1 Weekly Examination Summary**

The page displays:

```text

This Week

6 Scheduled

```

This gives administrators an overview of examination activity for the current week.

The current week is calculated from Monday through Sunday.

**---**

**## 11.2 Examination Cards**

Each examination card should contain:

* Examination Name

* School Name

* Class

* Examination Date

* Progress Status

**### Example**

```text

Mathematics — Mid Term

Greenwood · Class 8 · 14 Aug

[ ON TRACK ]

```

Another example:

```text

Science — Mid Term

Riverdale High · Class 9 · 16 Aug

[ APPROACHING ]

```

**---**

**## 11.3 Examination Status**

Each active examination is evaluated using its scheduled date.

**### On Track**

An examination is considered On Track when there are no overdue or approaching examinations affecting the school's examination KPI.

**### Approaching**

An examination is considered Approaching when its scheduled date falls within the next **3 days**.

**### Lagging**

An examination is considered Lagging when its scheduled date has already passed and the examination has not been completed or cancelled.

The underlying KPI statuses are:

| Condition                             | KPI Status |

| ------------------------------------ | ---------- |

| Exam date has passed                 | Critical   |

| Exam within next 3 days              | Warning    |

| Exam more than 3 days away           | Healthy    |

Completed and cancelled examinations are excluded from active deadline evaluation.

**---**

**# 12. Account / Profile**

The Account page allows the administrator to view their profile.

The page contains a profile card.

**## 12.1 Profile Information**

The profile card displays:

* Profile Avatar

* User Initials

* Administrator Name

* Role

* District ID / District Information

**### Example**

```text

PN

Priya Nair

DISTRICT ADMINISTRATOR

DISTRICT: RAJASTHAN

```

The user profile is associated with the authenticated Firebase UID.

**---**

**## 12.2 Account Options**

The Account page can provide account-related actions available in the implemented application.

**### Logout**

The administrator can securely sign out from the application.

After logout, the authentication state changes and the user is returned to the unauthenticated flow.

**---**

**# 13. Feedback Feature**

SchoolSync includes a feedback module for communication associated with schools.

The district administrator can view and submit feedback associated with a school.

Each feedback item may contain:

* Feedback ID

* Feedback Message

* Feedback Symbol

* Created By

* Date

The implemented feedback symbols include:

* `good`

* `needs_review`

Feedback is stored under the selected school's feedback collection.

**---**

**# 14. Functional Requirements**

**## Authentication**

* Users must be able to sign up.

* Users must be able to log in.

* Users must be able to reset forgotten passwords.

* Users must be able to log out.

* Only authenticated users can access protected district data.

* Authentication state must be monitored by the application.

**## District Overview**

* Display attendance summary.

* Display fee collection summary.

* Display fee pending amount.

* Display examination count.

* Display school-level KPI status.

* Display operational alerts.

* Allow administrators to access school details.

**## Attendance**

* Display attendance for multiple schools.

* Display student count.

* Display attendance percentage.

* Calculate daily attendance.

* Calculate weekly attendance.

* Calculate monthly attendance.

* Highlight attendance warning and critical schools.

* Apply 85% and 75% attendance thresholds.

**## Fees**

* Display total collected fees.

* Display total pending fees.

* Display school-wise fee data.

* Calculate fee submission rate.

* Apply 90% and 75% fee thresholds.

* Display Healthy, Warning and Critical fee status.

* Generate fee-related alerts when applicable.

**## Exams**

* Display upcoming examinations.

* Display school and class information.

* Display examination dates.

* Display examination status.

* Identify overdue examinations.

* Identify examinations approaching within 3 days.

* Display On Track, Approaching or Lagging status.

**## School Details**

* Display school information.

* Display attendance details.

* Display fee details.

* Display examination details.

* Display school feedback.

**## Account**

* Display administrator profile information.

* Display role and district information.

* Provide logout functionality.

**---**

**# 15. Suggested Data Structure**

The application will mainly manage the following data entities.

**## User**

```text

User

├── uid

├── name

├── email

├── role

├── districtId

└── schoolId (optional)

```

**## School**

```text

School

├── schoolId

├── name

├── address

├── districtId

├── studentCount

├── createdAt

└── updatedAt

```

**## Attendance**

```text

Attendance

├── documentId

├── attendancePercentage

├── date

├── status

├── submittedBy

├── createdAt

└── updatedAt

```

**## Fees**

```text

FeePeriod

├── periodId

├── totalDue

├── totalSubmitted

├── status

├── updatedBy

├── createdAt

└── updatedAt

```

**## Examination**

```text

Examination

├── examId

├── examName

├── subject

├── classNumber

├── scheduledDate

├── status

├── completedAt

├── createdAt

└── updatedAt

```

**## Feedback**

```text

Feedback

├── feedbackId

├── text

├── symbol

├── createdBy

└── createdAt

```

**---**

**# 16. User Flow**

```text

Open SchoolSync

```
    ↓
```

Authentication

```
    ↓
```

Login Successful

```
    ↓
```

District Overview

```
    ↓
```

┌──────┼─────────┬────────┬─────────┐

↓      ↓         ↓        ↓         ↓

Board Attendance  Fees    Exams    Profile

```

**### Detailed Flow**

```text

Login

↓

District Overview

↓

Retrieve School Data

↓

Calculate Attendance / Fees / Exams

↓

Apply KPI Business Rules

↓

Generate School Status and Alerts

↓

Select Navigation Section

↓

Attendance / Fees / Exams / Profile

↓

Select School

↓

View Detailed School Information

```

**---**

**# 17. UI and Design Requirements**

The UI should follow the visual style demonstrated in the provided reference screens.

**## Design Direction**

* Mobile-first interface

* Minimal dashboard design

* Large readable cards

* Soft rounded corners

* Clear typography

* Consistent spacing

* Bottom navigation

* Quick access to major district metrics

* Clear KPI status indicators

**## Main UI Elements**

**### Background**

A warm brown district-themed background with subtle visual texture.

**### Content Cards**

Light-colored cards used for:

* Metrics

* School information

* Fee summaries

* Examination schedules

* Profile information

* Operational alerts

**### Bottom Navigation**

Persistent navigation with five items:

```text

Board | Attend. | Fees | Exams | Profile

```

The currently active page should be visually highlighted.

**---**

**# 18. MVP Scope**

The first version of SchoolSync should focus on the following features.

**## Must Have**

* [x] User Signup

* [x] User Login

* [x] Forgot Password

* [x] User Logout

* [x] District Overview Dashboard

* [x] Attendance Overview

* [x] Daily Attendance Calculation

* [x] Weekly Attendance Calculation

* [x] Monthly Attendance Calculation

* [x] Fee Overview

* [x] Fee Collection Calculation

* [x] Fee Pending Calculation

* [x] Examination Overview

* [x] Overdue Examination Detection

* [x] Approaching Examination Detection

* [x] Healthy / Warning / Critical KPI Status

* [x] On Track / Approaching / Lagging Examination Labels

* [x] School-wise Data

* [x] School Detail View

* [x] Bottom Navigation

* [x] Profile / Account Page

* [x] Firebase Authentication

* [x] Cloud Firestore Database

* [x] Operational Alerts

* [x] School Feedback

* [x] Search / Filtering / Sorting

**## Nice to Have**

These can be implemented later:

* [ ] Push Notifications

* [ ] Advanced Analytics

* [ ] Attendance History Charts

* [ ] Detailed Student Information

* [ ] Detailed Fee Transactions

* [ ] Examination Reminders

* [ ] Multiple District Support

* [ ] Export Reports

* [ ] Cloud Functions for Automated Aggregation

* [ ] Offline-first Support

**---**

**# 19. Recommended Tech Stack**

Since SchoolSync is being developed as a mobile application, the implemented stack is:

| Technology              | Purpose                                |

| ----------------------- | -------------------------------------- |

| Flutter                 | Mobile application development         |

| Dart                    | Application programming language       |

| Firebase Authentication | User authentication                    |

| Cloud Firestore         | Application database                   |

| Flutter Material UI     | UI components                          |

| Git & GitHub            | Version control                        |

Firebase Storage is not required by the current implemented MVP.

**---**

**# 20. Success Criteria**

The SchoolSync MVP will be considered successful if a district administrator can:

1. Create an account and log in securely.

2. View district-level statistics.

3. Monitor attendance across multiple schools.

4. Identify schools with attendance warnings or critical attendance.

5. Monitor collected and pending fees.

6. Identify schools with fee collection warnings or critical fee collection.

7. View upcoming examinations.

8. Identify examinations that are On Track, Approaching, or Lagging.

9. View automatically generated operational alerts.

10. Navigate easily between all major sections.

11. Open detailed information for an individual school.

12. View and submit school feedback.

13. Access their profile and log out securely.

**---**

**# 21. Final Application Structure**

```text

SchoolSync

│

├── Authentication

│   ├── Login

│   ├── Signup

│   └── Forgot Password

│

├── Main Application

│   │

│   ├── 🏠 District Overview

│   │   ├── Attendance Summary

│   │   ├── Fee Summary

│   │   ├── Exam Summary

│   │   ├── School Status

│   │   └── Operational Alerts

│   │

│   ├── 📊 Attendance Overview

│   │   ├── School-wise Attendance

│   │   ├── Student Count

│   │   ├── Daily Attendance

│   │   ├── Weekly Attendance

│   │   ├── Monthly Attendance

│   │   └── KPI Status

│   │

│   ├── 💰 Fees Overview

│   │   ├── Total Collected

│   │   ├── Total Pending

│   │   ├── Submission Rate

│   │   ├── School-wise Fee Status

│   │   └── Fee Alerts

│   │

│   ├── 📝 Exams Overview

│   │   ├── Weekly Exams

│   │   ├── Exam Schedule

│   │   ├── Overdue Exams

│   │   ├── Approaching Exams

│   │   └── On Track / Approaching / Lagging

│   │

│   └── 👤 Account

│       ├── Profile

│       └── Logout

│

├── School Details

│   ├── Attendance

│   ├── Fees

│   ├── Exams

│   └── Feedback

│

└── Future Features

```
├── Push Notifications

├── Advanced Analytics

├── Export Reports

├── Offline-first Support

└── Cloud-based Aggregation
```

```
