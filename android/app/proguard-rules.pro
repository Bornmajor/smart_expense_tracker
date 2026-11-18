# Extra rules for the release build's code shrinker (R8).

# The ML Kit text recognition plugin mentions the Chinese, Devanagari, Japanese
# and Korean recognizers. We only use Latin text, so those optional modules are
# not included, and nothing ever calls them. Without these lines R8 stops the
# release build with "Missing class ...".
#
# If another script is ever added to the app, add its module as a dependency in
# android/app/build.gradle.kts and remove the matching lines here.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# ML Kit starts itself by looking up its "registrar" classes by name and calling
# their empty constructors. Nothing in the code calls those constructors, so R8
# removes them, ML Kit never starts, and every receipt fails to read in the
# release build (the debug build does not shrink, so it works). Keep them.
-keep class com.google.mlkit.**.*Registrar { <init>(); }
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
