/// Lookup tables of the EWTS ↔ Tibetan Unicode converter.
///
/// Transcribed from pyewts (github.com/Webuddhist-tech/pyewts), the Python
/// port of BDRC's ewts-converter. Apache License 2.0.
/// Copyright (C) 2010 Roger Espel Llima; (c) 2011–2017 Buddhist Digital
/// Resource Center.
class EwtsTables {
  EwtsTables._();

  /// Wylie consonant → Unicode (top letter).
  static const Map<String, String> consonant = {
    'k': 'ཀ',
    'kh': 'ཁ',
    'g': 'ག',
    'gh': 'གྷ',
    'g+h': 'གྷ',
    'ng': 'ང',
    'c': 'ཅ',
    'ch': 'ཆ',
    'j': 'ཇ',
    'ny': 'ཉ',
    'T': 'ཊ',
    '-t': 'ཊ',
    'Th': 'ཋ',
    '-th': 'ཋ',
    'D': 'ཌ',
    '-d': 'ཌ',
    'Dh': 'ཌྷ',
    'D+h': 'ཌྷ',
    '-dh': 'ཌྷ',
    '-d+h': 'ཌྷ',
    'N': 'ཎ',
    '-n': 'ཎ',
    't': 'ཏ',
    'th': 'ཐ',
    'd': 'ད',
    'dh': 'དྷ',
    'd+h': 'དྷ',
    'n': 'ན',
    'p': 'པ',
    'ph': 'ཕ',
    'b': 'བ',
    'bh': 'བྷ',
    'b+h': 'བྷ',
    'm': 'མ',
    'ts': 'ཙ',
    'tsh': 'ཚ',
    'dz': 'ཛ',
    'dzh': 'ཛྷ',
    'dz+h': 'ཛྷ',
    'w': 'ཝ',
    'zh': 'ཞ',
    'z': 'ཟ',
    "'": 'འ',
    'y': 'ཡ',
    'r': 'ར',
    'l': 'ལ',
    'sh': 'ཤ',
    'Sh': 'ཥ',
    '-sh': 'ཥ',
    's': 'ས',
    'h': 'ཧ',
    'W': 'ཝ',
    'Y': 'ཡ',
    'R': 'ཪ',
    'f': 'ཕ༹',
    'v': 'བ༹',
  };

  /// Wylie consonant → Unicode (subjoined letter).
  static const Map<String, String> subjoined = {
    'k': 'ྐ',
    'kh': 'ྑ',
    'g': 'ྒ',
    'gh': 'ྒྷ',
    'g+h': 'ྒྷ',
    'ng': 'ྔ',
    'c': 'ྕ',
    'ch': 'ྖ',
    'j': 'ྗ',
    'ny': 'ྙ',
    'T': 'ྚ',
    '-t': 'ྚ',
    'Th': 'ྛ',
    '-th': 'ྛ',
    'D': 'ྜ',
    '-d': 'ྜ',
    'Dh': 'ྜྷ',
    'D+h': 'ྜྷ',
    '-dh': 'ྜྷ',
    '-d+h': 'ྜྷ',
    'N': 'ྞ',
    '-n': 'ྞ',
    't': 'ྟ',
    'th': 'ྠ',
    'd': 'ྡ',
    'dh': 'ྡྷ',
    'd+h': 'ྡྷ',
    'n': 'ྣ',
    'p': 'ྤ',
    'ph': 'ྥ',
    'b': 'ྦ',
    'bh': 'ྦྷ',
    'b+h': 'ྦྷ',
    'm': 'ྨ',
    'ts': 'ྩ',
    'tsh': 'ྪ',
    'dz': 'ྫ',
    'dzh': 'ྫྷ',
    'dz+h': 'ྫྷ',
    'w': 'ྭ',
    'zh': 'ྮ',
    'z': 'ྯ',
    "'": 'ྰ',
    'y': 'ྱ',
    'r': 'ྲ',
    'l': 'ླ',
    'sh': 'ྴ',
    'Sh': 'ྵ',
    '-sh': 'ྵ',
    's': 'ྶ',
    'h': 'ྷ',
    'a': 'ྸ',
    'W': 'ྺ',
    'Y': 'ྻ',
    'R': 'ྼ',
  };

  /// Wylie vowel → Unicode. "a" is the a-chen top letter.
  static const Map<String, String> vowel = {
    'a': 'ཨ',
    'A': 'ཱ',
    'i': 'ི',
    'I': 'ཱི',
    'u': 'ུ',
    'U': 'ཱུ',
    'e': 'ེ',
    'ai': 'ཻ',
    'o': 'ོ',
    'au': 'ཽ',
    '-i': 'ྀ',
    '-I': 'ཱྀ',
  };

