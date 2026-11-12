import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// On-device voice (TTS) for WhatsAyX v2.
///
/// ENGINE: Supertonic 3 (Supertone Inc., OpenRAIL-M) via sherpa-onnx
/// (`sherpa_onnx` Flutter plugin, FFI over ONNX Runtime) — NOT Kokoro
/// (rejected by the user 2026-11-12: "Kokoro mat use kar") and NOT
/// VoxCPM (genuinely infeasible on a phone: 2B params, ~5 GB weights,
/// needs an 8 GB-VRAM CUDA GPU — see the earlier v1.1.0 notes).
///
/// Why Supertonic 3:
///  - Hindi is native: 31 languages incl. `hi`, one shared model.
///  - Soft, natural human voice — the SAME voice family this user's
///    Hindi dubbing pipeline already uses (Supertonic 3, proven soft
///    Hindi in his env: venv ~/workspace/supertonic-venv).
///  - Real Flutter inference path: sherpa-onnx has a Supertonic
///    backend (`OfflineTtsSupertonicModelConfig`) with a Dart API
///    example; no phonemizer needed (it uses a unicode indexer, and
///    sherpa-onnx removed the espeak-ng dependency).
///  - 10 built-in voices (F1–F5 female, M1–M5 male); `voice.bin`
///    packs them in alphabetical filename order, so sid 0–4 = F1–F5
///    and sid 5–9 = M1–M5. Default F1 (sid 0) is a soft female voice.
///  - Size: 7 files, ~139 MB total — inside the ~500 MB budget, and
///    the int8 release is the sherpa-onnx project's own quantization.
///
/// Files are DOWNLOADED on first use into the app documents dir —
/// nothing is bundled in the APK, so the APK stays lite.
///
/// ENGINE STATUS: synthesis is WIRED. `synthesize()` builds the
/// sherpa-onnx Supertonic engine lazily (once), generates real audio
/// with `generateWithConfig`, writes a WAV with `writeWave`, and plays
/// it with `audioplayers`. `engineReady` is true once the model is
/// downloaded. One honest limit: generation runs on the main isolate
/// (the CLI example does the same), so a demo tap can briefly block
/// the UI while the sentence renders; sherpa-onnx's own Flutter demo
/// moves generation to a background isolate — that is the follow-up
/// if the freeze is ever noticeable.
class VoiceService {
  VoiceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final AudioPlayer _player = AudioPlayer();
  sherpa_onnx.OfflineTts? _tts;
  bool _bindingsReady = false;

  /// Pinned-commit HF mirror of the official sherpa-onnx release
  /// `sherpa-onnx-supertonic-3-tts-int8-2026-05-11.tar.bz2`
  /// (k2-fsa/sherpa-onnx, tag `tts-models`). The mirror is
  /// csukuangfj2 (sherpa-onnx author's account); every file below
  /// was verified byte-size-identical to the official tarball
  /// (all 7 files + LICENSE/README matched exactly, 2026-11-12).
  /// Canonical source if the mirror ever goes away:
  /// https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/sherpa-onnx-supertonic-3-tts-int8-2026-05-11.tar.bz2
  static const String _baseUrl =
      'https://huggingface.co/csukuangfj2/sherpa-onnx-supertonic-3-tts-int8-2026-05-11/resolve/cca5a0e6c96e1d2c720986bf7e75fcc81dee3ae4';

  /// (file name, expected bytes). Sum = 145,295,768 (~139 MB).
  static const List<(String, int)> _modelFiles = [
    ('duration_predictor.int8.onnx', 3700147),
    ('text_encoder.int8.onnx', 36416150),
    ('vector_estimator.int8.onnx', 78400833),
    ('vocoder.int8.onnx', 25991073),
    ('tts.json', 8253),
    ('unicode_indexer.bin', 262144),
    ('voice.bin', 517168),
  ];

  /// Approx total download: 145,295,768 bytes (~139 MB).
  static const int approxTotalBytes = 145295768;

  /// Voice id (F1–F5, M1–M5) → sherpa speaker id. `voice.bin`
  /// packs the styles in alphabetical filename order: sid 0–4 =
  /// F1–F5, sid 5–9 = M1–M5.
  static const Map<String, int> voiceSids = {
    'F1': 0,
    'F2': 1,
    'F3': 2,
    'F4': 3,
    'F5': 4,
    'M1': 5,
    'M2': 6,
    'M3': 7,
    'M4': 8,
    'M5': 9,
  };

  static int sidForVoice(String voice) => voiceSids[voice] ?? 0;

  /// True: synthesis is wired via sherpa_onnx + audioplayers.
  /// The Voice settings page enables "Hear demo" when this is true
  /// AND the model is downloaded.
  static const bool engineReady = true;

  Future<Directory> _modelDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/voice');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(String name) async =>
      File('${(await _modelDir()).path}/$name');

  /// True only when ALL 7 files exist and each looks complete
  /// (a partial download is never counted as downloaded).
  Future<bool> isDownloaded() async {
    for (final (name, size) in _modelFiles) {
      final f = await _file(name);
      if (!await f.exists()) return false;
      // Guard against an interrupted download: a file that made it
      // to disk is complete (rename happens only after full fetch),
      // so half the expected size is a safe completeness bar.
      if ((await f.length()) < size ~/ 2) return false;
    }
    return true;
  }

  /// Bytes already on disk (0 when nothing downloaded). Used for the
  /// "Ready (~139 MB)" / partial-download status line.
  Future<int> downloadedBytes() async {
    var total = 0;
    for (final (name, _) in _modelFiles) {
      final f = await _file(name);
      if (await f.exists()) total += await f.length();
    }
    return total;
  }

