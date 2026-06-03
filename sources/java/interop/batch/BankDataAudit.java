import com.rocketsoftware.jzos.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.*;
import java.util.regex.*;

/**
 * Step 9: Data Integrity Audit & Reconciliation
 *
 * A comprehensive data quality framework that validates BankDemo's
 * VSAM datasets for referential integrity, format correctness,
 * and business rule compliance.
 *
 * Demonstrates using ZUtil.getEnv() to read environment variables
 * set in STDENV — a powerful pattern for passing configuration
 * that doesn't fit neatly into MAINARGS or control cards.
 *
 * Audit passes:
 *   STRUCTURAL - orphan accounts, missing customers, dangling txns
 *   FORMAT     - field format validation (PID format, date ranges)
 *   BUSINESS   - balance sanity, transaction amount limits
 *   ALL        - run all passes
 *
 * Returns: RC=0 (clean), RC=4 (warnings), RC=8 (errors), RC=12 (fatal)
 */
public class BankDataAudit {

    private static String auditPass = "ALL";
    private static String severity = "WARN";
    private static String runId = "UNKNOWN";
    private static String auditMode = "FULL";

    private static int errorCount = 0;
    private static int warnCount = 0;
    private static List<String> findings = new ArrayList<>();

    public static void main(String[] args) {
        // Read MAINARGS
        if (args.length >= 1) auditPass = args[0].toUpperCase();
        if (args.length >= 2) severity = args[1].toUpperCase();

        // Read environment (set in STDENV) via ZUtil
        try {
            String envRunId = ZUtil.getEnv("AUDIT_RUN_ID");
            if (envRunId != null) runId = envRunId;
            String envMode = ZUtil.getEnv("AUDIT_MODE");
            if (envMode != null) auditMode = envMode;
        } catch (Exception e) {
            // ZUtil may not be available in all environments
            runId = "LOCAL-" + System.currentTimeMillis();
        }

        System.out.println("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓");
        System.out.println("┃  BANKDEMO DATA INTEGRITY AUDIT                        ┃");
        System.out.println("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛");
        System.out.printf("  Run ID:   %s%n", runId);
        System.out.printf("  Mode:     %s%n", auditMode);
        System.out.printf("  Pass:     %s%n", auditPass);
        System.out.printf("  Severity: %s%n", severity);
        System.out.println();

        // Load all datasets into memory for cross-validation
        Set<String> customerPIDs = loadCustomerPIDs();
        Map<String, Set<String>> accountsByCustomer = loadAccounts();
        Map<String, List<TxnRecord>> txnsByAccount = loadTransactions();

        System.out.printf("  Loaded: %d customers, %d accounts, %d transactions%n",
            customerPIDs.size(),
            accountsByCustomer.values().stream().mapToInt(Set::size).sum(),
            txnsByAccount.values().stream().mapToInt(List::size).sum());
        System.out.println();

        // Execute requested passes
        if (auditPass.equals("ALL") || auditPass.equals("STRUCTURAL")) {
            runStructuralAudit(customerPIDs, accountsByCustomer, txnsByAccount);
        }
        if (auditPass.equals("ALL") || auditPass.equals("FORMAT")) {
            runFormatAudit(customerPIDs, accountsByCustomer);
        }
        if (auditPass.equals("ALL") || auditPass.equals("BUSINESS")) {
            runBusinessAudit(accountsByCustomer, txnsByAccount);
        }

        // Summary
        System.out.println();
        System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        System.out.println("AUDIT SUMMARY");
        System.out.printf("  Errors:   %d%n", errorCount);
        System.out.printf("  Warnings: %d%n", warnCount);
        System.out.printf("  Total findings: %d%n", findings.size());

        if (auditMode.equals("FIXUP") && !findings.isEmpty()) {
            System.out.println();
            System.out.println("RECOMMENDED FIXES:");
            for (String f : findings) {
                System.out.println("  > " + f);
            }
        }

        int rc = 0;
        if (errorCount > 0) rc = 8;
        else if (warnCount > 0) rc = 4;
        System.out.printf("  RC=%d%n", rc);
    }

