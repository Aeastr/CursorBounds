<div align="center">
  <img width="300" height="300" src="/assets/icon.png" alt="Logo">
  <h1><b>CursorBounds</b></h1>
  <p>Swift package that provides precise information about the position and bounds of the text cursor (caret) in macOS applications. It leverages the macOS Accessibility API to retrieve the caret's location and bounding rectangle, with fallbacks<br>
  <i>Compatible with macOS 12.0 and later</i></p>
</div>

---

## **Positioning**

| ![Example of a cursor caret](assets/caretExample.png) | ![Bounding rectangle of a focused text area](assets/textAreaExample.png) | ![Fallback method using cursor position](assets/fallbackExample.png) |
|:-----------------------------:|:-----------------------------:|:-----------------------------:|
| **Cursor Caret**                 | **Text Field/Area**               | **Cursor**             |
| Identifies the cursor caret, the blinking indicator that shows where text will be inserted. | Determines the bounding rectangle of the currently focused text area or input field. | Uses the screen position of the cursor if other methods are unavailable. |
| Works reliably in most text input scenarios. | Provides a general area when caret data is not accessible. | Acts as a backup to ensure the cursor's position is still available. |
| Preferred method for accuracy. | Handles cases where a text field is active but caret data cannot be retrieved. | Ensures functionality when no other data is accessible. |

CursorBounds primarily finds the cursor caret, _the blinking line or block that indicates where the next character will appear when typing_. 
If the caret's position cannot be retrieved, it falls back to the bounding rectangle of the focused text area or field. 
When neither the caret nor the bounding rectangle is accessible, it uses the position of the mouse cursor as a final fallback.

---

## **Features**
- Retrieve the position of the text caret (cursor) in macOS apps.
- Get the bounding rectangle of the caret for text fields and text areas.
- Graceful handling of unsupported or restricted applications.
- Built-in fallback mechanisms for robust behavior.

---

## **Installation**

### **Swift Package Manager**
To include `CursorBounds` in your project:

1. Open your Xcode project.
2. Go to **File > Add Packages...**.
3. Paste the following URL in the search bar:
   ```
   https://github.com/aeastr/CursorBounds.git
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
- **Accessibility permissions must be granted to the app.**
- **App Sanbox must be disabled**

---

## **Permissions**

To use this package, your app must have **Accessibility permissions**, and **App Sanbox must be disabled**. **Accessibility permissions** can be configured in **System Preferences > Privacy & Security > Accessibility**. Ensure that your app is checked in the list of allowed apps.

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
