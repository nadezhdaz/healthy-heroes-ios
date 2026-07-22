# Core Data migration policy

This policy applies to the release SQLite store at `Application Support/HealthyHeroes/HealthyHeroes.sqlite`.

## Version rules

1. `HealthyHeroesV1.xcdatamodel` is immutable after its first public release.
2. Every schema change creates a new model version inside `HealthyHeroes.xcdatamodeld`; never edit a released model in place.
3. Additive optional attributes and compatible defaults may use inferred lightweight migration.
4. Renames must use stable renaming identifiers.
5. Type changes, entity splits/merges, semantic rewrites, or relationship reconstruction require an explicit staged migration and mapping code.
6. A migration failure must be surfaced and logged without profile contents. The app must never delete or recreate the store automatically.

## Fixture retention

When `HealthyHeroesV2` is introduced, capture a real anonymized V1 SQLite fixture before shipping V2:

```text
HealthyHeroesTests/Fixtures/CoreData/
└── HealthyHeroesV1/
    ├── HealthyHeroes.sqlite
    ├── HealthyHeroes.sqlite-shm   # include when present
    └── HealthyHeroes.sqlite-wal   # include when present
```

When V3 is introduced, retain both V1 and V2 fixtures. From that point every release must test migration from N−1 and N−2.

Fixtures must contain deterministic synthetic values covering:

- a selected character and appearance;
- non-zero XP and map position;
- active, completed, and rewarded quest states;
- opened and unopened rewards;
- unlocked and equipped wardrobe items;
- multiple Food Log entries including a named custom entry.

## Required migration test

For each retained fixture:

1. Copy the SQLite file and sidecars into a fresh temporary directory.
2. Open the copy with the current `NSPersistentContainer` configuration.
3. Assert that the store migrated without deleting or replacing the original data.
4. Load through `CoreDataGameRepository`, not raw `NSManagedObject` access.
5. Verify profile ID, XP, map position, quest status, reward/open state, wardrobe state, and Food Log IDs/titles.
6. Execute one atomic Food Log transaction after migration and reopen the store to verify persistence.
7. Keep the source fixture unchanged so the test remains repeatable.

## Current baseline

The project currently has only `HealthyHeroesV1`, so a genuine SQLite N−1/N−2 migration cannot yet be exercised. The test suite instead verifies the V1 model constraints and covers import from both legacy JSON formats. The first real SQLite migration fixture must be added in the same change that creates `HealthyHeroesV2`.
