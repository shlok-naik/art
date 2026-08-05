/// A best-effort client-side courtesy filter — not a security boundary,
/// since anything calling Supabase directly could bypass it. It only nudges
/// the poster before submission; real enforcement is the report flow plus
/// owner/self delete on the comments table.
const _blockedWords = [
  'fuck',
  'shit',
  'bitch',
  'asshole',
  'bastard',
  'cunt',
  'dick',
  'piss',
  'slut',
  'whore',
];

bool containsProfanity(String text) {
  final lower = text.toLowerCase();
  return _blockedWords.any((word) => lower.contains(word));
}
