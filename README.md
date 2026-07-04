# VyaparSetu

VyaparSetu is a modern, cross-platform Flutter application designed to simplify business invoicing, party management, expenses, and inventory tracking for small to medium enterprises. Built with performance and local-first capabilities in mind, it provides a user-friendly interface to manage business operations seamlessly.

---

## 🚀 Key Features

- **Invoicing & Billing**: Generate, preview, share, and print invoices as PDF documents. Includes a custom invoice wizard.
- **Voice-Activated Invoicing**: Intelligent speech-to-text integration to create invoices on-the-go via the Voice Invoice Wizard.
- **Inventory/Item Management**: Efficiently track stock levels, item pricing, and categories.
- **Party Ledger**: Manage transactions and balances for buyers and suppliers.
- **Expense Tracker**: Log and categorize daily business expenses.
- **Multi-Language Support (Localization)**: Full localization in English, Hindi (हिंदी), and Gujarati (ગુજરાતી) using `easy_localization`.
- **Offline-First & Local Storage**: Utilizes `Hive` for fast, lightweight local database storage.
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
├── helpers/        # Helper utilities, navigation handlers, and formatters
├── routes/         # Application routing structure
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
