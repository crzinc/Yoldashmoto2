import 'package:image_picker/image_picker.dart';
import 'backend.dart';

/// Photo picker + Supabase Storage upload (avatars, sos-photos, listings, docs).
/// Returns public URLs (empty in demo mode).
Future<List<String>> pickAndUpload(String bucket, {int max = 3}) async {
  final picker = ImagePicker();
  final files = await picker.pickMultiImage();
  final out = <String>[];
  for (final f in files.take(max)) {
    final bytes = await f.readAsBytes();
    final url = await Backend.uploadPhoto(bucket, '${nid()}_${f.name}', bytes);
    if (url != null) out.add(url);
  }
  return out;
}
