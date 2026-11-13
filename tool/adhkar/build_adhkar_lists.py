"""Writes lib/features/habits/domain/adhkar_lists.dart: Ahmed's morning and
night du'a lists.

Where the text comes from: the Instagram post Ahmed picked on 2026-11-13
(instagram.com/p/DQULTezDYgG, "أذكار الصباح والمساء", 15 pictures, 27 Oct
2025) is pictures, so the du'a text is Hisn al-Muslim's typed text
(hisnmuslim.com/api/ar/27.json, chapter 27), cut by this script in the post's
order, splits and counts. No du'a text is typed by hand here, except two
things taken from the post itself: the vowels of one word in #85 (picture 10:
waw, sheen+kasra, reh, kaf+kasra, heh+kasra) and the heading of picture 14
("الإستغفار", 100 times, no wording given). The evening wording is the book's
own evening notes, which it prints without vowel marks.

Run from the repo root:  python -X utf8 tool/adhkar/build_adhkar_lists.py
It prints the fingerprint that test/features/habits/domain/adhkar_lists_test.dart
expects. Change the lists only with Ahmed's word, then update that test.
"""
import json
import pathlib
import re
import unicodedata
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / 'lib' / 'features' / 'habits' / 'domain' / 'adhkar_lists.dart'
URL = 'https://www.hisnmuslim.com/api/ar/27.json'
OPEN, CLOSE = '﴿', '﴾'   # ﴿ ﴾ as Arabic texts use them

req = urllib.request.Request(URL, headers={'User-Agent': 'Mozilla/5.0'})
src = json.loads(urllib.request.urlopen(req).read().decode('utf-8-sig'))
items = {it['ID']: it for it in list(src.values())[0]}


def clean(t):
    t = t.replace('((', '').replace('))', '')
    t = re.sub(r'\[[^\]]*\]', '', t)        # the book's evening notes
    t = re.sub(r'\([^()]*\)', '', t)        # "(ثلاث مرات)" and the like
    t = re.sub(r'\s+،', '،', t)
    t = re.sub(r'\s{2,}', ' ', t)
    return t.strip().rstrip('.').strip().rstrip('،').strip()


def notes(it):
    """The book's evening notes '[وإذا أمسى قال: ...]', as written."""
    found = re.findall(r'\[\s*وإذا أمسى قال:\s*([^\]]*)\]', it['ARABIC_TEXT'])
    return [n.strip().rstrip('.').strip() for n in found]


def bare(w):
    return ''.join(c for c in w if unicodedata.category(c) != 'Mn')


def verses(body):
    digits = '٠١٢٣٤٥٦٧٨٩'
    def num(n):
        return ''.join(digits[int(c)] for c in str(n))
    parts = [p.strip() for p in body.split('*')]
    return ' '.join(f'{p} {OPEN}{num(i + 1)}{CLOSE}' for i, p in enumerate(parts))


def T(i):
    return clean(items[i]['ARABIC_TEXT'])


# Ayat al-Kursi (#75): "أعوذ بالله…" on its own line, then the verse, numbered.
m = re.match(r'(.*?)\s*[﴾﴿](.*)[﴾﴿]$', T(75))
kursi = f'{m.group(1)}\n{m.group(2)} {OPEN}٢٥٥{CLOSE}'

# The three Quls (#76): one card each, as in the post.
quls = []
for chunk in T(76).split('بسم الله الرحمن الرحيم'):
    if not chunk.strip():
        continue
    body = re.search(r'[﴾﴿](.*)[﴾﴿]', chunk).group(1)
    quls.append('بسم الله الرحمن الرحيم\n' + verses(body))
assert len(quls) == 3, len(quls)

# #77: the morning text; the evening one swaps in the book's two notes.
seg = T(77).split('، ')
assert len(seg) == 8, len(seg)
n77 = notes(items[77])
assert len(n77) == 2
m77 = '، '.join(seg)
e77 = '، '.join([n77[0]] + seg[1:4] + [n77[1]] + seg[6:8])

# #78: the evening text is the book's note, whole.
m78 = T(78)
e78 = notes(items[78])[0]

# #80 and #90: the evening changes one word (أمسيت / أمسينا, per the notes).
w80 = T(80).split(' ')
assert bare(w80[2]) == 'أصبحت', w80[2]
m80, e80 = ' '.join(w80), ' '.join(w80[:2] + ['أمسيت'] + w80[3:])
w90 = T(90).split(' ')
assert bare(w90[0]) == 'أصبحنا', w90[0]
m90, e90 = ' '.join(w90), ' '.join(['أمسينا'] + w90[1:])

# #82 in two cards, as the post does (each 3 times).
a82, c82 = T(82).split('. ', 1)

# #85 with the post's vowels on one word.
w85 = T(85).split(' ')
hits = [i for i, w in enumerate(w85) if bare(w).rstrip('،') == 'وشركه']
assert len(hits) == 1, hits
tail = '،' if w85[hits[0]].endswith('،') else ''
w85[hits[0]] = 'وشِركِهِ' + tail
t85 = ' '.join(w85)

