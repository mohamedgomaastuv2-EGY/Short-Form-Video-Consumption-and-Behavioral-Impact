import pandas as pd
import pyodbc

# ── 1. Config — UPDATE THESE ─────────────────────────────────
CSV_PATH = r'D:\YF\DATA ANALYST CORE\DEPI TECH TRACK\Final Project\Final Project\Dataset\DWH\Bronze Layer\survey_row_data - Copy.csv'
SERVER   = '.'    # e.g. DESKTOP-ABC123 or localhost
DATABASE = 'Reels_Pulse_Warehouse'  # e.g. ReelsProject

# ── 2. Read CSV ──────────────────────────────────────────────
print("Reading CSV...")
df = pd.read_csv(CSV_PATH, encoding='utf-8-sig', dtype=str)

# Force ALL null-like values to Python None (fixes the float NaN bug)
df = df.astype(object).where(pd.notnull(df), other=None)
for col in df.columns:
    df[col] = df[col].apply(lambda x: None if (x is None or (isinstance(x, float))) else str(x).strip() or None)

print(f"Loaded {len(df):,} rows x {len(df.columns)} columns")
print("Null counts:", {c: df[c].isna().sum() for c in df.columns if df[c].isna().sum() > 0})

# ── 3. Connect ───────────────────────────────────────────────
print("\nConnecting to SQL Server...")
conn = pyodbc.connect(
    f'DRIVER={{ODBC Driver 17 for SQL Server}};'
    f'SERVER={SERVER};'
    f'DATABASE={DATABASE};'
    f'Trusted_Connection=yes;'
    # For SQL Auth instead of Windows Auth, comment line above and use:
    # f'UID=your_username;PWD=your_password;'
)
conn.autocommit = False
cursor = conn.cursor()
print("Connected!")

# ── 4. Insert ────────────────────────────────────────────────
COLUMNS = [
    'timestamp', 'age_group', 'gender', 'region', 'marital_status',
    'occupation', 'education_level', 'primary_platform', 'daily_watch_hours',
    'content_type', 'peak_usage_time', 'daily_opens', 'voice_msg_behavior',
    'usage_duration_since', 'content_relevance', 'difficulty_closing_app',
    'productivity_impact', 'sleep_impact', 'feeling_after_closing',
    'watching_companion', 'behavior_while_watching', 'phone_during_family',
    'family_opinion', 'reason_for_watching', 'social_media_without_reels',
    'purchased_from_video', 'purchase_reason', 'purchase_influence_level',
    'rewatched_before_purchase'
]

INSERT_SQL = """
INSERT INTO bronze.reels_survey (
    [timestamp], age_group, gender, region, marital_status,
    occupation, education_level, primary_platform, daily_watch_hours,
    content_type, peak_usage_time, daily_opens, voice_msg_behavior,
    usage_duration_since, content_relevance, difficulty_closing_app,
    productivity_impact, sleep_impact, feeling_after_closing,
    watching_companion, behavior_while_watching, phone_during_family,
    family_opinion, reason_for_watching, social_media_without_reels,
    purchased_from_video, purchase_reason, purchase_influence_level,
    rewatched_before_purchase
) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
"""

BATCH_SIZE  = 200
total       = len(df)
inserted    = 0
failed_rows = []

print(f"\nInserting {total:,} rows in batches of {BATCH_SIZE}...")

for i in range(0, total, BATCH_SIZE):
    batch = df.iloc[i : i + BATCH_SIZE]
    rows  = []
    for _, row in batch.iterrows():
        r = tuple(None if (row[col] is None or row[col] != row[col]) else row[col] for col in COLUMNS)
        rows.append(r)
    try:
        cursor.executemany(INSERT_SQL, rows)
        conn.commit()
        inserted += len(rows)
        pct = inserted / total * 100
        print(f"  Progress: {inserted:,} / {total:,} ({pct:.1f}%)", end="\r")
    except Exception as e:
        conn.rollback()
        print(f"\n  Batch {i}–{i+BATCH_SIZE} failed: {e}")
        # Fall back: insert row by row to skip only the bad ones
        for j, row in enumerate(rows):
            try:
                cursor.execute(INSERT_SQL, row)
                conn.commit()
                inserted += 1
            except Exception as e2:
                print(f"    Row {i+j} skipped: {e2}")
                failed_rows.append(i + j)

print(f"\n\nDone! {inserted:,} rows inserted successfully.")
if failed_rows:
    print(f"Skipped {len(failed_rows)} rows: {failed_rows}")

# ── 5. Sanity check ──────────────────────────────────────────
cursor.execute("SELECT COUNT(*) FROM bronze.reels_survey")
print(f"Total rows now in bronze.reels_survey: {cursor.fetchone()[0]:,}")

cursor.close()
conn.close()
print("Connection closed.")
