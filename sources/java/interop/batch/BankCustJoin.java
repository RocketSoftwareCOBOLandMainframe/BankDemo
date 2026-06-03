import com.rocketsoftware.jzos.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.*;

/**
 * Step 7: Customer-Account Join Report
 *
 * Opens two VSAM datasets concurrently via ZFile and performs an
 * in-memory hash-join on Customer PID. Demonstrates that JVMLDM
 * supports multiple simultaneous DD allocations — a powerful
 * pattern for cross-dataset batch processing in Java.
 *
 * Reads control cards from STDIN for output formatting options.
 *
 * Record layouts (from copybooks):
 *   CUSTDATA (CBANKVCS): PID(5) NAME(25) NAME_FF(25) SIN(9) ADDR1(25) ...
 *   ACCTDATA (CBANKVAC): PID(5) ACCNO(9) TYPE(1) BALANCE(COMP-3,5bytes) ...
 */
public class BankCustJoin {

    private static String outputFormat = "REPORT";
    private static long minBalance = 0;
    private static boolean includeEmpty = false;

    public static void main(String[] args) {
        System.out.println("=== Step 7: Customer-Account Join Report ===");
        System.out.println();

        readControlCards();

        // Load customers into a HashMap keyed by PID
        Map<String, CustomerRecord> customers = loadCustomers();
        System.out.printf("  Customers loaded: %d%n", customers.size());

        // Stream through accounts and attach to customer records
        int accountCount = joinAccounts(customers);
        System.out.printf("  Accounts joined:  %d%n", accountCount);
        System.out.println();

        // Produce output in requested format
        int rc = produceReport(customers);

        System.out.println();
        System.out.println("=== Join Complete. RC=" + rc + " ===");
    }

    private static void readControlCards() {
        try {
            BufferedReader reader = new BufferedReader(
                new InputStreamReader(System.in));
            String line;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                if (line.isEmpty() || line.startsWith("*")) continue;
                int eq = line.indexOf('=');
                if (eq > 0) {
                    String key = line.substring(0, eq).trim();
                    String val = line.substring(eq + 1).trim();
                    switch (key) {
                        case "OUTPUT_FORMAT": outputFormat = val.toUpperCase(); break;
                        case "MIN_BALANCE":   minBalance = Long.parseLong(val); break;
                        case "INCLUDE_EMPTY": includeEmpty = val.equalsIgnoreCase("Y"); break;
                    }
                }
            }
        } catch (Exception e) {
            System.out.println("  (Using default control parameters)");
        }
        System.out.println("  Format:        " + outputFormat);
        System.out.println("  Min Balance:   " + minBalance);
        System.out.println("  Include Empty: " + includeEmpty);
        System.out.println();
    }

    private static Map<String, CustomerRecord> loadCustomers() {
        Map<String, CustomerRecord> map = new LinkedHashMap<>();
        ZFile zFile = null;
        try {
            zFile = new ZFile("//DD:CUSTDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];
            int bytesRead;

            while ((bytesRead = zFile.read(record)) >= 0) {
                String pid = new String(record, 0, 5).trim();
                String name = new String(record, 5, 25).trim();
                String state = new String(record, 124, 2).trim();
                map.put(pid, new CustomerRecord(pid, name, state));
            }
        } catch (Exception e) {
            System.err.println("ERROR reading CUSTDATA: " + e.getMessage());
            throw new RuntimeException("Fatal error");
        } finally {
            if (zFile != null) zFile.close();
        }
        return map;
    }

    private static int joinAccounts(Map<String, CustomerRecord> customers) {
        ZFile zFile = null;
        int count = 0;
        try {
            zFile = new ZFile("//DD:ACCTDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];
            int bytesRead;

            while ((bytesRead = zFile.read(record)) >= 0) {
                count++;
                String pid = new String(record, 0, 5).trim();
                String accNo = new String(record, 5, 9).trim();
                String type = new String(record, 14, 1).trim();

                // Decode COMP-3 balance (S9(7)V99 = 5 bytes packed)
                long balanceCents = decodePackedDecimal(record, 15, 5);

                CustomerRecord cust = customers.get(pid);
                if (cust != null) {
                    cust.accounts.add(new AccountRecord(accNo, type, balanceCents));
                }
            }
        } catch (Exception e) {
            System.err.println("ERROR reading ACCTDATA: " + e.getMessage());
            throw new RuntimeException("Fatal error");
        } finally {
            if (zFile != null) zFile.close();
        }
        return count;
    }

    private static int produceReport(Map<String, CustomerRecord> customers) {
        int warnings = 0;

        switch (outputFormat) {
            case "CSV":
                System.out.println("PID,NAME,STATE,ACCOUNT,TYPE,BALANCE");
                for (CustomerRecord c : customers.values()) {
                    for (AccountRecord a : c.accounts) {
                        if (a.balanceCents >= minBalance) {
                            System.out.printf("%s,%s,%s,%s,%s,%.2f%n",
                                c.pid, c.name, c.state, a.accNo, a.type,
                                a.balanceCents / 100.0);
                        }
                    }
                }
                break;

            case "SUMMARY":
                System.out.printf("%-5s %-25s %-2s %5s %12s%n",
                    "PID", "NAME", "ST", "ACCTS", "TOTAL BAL");
                System.out.println("-".repeat(55));
                for (CustomerRecord c : customers.values()) {
                    if (!includeEmpty && c.accounts.isEmpty()) continue;
                    long total = c.accounts.stream()
                        .mapToLong(a -> a.balanceCents).sum();
                    if (total >= minBalance) {
                        System.out.printf("%-5s %-25s %-2s %5d %12.2f%n",
                            c.pid, c.name, c.state, c.accounts.size(),
                            total / 100.0);
                    }
                }
                break;

            default: // REPORT
                for (CustomerRecord c : customers.values()) {
                    if (!includeEmpty && c.accounts.isEmpty()) continue;
                    System.out.printf("Customer: %s  %-25s [%s]%n",
                        c.pid, c.name, c.state);
                    if (c.accounts.isEmpty()) {
                        System.out.println("  (no accounts)");
                        warnings++;
                    }
                    for (AccountRecord a : c.accounts) {
                        if (a.balanceCents >= minBalance) {
                            System.out.printf("    Acct %-9s  Type=%s  Balance=$%,.2f%n",
                                a.accNo, a.type, a.balanceCents / 100.0);
                        }
                    }
                }
                break;
        }
        return warnings > 0 ? 4 : 0;
    }

    /** Decode an IBM COMP-3 packed decimal field. */
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
                // lo is the sign nibble: 0xD = negative
                if (lo == 0x0D) value = -value;
            }
        }
        return value;
    }

    static class CustomerRecord {
        String pid, name, state;
        List<AccountRecord> accounts = new ArrayList<>();
        CustomerRecord(String pid, String name, String state) {
            this.pid = pid; this.name = name; this.state = state;
        }
    }

    static class AccountRecord {
        String accNo, type;
        long balanceCents;
        AccountRecord(String accNo, String type, long balanceCents) {
            this.accNo = accNo; this.type = type; this.balanceCents = balanceCents;
        }
    }
}
