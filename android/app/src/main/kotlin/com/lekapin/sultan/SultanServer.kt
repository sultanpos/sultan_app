package com.lekapin.sultan

object SultanServer {

    init {
        System.loadLibrary("sultan_android")
    }

    external fun start(dbPath: String, jwtSecret: String, port: Int): Boolean
    external fun stop()
    external fun isRunning(): Boolean
}
