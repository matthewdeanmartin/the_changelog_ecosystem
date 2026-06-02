plugins {
    java
    id("com.diffplug.spotless-changelog") version "3.1.2"
}

group = "com.example"
version = "1.0.0"

spotlessChangelog {
    changelogFile("CHANGELOG.md")
    // enforceCheck false — don't block normal builds on changelog validation
    enforceCheck(false)
}

tasks.jar {
    manifest {
        attributes["Main-Class"] = "tipcalc.Main"
    }
}