D = {
    'kursi': ('آية الكرسي', kursi, 1),
    'ikhlas': ('سورة الإخلاص', quls[0], 3),
    'falaq': ('سورة الفلق', quls[1], 3),
    'nas': ('سورة الناس', quls[2], 3),
    'mulk_m': ('أصبحنا وأصبح الملك لله', m77, 1),
    'mulk_e': ('أمسينا وأمسى الملك لله', e77, 1),
    'fitra_m': ('أصبحنا على فطرة الإسلام', m90, 1),
    'fitra_e': ('أمسينا على فطرة الإسلام', e90, 1),
    'ushhid_m': ('اللهم إني أصبحت أشهدك', m80, 4),
    'ushhid_e': ('اللهم إني أمسيت أشهدك', e80, 4),
    'bika_m': ('اللهم بك أصبحنا', m78, 1),
    'bika_e': ('اللهم بك أمسينا', e78, 1),
    'kalimat': ('أعوذ بكلمات الله التامات', T(97), 3),
    'sayyid': ('سيد الاستغفار', T(79), 1),
    'afw': ('العفو والعافية', T(84), 1),
    'hayy': ('يا حي يا قيوم', T(88), 1),
    'alim': ('عالم الغيب والشهادة', t85, 1),
    'afini': ('اللهم عافني في بدني', a82, 3),
    'kufr': ('أعوذ بك من الكفر والفقر', c82, 3),
    'radeet': ('رضيت بالله رباً', T(87), 3),
    'bismillah': ('بسم الله الذي لا يضر', T(86), 3),
    'subhan100': ('سبحان الله وبحمده', T(91), 100),
    'adada': ('سبحان الله وبحمده عدد خلقه', T(94), 3),
    'ilman': ('علماً نافعاً', T(95), 1),
    'istighfar': ('الإستغفار', 'الإستغفار', 100),
    'tahlil100': ('لا إله إلا الله وحده', T(93), 100),
}

MORNING = ['kursi', 'ikhlas', 'falaq', 'nas', 'mulk_m', 'fitra_m', 'ushhid_m',
           'bika_m', 'sayyid', 'afw', 'hayy', 'alim', 'afini', 'kufr', 'radeet',
           'bismillah', 'subhan100', 'adada', 'ilman', 'istighfar', 'tahlil100']
NIGHT = ['kursi', 'ikhlas', 'falaq', 'nas', 'mulk_e', 'fitra_e', 'ushhid_e',
         'bika_e', 'kalimat', 'sayyid', 'afw', 'hayy', 'alim', 'afini', 'kufr',
         'radeet', 'bismillah', 'subhan100', 'tahlil100']


def dart_str(s):
    s = s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
    return "'" + s.replace('\n', '\\n') + "'"


def var(key):
    head, *rest = key.split('_')
    return '_' + head + ''.join(p[:1].upper() + p[1:] for p in rest)


def fingerprint():
    rows = []
    for name, keys in (('morning', MORNING), ('night', NIGHT)):
        for k in keys:
            title, text, times = D[k]
            rows.append(f'{name}|{k}|{title}|{times}|{text}\n')
    h = 0x811c9dc5
    for byte in ''.join(rows).encode('utf-8'):
        h = ((h ^ byte) * 0x01000193) & 0xFFFFFFFF
    return f'{h:08x}'


def taps(keys):
    return sum(D[k][2] for k in keys)


lines = [
    '// GENERATED by tool/adhkar/build_adhkar_lists.py. Do not edit by hand.',
    "// The du'a text is Hisn al-Muslim's typed text (hisnmuslim.com, chapter",
    "// 27), cut in the order, splits and counts of the Instagram post Ahmed",
    '// picked on 2026-11-13 (instagram.com/p/DQULTezDYgG). Its fingerprint is',
    '// pinned in test/features/habits/domain/adhkar_lists_test.dart: change',
    '// the lists only with his word, by re-running the script.',
    '',
    "import 'dhikr.dart';",
    '',
]
for k in dict.fromkeys(MORNING + NIGHT):
    title, text, times = D[k]
    lines += [
        f'const Dhikr {var(k)} = Dhikr(',
        f"  id: '{k}',",
        f'  title: {dart_str(title)},',
        f'  times: {times},',
        f'  text: {dart_str(text)},',
        ');',
        '',
    ]
lines += [
    f"/// Morning (أذكار الصباح): {len(MORNING)} du'as, {taps(MORNING)} taps in all.",
    'const List<Dhikr> kMorningAdhkar = [',
    *[f'  {var(k)},' for k in MORNING],
    '];',
    '',
    f"/// Night, the post's evening list (أذكار المساء): {len(NIGHT)} du'as, {taps(NIGHT)} taps in all.",
    'const List<Dhikr> kNightAdhkar = [',
    *[f'  {var(k)},' for k in NIGHT],
    '];',
    '',
]
OUT.write_text('\n'.join(lines), encoding='utf-8', newline='\n')
print(f'wrote {OUT.relative_to(ROOT)}')
print(f"morning {len(MORNING)} du'as, {taps(MORNING)} taps; night {len(NIGHT)} du'as, {taps(NIGHT)} taps")
print('fingerprint', fingerprint())