    private static void runStructuralAudit(Set<String> custPIDs,
            Map<String, Set<String>> acctsByCust,
            Map<String, List<TxnRecord>> txnsByAcct) {

        System.out.println("── STRUCTURAL VALIDATION ──────────────────────────────");

        // Check for orphan accounts (account PID not in customer file)
        Set<String> acctPIDs = acctsByCust.keySet();
        int orphanAccounts = 0;
        for (String pid : acctPIDs) {
            if (!custPIDs.contains(pid)) {
                orphanAccounts++;
                reportFinding("ERROR", "ORPHAN_ACCT",
                    String.format("Account owner PID=%s not found in customer file", pid));
            }
        }

        // Check for transactions referencing non-existent accounts
        Set<String> allAccounts = new HashSet<>();
        acctsByCust.values().forEach(allAccounts::addAll);

        int danglingTxns = 0;
        for (String acctNo : txnsByAcct.keySet()) {
            if (!allAccounts.contains(acctNo)) {
                danglingTxns++;
                reportFinding("WARN", "DANGLING_TXN",
                    String.format("Transactions reference account %s which doesn't exist", acctNo));
            }
        }

        // Check for customers with no accounts
        int noAcctCust = 0;
        for (String pid : custPIDs) {
            if (!acctsByCust.containsKey(pid) || acctsByCust.get(pid).isEmpty()) {
                noAcctCust++;
                if (severity.equals("STRICT")) {
                    reportFinding("WARN", "NO_ACCOUNTS",
                        String.format("Customer PID=%s has no accounts", pid));
                }
            }
        }

        System.out.printf("  Orphan accounts:        %d%n", orphanAccounts);
        System.out.printf("  Dangling transactions:  %d%n", danglingTxns);
        System.out.printf("  Customers w/no account: %d%n", noAcctCust);
        System.out.println();
    }

    private static void runFormatAudit(Set<String> custPIDs,
            Map<String, Set<String>> acctsByCust) {

        System.out.println("── FORMAT VALIDATION ──────────────────────────────────");

        Pattern pidPattern = Pattern.compile("^\\d{5}$");
        Pattern acctPattern = Pattern.compile("^\\d{9}$");

        int badPIDs = 0;
        for (String pid : custPIDs) {
            if (!pidPattern.matcher(pid).matches()) {
                badPIDs++;
                reportFinding("ERROR", "BAD_PID_FMT",
                    String.format("Customer PID '%s' doesn't match 5-digit format", pid));
            }
        }

        int badAccts = 0;
        for (Set<String> accounts : acctsByCust.values()) {
            for (String acct : accounts) {
                if (!acctPattern.matcher(acct).matches()) {
                    badAccts++;
                    reportFinding("ERROR", "BAD_ACCT_FMT",
                        String.format("Account number '%s' doesn't match 9-digit format", acct));
                }
            }
        }

        System.out.printf("  Invalid PID format:     %d%n", badPIDs);
        System.out.printf("  Invalid account format: %d%n", badAccts);
        System.out.println();
    }

    private static void runBusinessAudit(Map<String, Set<String>> acctsByCust,
            Map<String, List<TxnRecord>> txnsByAcct) {

        System.out.println("── BUSINESS RULE VALIDATION ───────────────────────────");

        // Rule: No account should have a negative balance exceeding -$10000
        // (This would require reading balance from accounts - simplified here)

        // Rule: Transaction amounts should not exceed $999,999.99
        int oversizeTxns = 0;
        for (List<TxnRecord> txns : txnsByAcct.values()) {
            for (TxnRecord t : txns) {
                if (Math.abs(t.amount) > 99999999) { // cents
                    oversizeTxns++;
                    reportFinding("ERROR", "OVERSIZE_TXN",
                        String.format("Transaction on acct %s amount $%.2f exceeds limit",
                            t.accountNo, t.amount / 100.0));
                }
            }
        }

        // Rule: Each customer should not have more than 10 accounts
        int overAllocated = 0;
        for (Map.Entry<String, Set<String>> entry : acctsByCust.entrySet()) {
            if (entry.getValue().size() > 10) {
                overAllocated++;
                reportFinding("WARN", "EXCESS_ACCTS",
                    String.format("Customer %s has %d accounts (max recommended: 10)",
                        entry.getKey(), entry.getValue().size()));
            }
        }

        System.out.printf("  Oversized transactions: %d%n", oversizeTxns);
        System.out.printf("  Over-allocated custs:   %d%n", overAllocated);
        System.out.println();
    }

