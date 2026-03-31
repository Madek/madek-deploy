# Suppress restored prod emails/notifications on staging

## Context
Staging DB is restored nightly from prod. All pending emails (trials=0) and unacknowledged notifications restored from prod must be suppressed immediately after restore, so only activity created on staging itself gets delivered.

## Approach
Add a post-restore cleanup task to the datalayer deploy role. Runs psql directly (no app needed at that stage). Gated on `restore_structure_and_data | bool`.

## SQL to execute
```sql
UPDATE emails
SET trials = 9999, is_successful = false, updated_at = now(),
    error_message = 'suppressed: restored from prod backup'
WHERE is_successful IS NOT TRUE;

UPDATE notifications SET acknowledged = true WHERE acknowledged = false;
```

Targets all emails not already successfully sent: pending (`trials=0`) and failed retries (`is_successful=false`). Mail service retries while `trials <= array_length(retries_seconds)` (default: 7). Setting `trials=9999` ensures no retry regardless of config.

Notification `acknowledged=false` + `email_id IS NULL` = candidates for next batch email. Setting `acknowledged=true` excludes them from future `produce_daily_emails` / `produce_weekly_emails` runs.

## Files to modify/create

- `admin-webapp/datalayer/deploy/roles/deploy/tasks/main.yml` — add include after `restore.yml`
- `admin-webapp/datalayer/deploy/roles/deploy/tasks/post-restore-cleanup.yml` — new file

## Implementation

### `main.yml` addition (after line 13, restore.yml include)
```yaml
- include_tasks: post-restore-cleanup.yml
  when: restore_structure_and_data | bool
```

### `post-restore-cleanup.yml` (new)
```yaml
- name: Suppress pending emails restored from prod
  become: true
  become_user: '{{database.user}}'
  shell: >
    psql --port {{database.port}} {{database.name}} -c
    "UPDATE emails SET trials=9999, is_successful=false, updated_at=now(),
    error_message='suppressed: restored from prod backup'
    WHERE is_successful IS NOT TRUE;"
  register: suppress_emails

- name: Acknowledge notifications restored from prod
  become: true
  become_user: '{{database.user}}'
  shell: >
    psql --port {{database.port}} {{database.name}} -c
    "UPDATE notifications SET acknowledged=true WHERE acknowledged=false;"
  register: suppress_notifications
```

## Verification
1. Deploy to staging (which restores prod)
2. Check `SELECT count(*) FROM emails WHERE trials=0 AND is_successful IS NULL` → should be 0
3. Check `SELECT count(*) FROM notifications WHERE acknowledged=false` → should be 0 (right after restore, before any staging activity)
4. Create a new notification on staging → verify it gets emailed normally
