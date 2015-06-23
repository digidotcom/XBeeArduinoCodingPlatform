XBee Game Controller - Processing library
===

This is a [Processing](http://processing.org) library which utilizes Digi's 
[XBee Java Library](https://github.com/digidotcom/XBeeJavaLibrary) to expose interactions with the 
XBee Game Controller to a Processing application.


# Building the library

These instructions assume that you have the RXTX library installed on your computer, or know which 
file to include inside this library.

 1. Set the `PROCESSING_INSTALL_DIR` environment variable to point to your Processing IDE
    installation. The directory you specify for this value should contains directories such as
    core, java, launch4j, etc.

    - This lets the Gradle build script automatically add the Processing core libraries to the Java
      classpath during compilation. You may skip this step if these libraries (found under
      &lt;install dir&gt;/core/library) are already on your classpath.

 2. Execute the `makeProcessingLibrary` Gradle task. For example:

        $ ./gradlew clean makeProcessingLibrary

    Or, if you are using Windows:

        > .\gradlew.bat clean makeProcessingLibrary

 3. Copy the `xbeegamecontroller` directory from under `build/processing-lib` into your Processing
    libraries directory.