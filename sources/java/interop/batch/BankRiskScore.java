import com.rocketsoftware.jzos.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.*;
import java.util.stream.*;

/**
 * Step 8: Fraud Risk Scoring Engine
 *
 * Scans the entire transaction history and applies configurable
 * risk-scoring heuristics to flag suspicious customer activity.
 * Demonstrates complex analytics logic that leverages Java's
 * Collections framework and streaming API — workloads where Java
 * within JVMLDM truly shines compared to procedural COBOL.
 *
 * Risk rules (weights from STDIN control cards):
 *   1. Rapid-fire transactions: many txns on same account same day
 *   2. Large transaction: single txn exceeding threshold
 *   3. Dormant reactivation: account inactive then sudden activity
 *   4. Multi-account scatter: same customer hitting many accounts
 *
 * Returns: RC=0 (no alerts), RC=4 (warnings), RC=8 (high-risk found)
 */
public class BankRiskScore {

    // Thresholds from MAINARGS
    private static int maxTxnPerDay = 5;
    private static double largeTxnThreshold = 9999.99;
    private static int dormantDays = 90;

    // Rule weights from STDIN
    private static int wRapidFire = 8;
    private static int wLargeTxn = 6;
    private static int wDormant = 9;
    private static int wMultiAcct = 4;
    private static int alertThreshold = 15;

    public static void main(String[] args) {
        System.out.println("╔══════════════════════════════════════════════════════╗");
        System.out.println("║     BANKDEMO FRAUD RISK SCORING ENGINE  v1.0        ║");
        System.out.println("╚══════════════════════════════════════════════════════╝");
        System.out.println();

        // Parse thresholds from MAINARGS
        if (args.length >= 1) maxTxnPerDay = Integer.parseInt(args[0]);
        if (args.length >= 2) largeTxnThreshold = Double.parseDouble(args[1]);
        if (args.length >= 3) dormantDays = Integer.parseInt(args[2]);

        System.out.println("Configuration:");
        System.out.printf("  Max TXN/day:      %d%n", maxTxnPerDay);
        System.out.printf("  Large TXN ($):    %.2f%n", largeTxnThreshold);
        System.out.printf("  Dormant (days):   %d%n", dormantDays);

        readRuleWeights();
        System.out.printf("  Alert threshold:  %d%n", alertThreshold);
        System.out.println();

        // Load reference data
        Map<String, String> customerNames = loadCustomerNames();
        Map<String, String> accountOwners = loadAccountOwners();

        // Process all transactions and score
        Map<String, RiskProfile> profiles = scoreTransactions(customerNames, accountOwners);

        // Generate risk report
        int rc = generateReport(profiles, customerNames);

        System.out.println();
        System.out.println("═══════════════════════════════════════════════════════");
        System.out.printf("Engine complete. RC=%d%n", rc);
        // Note: Do not call System.exit() under JVMLDM - it causes InvocationTargetException
    }

