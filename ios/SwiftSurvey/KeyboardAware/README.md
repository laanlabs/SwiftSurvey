# KeyboardAdaptiveSwiftUI

[Original github repo here](https://github.com/ralfebert/KeyboardAwareSwiftUI.git)

A Swift package that adds a modifier `.keyboardAware()` to SwiftUI views to handle the keyboard appearing:

Usage:

```swift
struct KeyboardAwareView: View {
    @State var text = "example"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(0 ..< 20) { i in
                        Text("Text \(i):")
                        TextField("Text", text: self.$text)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom, 10)
                    }
                }
                .padding()
            }
            .keyboardAware()  // <--- the view modifier
            .navigationBarTitle("Keyboard Example")
        }

    }
}
````

Result:

<img src="https://github.com/ralfebert/KeyboardAwareSwiftUI/blob/master/docs/example.png" width="250" style="border:1px solid black;"/>

## See also

- [Keyboard Avoidance for SwiftUI Views](https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/).
- [AdaptsToSoftwareKeyboard.swift](https://gist.github.com/scottmatthewman/722987c9ad40f852e2b6a185f390f88d)
- [Move TextField up when the keyboard has appeared by using SwiftUI?](https://stackoverflow.com/questions/56491881/move-textfield-up-when-thekeyboard-has-appeared-by-using-swiftui-ios)
