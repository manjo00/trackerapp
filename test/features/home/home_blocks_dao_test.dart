import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/home/data/home_block_config.dart';
import 'package:life_tracker/features/home/data/home_block_type.dart';
import 'package:life_tracker/features/home/data/home_blocks_dao.dart';

void main() {
  late AppDatabase db;
  late HomeBlocksDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = HomeBlocksDao(db);
  });
  tearDown(() async => db.close());

  test('ensureSeeded fills an empty table from the legacy layout, once', () async {
    await dao.ensureSeeded(HomeBlockType.defaults);
    final first = await dao.getBlocks();
    expect(first.map((b) => b.type),
        HomeBlockType.defaults.map((t) => t.name).toList());

    // Second call is a no-op — user edits are never overwritten.
    await dao.deleteBlock(first.first.id);
    await dao.ensureSeeded(HomeBlockType.defaults);
    final second = await dao.getBlocks();
    expect(second.length, first.length - 1);
  });

  test('addBlock appends at the end and keeps its config', () async {
    await dao.ensureSeeded(const [HomeBlockType.urgent]);
    final int id = await dao.addBlock(HomeBlockType.pinnedNote,
        configJson: pinnedNoteConfig(7));

    final blocks = await dao.getBlocks();
    expect(blocks.last.id, id);
    expect(blocks.last.type, 'pinnedNote');
    expect(pinnedNoteIdFromConfig(blocks.last.configJson), 7);
  });

  test('reorderBlocks rewrites the dashboard order', () async {
    await dao.ensureSeeded(
        const [HomeBlockType.urgent, HomeBlockType.dueToday, HomeBlockType.notes]);
    final blocks = await dao.getBlocks();
    final ids = blocks.map((b) => b.id).toList();

    await dao.reorderBlocks([ids[2], ids[0], ids[1]]);
    final after = await dao.getBlocks();
    expect(after.map((b) => b.id), [ids[2], ids[0], ids[1]]);
  });

  test('updateConfig repoints a pinned block at another note', () async {
    final int id = await dao.addBlock(HomeBlockType.pinnedNote,
        configJson: pinnedNoteConfig(1));
    await dao.updateConfig(id, pinnedNoteConfig(9));
    final blocks = await dao.getBlocks();
    expect(pinnedNoteIdFromConfig(blocks.single.configJson), 9);
  });

  test('config parsing shrugs off malformed data', () {
    expect(pinnedNoteIdFromConfig(null), isNull);
    expect(pinnedNoteIdFromConfig(''), isNull);
    expect(pinnedNoteIdFromConfig('not json'), isNull);
    expect(pinnedNoteIdFromConfig('[1,2]'), isNull);
    expect(pinnedNoteIdFromConfig('{"noteId":"five"}'), isNull);
    expect(pinnedNoteIdFromConfig(pinnedNoteConfig(42)), 42);
  });
}
