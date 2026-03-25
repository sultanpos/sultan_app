package lekapin.com.sultan

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
                    val dbPath = context.getDatabasePath("sultan.db").absolutePath
                    context.getDatabasePath("sultan.db").parentFile?.mkdirs()
                    val jwtSecret = call.argument<String>("jwtSecret") ?: "sultan-secret-key"
                    val port = call.argument<Int>("port") ?: 8721
                    val started = SultanServer.start(dbPath, jwtSecret, port)
                    result.success(started)
                }
                "stop" -> {
                    SultanServer.stop()
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