  /// Wylie final sign → Unicode.
  static const Map<String, String> finalUni = {
    'M': 'ཾ',
    '~M`': 'ྂ',
    '~M': 'ྃ',
    'X': '༷',
    '~X': '༵',
    'H': 'ཿ',
    '?': '྄',
    '^': '༹',
    '&': '྅',
  };

  /// Wylie final sign → its class (finals of one class cannot combine).
  static const Map<String, String> finalClass = {
    'M': 'M',
    '~M`': 'M',
    '~M': 'M',
    'X': 'X',
    '~X': 'X',
    'H': 'H',
    '?': '?',
    '^': '^',
    '&': '&',
  };

  /// Wylie stand-alone symbols → Unicode.
  static const Map<String, String> other = {
    '0': '༠',
    '1': '༡',
    '2': '༢',
    '3': '༣',
    '4': '༤',
    '5': '༥',
    '6': '༦',
    '7': '༧',
    '8': '༨',
    '9': '༩',
    ' ': '་',
    '*': '༌',
    '/': '།',
    '//': '༎',
    ';': '༏',
    '|': '༑',
    '!': '༈',
    ':': '༔',
    '_': ' ',
    '=': '༴',
    '<': '༺',
    '>': '༻',
    '(': '༼',
    ')': '༽',
    '@': '༄',
    '#': '༅',
    r'$': '༆',
    '%': '༇',
  };

  /// Characters flagged when they occur out of context.
  static const Set<String> special = {'.', '+', '-', '~', '^', '?', '`', ']'};

  /// Superscript → letters or stacks it may sit above.
  static const Map<String, Set<String>> superscripts = {
    'r': {
      'k', 'g', 'ng', 'j', 'ny', 't', 'd', 'n', 'b', 'm', 'ts', 'dz',
      'k+y', 'g+y', 'm+y', 'b+w', 'ts+w', 'g+w',
    },
    'l': {'k', 'g', 'ng', 'c', 'j', 't', 'd', 'p', 'b', 'h'},
    's': {
      'k', 'g', 'ng', 'ny', 't', 'd', 'n', 'p', 'b', 'm', 'ts',
      'k+y', 'g+y', 'p+y', 'b+y', 'm+y', 'k+r', 'g+r', 'p+r', 'b+r', 'm+r',
      'n+r',
    },
    'y': {
      'k', 'kh', 'g', 'p', 'ph', 'b', 'm',
      'r+k', 'r+g', 'r+m', 's+k', 's+g', 's+p', 's+b', 's+m',
    },
  };

  /// Subscript → letters or stacks it may sit below.
  static const Map<String, Set<String>> subscripts = {
    'y': {
      'k', 'kh', 'g', 'p', 'ph', 'b', 'm',
      'r+k', 'r+g', 'r+m', 's+k', 's+g', 's+p', 's+b', 's+m',
    },
    'r': {
      'k', 'kh', 'g', 't', 'th', 'd', 'n', 'p', 'ph', 'b', 'm', 'sh', 's',
      'h', 'dz', 's+k', 's+g', 's+p', 's+b', 's+m', 's+n',
    },
    'l': {'k', 'g', 'b', 'r', 's', 'z'},
    'w': {
      'k', 'kh', 'g', 'c', 'ny', 't', 'd', 'ts', 'tsh', 'zh', 'z', 'r', 'l',
      'sh', 's', 'h', 'g+r', 'd+r', 'ph+y', 'r+g', 'r+ts',
    },
  };

  /// Prefix → roots (letters or stacks) it may precede.
  static const Map<String, Set<String>> prefixes = {
    'g': {'c', 'ny', 't', 'd', 'n', 'ts', 'zh', 'z', 'y', 'sh', 's'},
    'd': {
      'k', 'g', 'ng', 'p', 'b', 'm',
      'k+y', 'g+y', 'p+y', 'b+y', 'm+y', 'k+r', 'g+r', 'p+r', 'b+r',
    },
    'b': {
      'k', 'g', 'c', 't', 'd', 'ts', 'zh', 'z', 'sh', 's', 'r', 'l',
      'k+y', 'g+y', 'k+r', 'g+r', 'r+l', 's+l', 'r+k', 'r+g', 'r+ng', 'r+j',
      'r+ny', 'r+t', 'r+d', 'r+n', 'r+ts', 'r+dz', 's+k', 's+g', 's+ng',
      's+ny', 's+t', 's+d', 's+n', 's+ts', 'r+k+y', 'r+g+y', 's+k+y', 's+g+y',
      's+k+r', 's+g+r', 'l+d', 'l+t', 'k+l', 's+r', 'z+l', 's+w',
    },
    'm': {
      'kh', 'g', 'ng', 'ch', 'j', 'ny', 'th', 'd', 'n', 'tsh', 'dz',
      'kh+y', 'g+y', 'kh+r', 'g+r',
    },
    "'": {
      'kh', 'g', 'ch', 'j', 'th', 'd', 'ph', 'b', 'tsh', 'dz',
      'kh+y', 'g+y', 'ph+y', 'b+y', 'kh+r', 'g+r', 'd+r', 'ph+r', 'b+r',
    },
  };

