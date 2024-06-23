#  About Xcode Projects

These Xcode projects contain references to the actual swift files and respource folders located in the GateEngineDemos package. Nothing is a "Copy".

Xcode does not have the ability to live update references folders of source code or respurces. Becuase of this it is strongly recommended that you develop your game as a package first, then make it work with an Xcode project later.

Alternatively, you can develop your game as a swift package library. You can then import that library in both a package executable and in an Xcode project target. When doing it this way Xcode will live update as you edit the library.  
