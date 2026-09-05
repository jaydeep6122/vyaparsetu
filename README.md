# VyaparSetu

VyaparSetu is a cross-platform Flutter application that simplifies GST invoicing, party ledgers and expense tracking for small and medium Indian businesses.

---

## 🚀 Key Features

- **Invoicing & Billing**: Generate, preview, share, and print invoices as PDF documents across five designs (three GST, two non-GST), with correct CGST/SGST vs IGST treatment based on place of supply.
- **Item Catalogue**: Maintain items with HSN codes and measuring units for reuse across invoices.
- **Party Ledger**: Manage transactions and balances for buyers and suppliers.
- **Expense Tracker**: Log and categorize daily business expenses.
- **Multi-Language Support (Localization)**: Full localization in English, Hindi (हिंदी), and Gujarati (ગુજરાતી) using `easy_localization`.
- **Local Storage**: Uses `Hive` to cache your profile, businesses and dashboard summaries for fast startup. Note that the app requires a network connection - invoices, parties, items, payments and expenses are fetched on demand.
- **Secure Storage**: Sensitive user credentials are stored using `flutter_secure_storage`.
- **Modern UI/UX**: Seamless light and dark mode toggling with a premium user experience.

---

## 🛠️ Tech Stack & Packages

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.9.2`)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Local Storage**: [Hive](https://pub.dev/packages/hive) & [Hive Flutter](https://pub.dev/packages/hive_flutter)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **PDF/Print Services**: [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)
- **Media Picker**: [image_picker](https://pub.dev/packages/image_picker) & [image_cropper](https://pub.dev/packages/image_cropper)
- **Localization**: [easy_localization](https://pub.dev/packages/easy_localization)

---

## 📂 Directory Structure

Here is a high-level overview of the `lib` directory structure:

```text
lib/
├── api/            # API services, Dio instances, and endpoints
├── components/     # Reusable UI components (buttons, textfields, wizard screens)
├── core/           # Core configurations and central application controller
├── extensions/     # Dart/Flutter extension methods
├── global/         # Constants, theme definitions, and global styling variables
├── helpers/        # Helper utilities, navigation, formatters, GST rules
├── screens/        # Feature screens (Auth, Invoices, Items, Parties, Payments, Settings, etc.)
├── services/       # Core app services
├── storage/        # Hive initialization and database access boxes
├── types/          # Models and custom type definitions
└── main.dart       # App entry point
```

---

## ⚙️ Getting Started

Follow these steps to set up and run VyaparSetu locally on your system.

### Prerequisites

Ensure you have the Flutter SDK installed.

- Check your Flutter version:
  ```bash
  flutter --version
  ```
- Run doctor to check if you have any missing setup requirements:
  ```bash
  flutter doctor
  ```

### Installation

1.  **Clone the repository:**

    ```bash
    git clone git@github.com:jaydeep6122/vyaparsetu.git
    cd vyaparsetu
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run
    ```

## 📝 License

Private codebase. All rights reserved.
