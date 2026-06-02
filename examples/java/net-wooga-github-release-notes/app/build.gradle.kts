plugins {
    java
    id("net.wooga.github-release-notes") version "4.1.1"
}

group = "com.example"
version = "1.0.0"

// Minimal config — the plugin needs a repository reference but we have none locally
githubReleaseNotes {
    // No valid config possible without GitHub credentials
}
