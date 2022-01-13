import Foundation

func exampleOfTranslationFrom160To180() {
    let h: Int = 0

    let x = Int.random(in: 0 ..< h + 1) // 160
    for index in 1 ... h { // 165
        if index == x {
            print(".  ") // 170, 173
        } else {
            print(".--") // 171
        }
    }
    print(".") // 190

    // 195 here
}
