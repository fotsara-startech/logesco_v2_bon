-- CreateTable operation_log
CREATE TABLE "operation_log" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "operation_id" TEXT NOT NULL UNIQUE,
  "operation_type" TEXT NOT NULL,
  "table_name" TEXT NOT NULL,
  "record_id" INTEGER,
  "data" TEXT,
  "timestamp" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "synced_at" DATETIME,
  "status" TEXT NOT NULL DEFAULT 'pending',
  "error_message" TEXT,
  "device_id" TEXT,
  "user_id" INTEGER
);

-- CreateIndex operation_log_status_timestamp
CREATE INDEX "operation_log_status_timestamp" ON "operation_log"("status", "timestamp");

-- CreateIndex operation_log_table_timestamp
CREATE INDEX "operation_log_table_timestamp" ON "operation_log"("table_name", "timestamp");

-- CreateIndex operation_log_operation_id
CREATE INDEX "operation_log_operation_id" ON "operation_log"("operation_id");