  /// Suffix letters; a few Sanskrit letters are included because they often
  /// occur in suffix position in Sanskrit words.
  static const Set<String> suffixes = {
    "'", 'g', 'ng', 'd', 'n', 'b', 'm', 'r', 'l', 's', 'N', 'T', '-n', '-t',
  };

  /// Second suffix → suffixes it may follow.
  static const Map<String, Set<String>> suff2 = {
    's': {'g', 'ng', 'b', 'm'},
    'd': {'n', 'r', 'l'},
  };

  /// Letters allowed as a second suffix after the affix a-chung ('am, 'ang).
  static const Set<String> affixedSuff2 = {'ng', 'm'};

  /// Root letter index for very ambiguous three-stack syllables.
  static const Map<String, int> ambiguousKey = {
    'dgs': 1,
    'dms': 1,
    'dngs': 0,
    "'gs": 1,
    "'bs": 1,
    'mngs': 0,
    'mgs': 0,
    'bgs': 0,
    'dbs': 1,
  };

  static const Map<String, String> ambiguousWylie = {
    'dgs': 'dgas',
    'dngs': 'dangs',
    'dms': 'dmas',
    "'gs": "'gas",
    "'bs": "'bas",
    'mngs': 'mangs',
    'mgs': 'mags',
    'bgs': 'bags',
    'dbs': 'dbas',
  };

  // *** Unicode → Wylie ***

  /// Top letters.
  static const Map<String, String> tibTop = {
    'ཀ': 'k',
    'ཁ': 'kh',
    'ག': 'g',
    'གྷ': 'g+h',
    'ང': 'ng',
    'ཅ': 'c',
    'ཆ': 'ch',
    'ཇ': 'j',
    'ཉ': 'ny',
    'ཊ': 'T',
    'ཋ': 'Th',
    'ཌ': 'D',
    'ཌྷ': 'D+h',
    'ཎ': 'N',
    'ཏ': 't',
    'ཐ': 'th',
    'ད': 'd',
    'དྷ': 'd+h',
    'ན': 'n',
    'པ': 'p',
    'ཕ': 'ph',
    'བ': 'b',
    'བྷ': 'b+h',
    'མ': 'm',
    'ཙ': 'ts',
    'ཚ': 'tsh',
    'ཛ': 'dz',
    'ཛྷ': 'dz+h',
    'ཝ': 'w',
    'ཞ': 'zh',
    'ཟ': 'z',
    'འ': "'",
    'ཡ': 'y',
    'ར': 'r',
    'ལ': 'l',
    'ཤ': 'sh',
    'ཥ': 'Sh',
    'ས': 's',
    'ཧ': 'h',
    'ཨ': 'a',
    'ཀྵ': 'k+Sh',
    'ཪ': 'R',
  };

  /// Subjoined letters.
  static const Map<String, String> tibSubjoined = {
    'ྐ': 'k',
    'ྑ': 'kh',
    'ྒ': 'g',
    'ྒྷ': 'g+h',
    'ྔ': 'ng',
    'ྕ': 'c',
    'ྖ': 'ch',
    'ྗ': 'j',
    'ྙ': 'ny',
    'ྚ': 'T',
    'ྛ': 'Th',
    'ྜ': 'D',
    'ྜྷ': 'D+h',
    'ྞ': 'N',
    'ྟ': 't',
    'ྠ': 'th',
    'ྡ': 'd',
    'ྡྷ': 'd+h',
    'ྣ': 'n',
    'ྤ': 'p',
    'ྥ': 'ph',
    'ྦ': 'b',
    'ྦྷ': 'b+h',
    'ྨ': 'm',
    'ྩ': 'ts',
    'ྪ': 'tsh',
    'ྫ': 'dz',
    'ྫྷ': 'dz+h',
    'ྭ': 'w',
    'ྮ': 'zh',
    'ྯ': 'z',
    'ྰ': "'",
    'ྱ': 'y',
    'ྲ': 'r',
    'ླ': 'l',
    'ྴ': 'sh',
    'ྵ': 'Sh',
    'ྶ': 's',
    'ྷ': 'h',
    'ྸ': 'a',
    'ྐྵ': 'k+Sh',
    'ྺ': 'W',
    'ྻ': 'Y',
    'ྼ': 'R',
  };

