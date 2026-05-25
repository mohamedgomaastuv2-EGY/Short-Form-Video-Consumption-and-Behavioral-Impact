import pandas as pd
import pyodbc

# ── 1. Config — UPDATE THESE ─────────────────────────────────
CSV_PATH = r'D:\YF\DATA ANALYST CORE\DEPI TECH TRACK\Final Project\Final Project\Dataset\DWH\Bronze Layer\survey_row_data - Copy.csv'
SERVER   = '.'    # e.g. DESKTOP-ABC123 or localhost
DATABASE = 'Reels_Pulse_Warehouse'

# ── 2. Read CSV ──────────────────────────────────────────────
print("Reading CSV...")
df = pd.read_csv(CSV_PATH, encoding='utf-8-sig', dtype=str)

# Force ALL null-like values to Python None
df = df.astype(object).where(pd.notnull(df), other=None)
for col in df.columns:
    df[col] = df[col].apply(lambda x: None if (x is None or isinstance(x, float)) else str(x).strip() or None)

print(f"Loaded {len(df):,} rows x {len(df.columns)} columns")

# ── 3. Silver-Layer Transformations ──────────────────────────
print("\nApplying silver-layer transformations...")

# 3a. Standardize text columns to Title Case
text_cols = [
    'gender', 'region', 'marital_status', 'occupation', 'education_level',
    'primary_platform', 'content_type', 'peak_usage_time', 'voice_msg_behavior',
    'usage_duration_since', 'content_relevance', 'difficulty_closing_app',
    'productivity_impact', 'sleep_impact', 'feeling_after_closing',
    'watching_companion', 'behavior_while_watching', 'phone_during_family',
    'family_opinion', 'reason_for_watching', 'social_media_without_reels',
    'purchased_from_video', 'purchase_reason', 'rewatched_before_purchase',
    'daily_watch_hours', 'daily_opens', 'purchase_influence_level'
]
for col in text_cols:
    if col in df.columns:
        df[col] = df[col].apply(lambda x: x.title() if pd.notna(x) else x)

# 3b. daily_watch_hours, daily_opens, and purchase_influence_level are
#     Arabic categorical text (e.g. "🎵 1 – 2 ساعة", "* 🙂 **3 – 5 مرات**"),
#     NOT numeric — treat them as plain text like all other columns.
#     They are already handled by the null-cleanup pass above; nothing extra needed.

# 3c. Normalize timestamp (strip whitespace; keep as string)
if 'timestamp' in df.columns:
    df['timestamp'] = df['timestamp'].apply(lambda x: x.strip() if x else None)

# 3d. Standardize age_group labels (e.g. "18-24", "25-34" ...)
if 'age_group' in df.columns:
    df['age_group'] = df['age_group'].apply(lambda x: x.strip() if x else None)

# 3e. Drop exact duplicate rows
before_dedup = len(df)
df = df.drop_duplicates()
print(f"Removed {before_dedup - len(df):,} duplicate rows")

print(f"Rows after cleaning: {len(df):,}")
print("Null counts:", {c: df[c].isna().sum() for c in df.columns if df[c].isna().sum() > 0})

# ── 4. Connect ───────────────────────────────────────────────
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

# ── 5. Verify the target table exists before inserting ───────
cursor.execute("""
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'silver'
      AND TABLE_NAME   = 'reels_survey'
""")
if cursor.fetchone()[0] == 0:
    raise RuntimeError(
        "Table 'silver.reels_survey' does not exist in database "
        f"'{DATABASE}' on server '{SERVER}'.\n"
        "Please run the Silver Layer DDL script first."
    )

# ── 6. Insert into Silver Layer ──────────────────────────────
# NOTE: ingested_at is excluded — it uses the DEFAULT SYSUTCDATETIME()
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
INSERT INTO silver.reels_survey (
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

print(f"\nInserting {total:,} rows into silver.reels_survey in batches of {BATCH_SIZE}...")

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

# ── 7. Sanity check ──────────────────────────────────────────
cursor.execute("SELECT COUNT(*) FROM silver.reels_survey")
print(f"Total rows now in silver.reels_survey: {cursor.fetchone()[0]:,}")

cursor.close()
conn.close()
print("Connection closed.")
