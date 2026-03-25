package lekapin.com.sultan

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.sultan.android.SultanServer

class MainActivity : FlutterActivity() {
    private val channel = "com.sultan.android/server"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val jwtSecret = call.argument<String>("jwtSecret") ?: "sultan-secret-key"
                    val port = call.argument<Int>("port") ?: 8721
                    val intent = Intent(this, SultanServerService::class.java).apply {
                        action = SultanServerService.ACTION_START
                        putExtra(SultanServerService.EXTRA_JWT_SECRET, jwtSecret)
                        putExtra(SultanServerService.EXTRA_PORT, port)
                    }
                    startForegroundService(intent)
                    // Give the service a moment to start, then check
                    android.os.Handler(mainLooper).postDelayed({
                        result.success(SultanServer.isRunning())
                    }, 500)
                }
                "stop" -> {
                    val intent = Intent(this, SultanServerService::class.java).apply {
                        action = SultanServerService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                "isRunning" -> {
                    result.success(SultanServer.isRunning())
                }
                else -> result.notImplemented()
            }
        }
    }
}
