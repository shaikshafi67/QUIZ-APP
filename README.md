# 🎯 Quiz App — Flutter + Supabase

A full-featured, production-ready Quiz Application built with **Flutter** and **Supabase**, featuring a modern dark glassmorphism UI, role-based authentication, OTP verification, admin panel, leaderboard, and more.

---

## 📱 Screenshots

> App includes animated splash, premium login, admin dashboard, user home, quiz flow, leaderboard, and profile pages.

---

## 🚀 Features

### 🔐 Authentication
- Email + Password signup and login
- **OTP Email Verification** — 6-digit code sent to email on signup
- **3-Step Password Reset** — Send OTP → Verify → Set new password
- Role-based access: **Admin** and **User**
- Admin signup protected by a **Master Key**
- **Auth Gate** — Auto-redirect to login when session expires
- Session persistence across app restarts

### 👤 User Panel
- Animated home page with greeting, date, and quick actions
- **Profile Page** with:
  - View and edit Full Name, Username, Mobile Number
  - Email (read-only)
  - Change / Remove profile photo (stored in Supabase Storage)
  - Read-only mode by default, Edit mode on tap
  - Save & Cancel buttons
  - Change password with OTP verification
  - Logout with confirmation
- **Quiz Page** — Category + Difficulty based questions with countdown timer
- **Quiz Summary** — Review answers before submitting
- **Result Page** — Score display with correct/incorrect breakdown
- **Leaderboard** — Real-time global rankings
- Dark / Light mode toggle

### 🛠️ Admin Panel
- **Admin Dashboard** with live stats (Questions, Users, Scores)
- Admin profile header with name, photo, and ADMIN badge
- **Add Question** — Batch add questions with optional images
- **Manage Categories** — Rename or delete quiz categories
- **Edit Category** — Edit or delete individual questions
- **View Users** — See all registered users and their roles
- **View All Scores** — Full score history with timestamps
- **Admin Profile Page** with:
  - Edit Full Name, Username, Mobile
  - Change / Remove profile photo
  - 3-step OTP password reset
  - Logout

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Supabase (PostgreSQL) |
| Authentication | Supabase Auth |
| Storage | Supabase Storage |
| Real-time | Supabase Streams |
| State Management | Flutter setState + ValueNotifier |
| Theming | Custom dark/light theme with glassmorphism |

---

## 🗄️ Database Schema

Run this SQL in your **Supabase SQL Editor**:

```sql
-- Users table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name   text,
  username    text,
  email       text,
  phone       text,
  role        text DEFAULT 'user',
  photo_url   text,
  created_at  timestamp with time zone DEFAULT now()
);

-- Quizzes table
CREATE TABLE IF NOT EXISTS quizzes (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category            text,
  category_image_url  text,
  question_text       text,
  image_url           text,
  options             jsonb,
  correct_answer_index int,
  timer_seconds       int DEFAULT 30,
  difficulty          text DEFAULT 'Easy',
  created_at          timestamp with time zone DEFAULT now()
);

-- Scores table
CREATE TABLE IF NOT EXISTS scores (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid,
  email           text,
  full_name       text,
  score           int,
  total_questions int,
  category        text,
  created_at      timestamp with time zone DEFAULT now()
);

-- Disable RLS for development
ALTER TABLE users   DISABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes DISABLE ROW LEVEL SECURITY;
ALTER TABLE scores  DISABLE ROW LEVEL SECURITY;

-- Add extra columns (run if upgrading)
ALTER TABLE users ADD COLUMN IF NOT EXISTS username text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone    text;
```

---

## 🪣 Supabase Storage

1. Go to **Supabase Dashboard → Storage → New Bucket**
2. Name: `app-images` — set to **Public**
3. Run this SQL to allow uploads:

```sql
CREATE POLICY "Authenticated can upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'app-images');

CREATE POLICY "Authenticated can update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'app-images');

CREATE POLICY "Public can view"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'app-images');

CREATE POLICY "Authenticated can delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'app-images');
```

Storage folder structure:
```
app-images/
├── profiles/     ← user & admin profile photos
├── quiz/         ← question images
└── categories/   ← category cover images
```

---

## ⚙️ Supabase Auth Settings

1. **Supabase Dashboard → Authentication → Providers → Email**
2. Turn **"Confirm email" OFF** for development (or configure SMTP for OTP emails)
3. For OTP emails — go to **Authentication → Email Templates → Confirm signup**
4. Add `{{ .Token }}` to the template body to show the 6-digit code

---

## 🔑 Admin Access

| Field | Value |
|---|---|
| Master Key | `12345` |
| How to register | Toggle "Switch to Admin" → Sign Up → enter Master Key |

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  image_picker: ^1.0.7
  intl: ^0.19.0
  cupertino_icons: ^1.0.2
```

---

## 🛠️ Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/shaikshafi67/QUIZ-APP.git
cd QUIZ-APP
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

In `lib/main.dart`, your Supabase credentials are already set:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 4. Run the app

```bash
# Chrome (web)
flutter run -d chrome

# Build for web
flutter build web --no-tree-shake-icons
```

---

## 📁 Project Structure

```
lib/
├── main.dart                  ← App entry, Supabase init
├── auth_gate.dart             ← Auth state listener & auto-redirect
├── app_theme.dart             ← Colors, themes, shared widgets
├── splash_screen.dart         ← Animated splash
├── login_page.dart            ← Login + Signup + Admin toggle
├── otp_verification_page.dart ← 6-digit OTP verification
│
├── user_main_layout.dart      ← Bottom nav wrapper
├── user_home_page.dart        ← Home with quick actions
├── dashboard_page.dart        ← Quiz categories
├── quiz_page.dart             ← Active quiz with timer
├── quiz_summary_page.dart     ← Review before submit
├── result_page.dart           ← Score result
├── leaderboard_page.dart      ← Global rankings
├── difficulty_selection_page.dart
├── profile_page.dart          ← User profile (edit, photo, password)
│
├── admin_dashboard_page.dart  ← Admin home with stats
├── admin_profile_page.dart    ← Admin profile (edit, photo, password)
├── question_editor_page.dart  ← Add / Edit questions
├── manage_categories_page.dart
├── edit_category_page.dart
├── view_users_page.dart
└── view_all_scores_page.dart
```

---

## 👨‍💻 Developer

**Shaik Shafi**
- 5th Semester — CPMAD Project
- Flutter & Supabase

---

## 📄 License

This project is for educational purposes.
