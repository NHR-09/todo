$flutterArgs = $args

$patterns = @(
  'D/FlutterJNI\(.+\): Sending viewport metrics to the engine\.',
  'I/InsetsController\(',
  'I/ImeTracker\(',
  'BLASTBufferQueue',
  'BufferQueueProducer: .*queueBuffer',
  'QUEUE_BUFFER_TIMEOUT'
)

$combined = $patterns -join '|'

flutter run @flutterArgs 2>&1 | ForEach-Object {
  $line = $_.ToString()
  if ($line -notmatch $combined) {
    Write-Output $line
  }
}
