Topics Covered

Downloaded Flutter SDK and setup

Dart Basics
Variables & Types ✅
String / int / double ✅
bool ✅
final ✅
Functions ✅
Parameters ✅
Arguments ✅
Return values ✅
Classes ✅
Objects ✅
Constructors ✅
Null Safety ✅
? ✅
! ✅
Future ✅
async ✅
await ✅
try / catch ✅
Stream ✅
listen() ✅


1. Attendance
Class-wise attendance data for Classes 6–12 has been removed to simplify the database.
Each school will submit one overall attendance percentage per day.
Structure:
schools/{schoolId}/attendance/{YYYY-MM-DD}
Daily records can be retrieved directly for historical viewing.
Weekly and monthly attendance will be calculated by averaging valid daily attendance percentages.
Missing attendance records will be treated as no data, not 0%.
Attendance values will be validated between 0–100%.
2. Fees
Only the overall fee submission rate for each school is required.
No class-wise fee data will be maintained.
Each fee period will store:
totalDue
totalSubmitted

Submission rate will be calculated as:

Fee Submission Rate = (Total Submitted / Total Due) × 100

Pending fees will be calculated as:

Pending = Total Due − Total Submitted

If totalDue = 0, the submission rate will be treated as N/A rather than 0%.
3. Exam Schedule & Tracking
Exams will be stored as individual scheduled events.
Each exam will contain:
Exam name
Subject
Class
Scheduled date
Status
Completion date
Primary statuses will be scheduled, completed, and cancelled.
"On Track" / "Needs Attention" will not be manually stored; they will be calculated from the schedule.
Exams whose scheduled date has passed and are not completed will be considered pending/behind schedule.

Exam completion rate will be:

Completed Exams / Expected Exams × 100

4. Feedback
Each school can have feedback records containing:
Optional text
Symbol/status such as Good Standing or Needs Review
User and timestamp information.
5. Backend Calculation Principle

The overall architecture follows:

Firestore stores factual/raw data → Backend performs calculations → Flutter displays the results.

Calculated values such as weekly/monthly attendance, fee submission rate, exam completion rate, and exam tracking status will not be treated as independent source data.

6. Security & Data Integrity

The application will use Firebase Authentication to identify users.

Firestore Security Rules will control access based on factors such as:

User authentication status
User role
School
District
Security Requirements
Users must not be able to modify their own authorization-related fields.
Users should only access data permitted by their role and assigned organization.
Financial data must be protected from unauthorized modification.
Calculated values should not be trusted when directly supplied by the client.
Firestore rules will enforce appropriate read/write permissions.

The goal is to ensure that authorization and important application data are controlled by the backend rather than relying solely on Flutter-side validation.

7. Firebase Storage related update
After the addition of Distict ID in the sign up page .
Made succesfull school and user data collection with updated information in the fire storage
Updated the set of firebase rules for correct data input and storage.

8.Seed data Updation

All the seed data has been updated with fields for weekly and monthly data