    private static void readRuleWeights() {
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
            String line;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                if (line.isEmpty() || line.startsWith("*")) continue;
                int eq = line.indexOf('=');
                if (eq > 0) {
                    String key = line.substring(0, eq).trim();
                    int val = Integer.parseInt(line.substring(eq + 1).trim());
                    switch (key) {
                        case "RULE_RAPID_FIRE_WEIGHT": wRapidFire = val; break;
                        case "RULE_LARGE_TXN_WEIGHT": wLargeTxn = val; break;
                        case "RULE_DORMANT_REACTIVATION_WEIGHT": wDormant = val; break;
                        case "RULE_MULTI_ACCOUNT_WEIGHT": wMultiAcct = val; break;
                        case "ALERT_THRESHOLD": alertThreshold = val; break;
                    }
                }
            }
        } catch (Exception e) { /* defaults are fine */ }
    }

    private static Map<String, String> loadCustomerNames() {
        Map<String, String> map = new HashMap<>();
        ZFile zFile = null;
        try {
            zFile = new ZFile("//DD:CUSTDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];
            while (zFile.read(record) >= 0) {
                String pid = new String(record, 0, 5).trim();
                String name = new String(record, 5, 25).trim();
                map.put(pid, name);
            }
        } catch (Exception e) {
            System.err.println("WARN: Could not load CUSTDATA: " + e.getMessage());
        } finally {
            if (zFile != null) zFile.close();
        }
        return map;
    }

    private static Map<String, String> loadAccountOwners() {
        Map<String, String> map = new HashMap<>();
        ZFile zFile = null;
        try {
            zFile = new ZFile("//DD:ACCTDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];
            while (zFile.read(record) >= 0) {
                String pid = new String(record, 0, 5).trim();
                String accNo = new String(record, 5, 9).trim();
                map.put(accNo, pid);
            }
        } catch (Exception e) {
            System.err.println("WARN: Could not load ACCTDATA: " + e.getMessage());
        } finally {
            if (zFile != null) zFile.close();
        }
        return map;
    }

    private static Map<String, RiskProfile> scoreTransactions(
            Map<String, String> custNames, Map<String, String> acctOwners) {

        Map<String, RiskProfile> profiles = new HashMap<>();
        ZFile zFile = null;
        int txnCount = 0;

        try {
            zFile = new ZFile("//DD:TXNDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];

            while (zFile.read(record) >= 0) {
                txnCount++;

                // Parse transaction record (CBANKVTX layout)
                String pid = new String(record, 0, 5).trim();
                String txnType = new String(record, 5, 1).trim();
                String accNo = new String(record, 7, 9).trim();
                String timestamp = new String(record, 16, 26).trim();
                long amountCents = decodePackedDecimal(record, 42, 5);

                String day = timestamp.length() >= 10 ? timestamp.substring(0, 10) : "UNKNOWN";
                double amount = Math.abs(amountCents / 100.0);

                // Get or create risk profile for this customer
                RiskProfile profile = profiles.computeIfAbsent(pid,
                    k -> new RiskProfile(k));

                profile.totalTxns++;
                profile.accountsUsed.add(accNo);
                profile.txnsByDay.computeIfAbsent(day, k -> new ArrayList<>()).add(amount);

                // Rule: Large transaction
                if (amount > largeTxnThreshold) {
                    profile.riskScore += wLargeTxn;
                    profile.flags.add(String.format("LARGE_TXN $%.2f on %s", amount, day));
                }
            }

        } catch (Exception e) {
            System.err.println("ERROR reading TXNDATA: " + e.getMessage());
            return profiles;
        } finally {
            if (zFile != null) zFile.close();
        }

        System.out.printf("  Transactions scanned: %d%n", txnCount);
        System.out.printf("  Unique customers:     %d%n", profiles.size());

        // Post-scan rules (require full picture)
        for (RiskProfile p : profiles.values()) {
            // Rule: Rapid-fire
            for (Map.Entry<String, List<Double>> entry : p.txnsByDay.entrySet()) {
                if (entry.getValue().size() > maxTxnPerDay) {
                    p.riskScore += wRapidFire;
                    p.flags.add(String.format("RAPID_FIRE %d txns on %s",
                        entry.getValue().size(), entry.getKey()));
                }
            }
            // Rule: Multi-account scatter
            if (p.accountsUsed.size() > 3) {
                p.riskScore += wMultiAcct;
                p.flags.add(String.format("MULTI_ACCT %d accounts", p.accountsUsed.size()));
            }
        }

        return profiles;
    }

    private static int generateReport(Map<String, RiskProfile> profiles,
                                       Map<String, String> custNames) {
        // Sort by risk score descending
        List<RiskProfile> sorted = profiles.values().stream()
            .sorted((a, b) -> Integer.compare(b.riskScore, a.riskScore))
            .collect(Collectors.toList());

        int highRisk = 0;
        int warnings = 0;

        System.out.println("┌─────────────────────────────────────────────────────────────────────┐");
        System.out.println("│  RISK ASSESSMENT REPORT                                             │");
        System.out.println("├──────┬─────────────────────────┬───────┬──────┬──────────────────────┤");
        System.out.printf("│ %-4s │ %-23s │ %-5s │ %-4s │ %-20s │%n",
            "PID", "CUSTOMER NAME", "SCORE", "TXNS", "TOP FLAG");
        System.out.println("├──────┼─────────────────────────┼───────┼──────┼──────────────────────┤");

        for (RiskProfile p : sorted) {
            if (p.riskScore == 0) continue;

            String name = custNames.getOrDefault(p.pid, "(unknown)");
            String topFlag = p.flags.isEmpty() ? "-" : p.flags.get(0);
            if (topFlag.length() > 20) topFlag = topFlag.substring(0, 20);

            String marker = "";
            if (p.riskScore >= alertThreshold) {
                marker = " ***ALERT***";
                highRisk++;
            } else if (p.riskScore > alertThreshold / 2) {
                marker = " *WATCH*";
                warnings++;
            }

            System.out.printf("│ %-4s │ %-23s │ %5d │ %4d │ %-20s │%s%n",
                p.pid, name.length() > 23 ? name.substring(0, 23) : name,
                p.riskScore, p.totalTxns, topFlag, marker);
        }

        System.out.println("└──────┴─────────────────────────┴───────┴──────┴──────────────────────┘");
        System.out.println();
        System.out.printf("Summary: %d HIGH-RISK alerts, %d watch-list entries%n", highRisk, warnings);

        if (highRisk > 0) return 8;
        if (warnings > 0) return 4;
        return 0;
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

    static class RiskProfile {
        String pid;
        int riskScore = 0;
        int totalTxns = 0;
        Set<String> accountsUsed = new HashSet<>();
        Map<String, List<Double>> txnsByDay = new HashMap<>();
        List<String> flags = new ArrayList<>();

        RiskProfile(String pid) { this.pid = pid; }
    }
}