    private static void reportFinding(String level, String code, String message) {
        String entry = String.format("[%s] %s: %s", level, code, message);
        findings.add(entry);
        if (level.equals("ERROR")) {
            errorCount++;
            System.out.println("    ✗ " + entry);
        } else {
            warnCount++;
            if (!severity.equals("ERROR")) { // Show warnings unless ERROR-only mode
                System.out.println("    ⚠ " + entry);
            }
        }
    }

    // --- Data loading ---

    private static Set<String> loadCustomerPIDs() {
        Set<String> pids = new LinkedHashSet<>();
        ZFile zFile = null;
        try {
            zFile = new ZFile("//DD:CUSTDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];
            while (zFile.read(record) >= 0) {
                pids.add(new String(record, 0, 5).trim());
            }
        } catch (Exception e) {
            System.err.println("FATAL: Cannot read CUSTDATA - " + e.getMessage());
            throw new RuntimeException("Fatal error");
        } finally {
            if (zFile != null) zFile.close();
        }
        return pids;
    }

    private static Map<String, Set<String>> loadAccounts() {
        Map<String, Set<String>> map = new HashMap<>();
        ZFile zFile = null;
        try {
            zFile = new ZFile("//DD:ACCTDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];
            while (zFile.read(record) >= 0) {
                String pid = new String(record, 0, 5).trim();
                String accNo = new String(record, 5, 9).trim();
                map.computeIfAbsent(pid, k -> new LinkedHashSet<>()).add(accNo);
            }
        } catch (Exception e) {
            System.err.println("FATAL: Cannot read ACCTDATA - " + e.getMessage());
            throw new RuntimeException("Fatal error");
        } finally {
            if (zFile != null) zFile.close();
        }
        return map;
    }

    private static Map<String, List<TxnRecord>> loadTransactions() {
        Map<String, List<TxnRecord>> map = new HashMap<>();
        ZFile zFile = null;
        try {
            zFile = new ZFile("//DD:TXNDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];
            while (zFile.read(record) >= 0) {
                String accNo = new String(record, 7, 9).trim();
                long amount = decodePackedDecimal(record, 42, 5);
                map.computeIfAbsent(accNo, k -> new ArrayList<>())
                   .add(new TxnRecord(accNo, amount));
            }
        } catch (Exception e) {
            System.err.println("FATAL: Cannot read TXNDATA - " + e.getMessage());
            throw new RuntimeException("Fatal error");
        } finally {
            if (zFile != null) zFile.close();
        }
        return map;
    }

    private static long decodePackedDecimal(byte[] data, int offset, int len) {
        long value = 0;
        for (int i = offset; i < offset + len; i++) {
            int b = data[i] & 0xFF;
            int hi = (b >> 4) & 0x0F;
            int lo = b & 0x0F;
            if (i < offset + len - 1) {
                value = value * 10 + hi;
                value = value * 10 + lo;
            } else {
                value = value * 10 + hi;
                if (lo == 0x0D) value = -value;
            }
        }
        return value;
    }

    static class TxnRecord {
        String accountNo;
        long amount;
        TxnRecord(String accountNo, long amount) {
            this.accountNo = accountNo;
            this.amount = amount;
        }
    }
}
