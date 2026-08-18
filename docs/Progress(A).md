Topics Covered

Downloaded Flutter SDK and setup

Dart Basics
-Var,const,finaly,dynamic
-Loops
-Operators
-Null safety

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
Firebase Authentication will identify users.
Access will be controlled through Firestore security rules based on factors such as role, school, and district.
Users should not be able to modify their own authorization fields.
Financial and calculated data should be protected from unauthorized client-side manipulation.
Current Status

Database structure and mathematical calculation criteria have been conceptually finalized. The next development step is to translate this plan into the actual Firestore collections/documents, field types, indexes, Firebase Security Rules, and backend calculation functions.