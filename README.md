
# **CaretPositioner**

**CaretPositioner** is a Swift package that provides precise information about the position and bounds of the text cursor (caret) in macOS applications. It leverages the macOS Accessibility API to retrieve the caret's location and bounding rectangle, making it ideal for accessibility tools, text navigation, and UI enhancements.

---

## **Features**
- Retrieve the position of the text caret (cursor) in macOS apps.
- Get the bounding rectangle of the caret for text fields and text areas.
- Graceful handling of unsupported or restricted applications.
- Built-in fallback mechanisms for robust behavior.

---

## **Installation**

### **Swift Package Manager**
To include `CaretPositioner` in your project:

1. Open your Xcode project.
2. Go to **File > Add Packages...**.
3. Paste the following URL in the search bar:
   ```
   https://github.com/aeastr/CaretPositioner.git
   ```
4. Choose the desired version and click **Add Package**.

---

## **Usage**

add ltr

---

## **Key Methods**

add ltr

---

## **Requirements**
- **macOS 12.0+**
- **Swift 5.5+**
- Accessibility permissions must be granted to the app.
- **App Sanbox must be disabled**

---

## **Permissions**

To enable this package, your app must have **Accessibility permissions**. This can be configured in **System Preferences > Privacy & Security > Accessibility**. Ensure that your app is checked in the list of allowed apps.

---

## **License**
This project is licensed under the [MIT License](LICENSE).

---

## **Contributing**

Contributions are welcome! Please fork this repository and submit a pull request for review.

---

## **Acknowledgments**

- Built with the macOS Accessibility API for seamless integration.
- Inspired by the need for better tools to enhance text navigation and accessibility in macOS apps.