  /// Vowel signs. A-chen is a top letter, not a vowel sign; the pre-composed
  /// Sanskrit vowels other than I/U are expanded by `toWylie` first.
  static const Map<String, String> tibVowel = {
    'ཱ': 'A',
    'ི': 'i',
    'ཱི': 'I',
    'ུ': 'u',
    'ཱུ': 'U',
    'ེ': 'e',
    'ཻ': 'ai',
    'ོ': 'o',
    'ཽ': 'au',
    'ྀ': '-i',
  };

  /// Long (Sanskrit) vowels: what a vowel becomes after the a-chung mark.
  static const Map<String, String> tibVowelLong = {
    'i': 'I',
    'u': 'U',
    '-i': '-I',
  };

  /// Final signs → Wylie.
  static const Map<String, String> tibFinalWylie = {
    'ཾ': 'M',
    'ྂ': '~M`',
    'ྃ': '~M',
    '༷': 'X',
    '༵': '~X',
    '༹': '^',
    'ཿ': 'H',
    '྄': '?',
    '྅': '&',
  };

  /// Final signs → class.
  static const Map<String, String> tibFinalClass = {
    'ཾ': 'M',
    'ྂ': 'M',
    'ྃ': 'M',
    '༷': 'X',
    '༵': 'X',
    '༹': '^',
    'ཿ': 'H',
    '྄': '?',
    '྅': '&',
  };

  /// Letters changed by a following caret (tsa-phru).
  static const Map<String, String> tibCaret = {'ph': 'f', 'b': 'v'};

  /// Other stand-alone characters → Wylie.
  static const Map<String, String> tibOther = {
    ' ': '_',
    '༄': '@',
    '༅': '#',
    '༆': r'$',
    '༇': '%',
    '༈': '!',
    '་': ' ',
    '༌': '*',
    '།': '/',
    '༎': '//',
    '༏': ';',
    '༑': '|',
    '༔': ':',
    '༠': '0',
    '༡': '1',
    '༢': '2',
    '༣': '3',
    '༤': '4',
    '༥': '5',
    '༦': '6',
    '༧': '7',
    '༨': '8',
    '༩': '9',
    '༴': '=',
    '༺': '<',
    '༻': '>',
    '༼': '(',
    '༽': ')',
  };

  /// Stacked consonants written without "+" between them.
  static const Set<String> tibStacks = {
    'b+l', 'b+r', 'b+y', 'c+w', 'd+r', 'd+r+w', 'd+w', 'dz+r', 'g+l', 'g+r',
    'g+r+w', 'g+w', 'g+y', 'h+r', 'h+w', 'k+l', 'k+r', 'k+w', 'k+y', 'kh+r',
    'kh+w', 'kh+y', 'l+b', 'l+c', 'l+d', 'l+g', 'l+h', 'l+j', 'l+k', 'l+ng',
    'l+p', 'l+t', 'l+w', 'm+r', 'm+y', 'n+r', 'ny+w', 'p+r', 'p+y', 'ph+r',
    'ph+y', 'ph+y+w', 'r+b', 'r+d', 'r+dz', 'r+g', 'r+g+w', 'r+g+y', 'r+j',
    'r+k', 'r+k+y', 'r+l', 'r+m', 'r+m+y', 'r+n', 'r+ng', 'r+ny', 'r+t',
    'r+ts', 'r+ts+w', 'r+w', 's+b', 's+b+r', 's+b+y', 's+d', 's+g', 's+g+r',
    's+g+y', 's+k', 's+k+r', 's+k+y', 's+l', 's+m', 's+m+r', 's+m+y', 's+n',
    's+n+r', 's+ng', 's+ny', 's+p', 's+p+r', 's+p+y', 's+r', 's+t', 's+ts',
    's+w', 'sh+r', 'sh+w', 't+r', 't+w', 'th+r', 'ts+w', 'tsh+w', 'z+l', 'z+w',
    'zh+w',
  };

  /// Tokenizer: letters that start multi-character tokens → the longest
  /// token length starting with that letter.
  static const Map<String, int> tokensStart = {
    'S': 2,
    '/': 2,
    'd': 4,
    'g': 3,
    'b': 3,
    'D': 3,
    'z': 2,
    '~': 3,
    '-': 4,
    'T': 2,
    'a': 2,
    'k': 2,
    't': 3,
    's': 2,
    'c': 2,
    'n': 2,
    'p': 2,
    '\r': 2,
  };

  /// Tokens longer than one character.
  static const Set<String> tokens = {
    '-d+h', 'dz+h', '-dh', '-sh', '-th', 'D+h', 'b+h', 'd+h', 'dzh', 'g+h',
    'tsh', '~M`', '-I', '-d', '-i', '-n', '-t', '//', 'Dh', 'Sh', 'Th', 'ai',
    'au', 'bh', 'ch', 'dh', 'dz', 'gh', 'kh', 'ng', 'ny', 'ph', 'sh', 'th',
    'ts', 'zh', '~M', '~X', '\r\n',
  };
}