  /// Download all 7 model files. [onProgress] gets (received, total);
  /// total is the approximate 139 MB (see [approxTotalBytes]).
  /// Each file downloads to a `.part` file and is renamed only when
  /// complete, so a failed run never leaves a corrupt "downloaded" file.
  /// A file that is already fully on disk is skipped, so re-running
  /// after a failure only fetches what is missing.
  /// Throws on no-network / HTTP errors — callers show the message.
  Future<void> downloadModel({
    required void Function(int received, int total) onProgress,
  }) async {
    var received = 0;
    for (final (name, size) in _modelFiles) {
      received += await _downloadOne(
        '$_baseUrl/$name',
        name,
        size,
        onProgress,
        received,
      );
    }
    onProgress(received, approxTotalBytes);
  }

  /// Download one file (skip when already complete on disk).
  /// Returns the bytes this file contributes to the cumulative count.
  Future<int> _downloadOne(
    String url,
    String fileName,
    int expectedBytes,
    void Function(int received, int total) onProgress,
    int receivedBefore,
  ) async {
    final dir = await _modelDir();
    final target = File('${dir.path}/$fileName');
    final minOkBytes = expectedBytes ~/ 2;
    if (await target.exists() && await target.length() >= minOkBytes) {
      final len = await target.length();
      onProgress(receivedBefore + len, approxTotalBytes);
      return len;
    }
    final part = File('${target.path}.part');
    if (await part.exists()) await part.delete();
    final request = http.Request('GET', Uri.parse(url));
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw HttpException(
        'Download failed: HTTP ${response.statusCode} for $fileName',
      );
    }
    final sink = part.openWrite();
    var receivedHere = 0;
    try {
      await for (final chunk in response.stream) {
        receivedHere += chunk.length;
        sink.add(chunk);
        onProgress(receivedBefore + receivedHere, approxTotalBytes);
      }
    } finally {
      await sink.close();
    }
    await part.rename(target.path);
    return receivedHere;
  }

  /// Build the sherpa-onnx Supertonic engine once (lazy). Follows
  /// sherpa-onnx's own Dart example (`dart-api-examples/tts/bin/
  /// supertonic-en.dart`): init bindings, then
  /// OfflineTtsSupertonicModelConfig → OfflineTtsModelConfig →
  /// OfflineTtsConfig → OfflineTts.
  Future<sherpa_onnx.OfflineTts> _ensureTts() async {
    final existing = _tts;
    if (existing != null) return existing;
    if (!_bindingsReady) {
      await sherpa_onnx.initBindingsAsync();
      _bindingsReady = true;
    }
    final dir = await _modelDir();
    String p(String name) => '${dir.path}/$name';
    final supertonic = sherpa_onnx.OfflineTtsSupertonicModelConfig(
      durationPredictor: p('duration_predictor.int8.onnx'),
      textEncoder: p('text_encoder.int8.onnx'),
      vectorEstimator: p('vector_estimator.int8.onnx'),
      vocoder: p('vocoder.int8.onnx'),
      ttsJson: p('tts.json'),
      unicodeIndexer: p('unicode_indexer.bin'),
      voiceStyle: p('voice.bin'),
    );
    final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
      supertonic: supertonic,
      numThreads: 2,
      debug: false,
    );
    final config = sherpa_onnx.OfflineTtsConfig(model: modelConfig);
    final tts = sherpa_onnx.OfflineTts(config);
    _tts = tts;
    return tts;
  }

  /// Synthesize [text] to a WAV file with [voice] at [speed], then
  /// play it. [lang] is a Supertonic language code (`hi` for Hindi
  /// in Devanagari; `en` for English; `na` lets the model guess).
  /// Returns the written WAV file. Real on-device synthesis — never
  /// silence, never a placeholder.
  Future<File> synthesize({
    required String text,
    required String voice,
    required double speed,
    String lang = 'hi',
  }) async {
    if (text.trim().isEmpty) {
      throw ArgumentError('Text is empty');
    }
    if (!await isDownloaded()) {
      throw StateError('Voice model is not downloaded yet.');
    }
    final tts = await _ensureTts();
    final genConfig = sherpa_onnx.OfflineTtsGenerationConfig(
      sid: sidForVoice(voice),
      speed: speed,
      extra: {'lang': lang, 'num_steps': 8},
    );
    // Blocking FFI call on the main isolate (same as sherpa-onnx's
    // own Dart CLI example); a short demo sentence renders in ~1–2 s.
    final audio = tts.generateWithConfig(
      text: text,
      config: genConfig,
      onProgress: (samples, progress) {
        return 1;
      },
    );
    final wav = await _file('demo.wav');
    sherpa_onnx.writeWave(
      filename: wav.path,
      samples: audio.samples,
      sampleRate: audio.sampleRate,
    );
    await _player.stop();
    await _player.play(DeviceFileSource(wav.path));
    return wav;
  }

  /// Stop demo playback (if any).
  Future<void> stopPlayback() => _player.stop();

  /// Delete the downloaded model files (and any `.part` left by an
  /// interrupted download, plus the demo WAV). Frees ~139 MB.
  /// The in-memory engine is freed too, so a re-download starts clean.
  Future<void> deleteModel() async {
    _tts?.free();
    _tts = null;
    for (final (name, _) in _modelFiles) {
      final f = await _file(name);
      if (await f.exists()) await f.delete();
      final part = File('${f.path}.part');
      if (await part.exists()) await part.delete();
    }
    final demo = await _file('demo.wav');
    if (await demo.exists()) await demo.delete();
  }

  void dispose() {
    _tts?.free();
    _tts = null;
    unawaited(_player.dispose());
    _client.close();
  }
}
