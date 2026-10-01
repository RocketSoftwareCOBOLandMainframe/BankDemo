import com.rocketsoftware.jzos.*;
import java.io.*;
import java.math.BigDecimal;
import java.util.*;

/**
 * Multi-step BankDemo batch report.
 *
 * FILTER: Reads BNKCUST, filters by customer ID regex pattern from MAINARGS.
 * REPORT: Reads BNKACC, decodes packed-decimal balances, writes formatted report.
 *
 * Usage via JVMLDM:
 *   PARM='... BankCustAcctReport FILTER <pattern>'
 *   PARM='... BankCustAcctReport REPORT <maxRecords>'
 */
public class BankCustAcctReport {

    // BNKCUST record layout
    private static final int CUST_PID_OFF = 0,   CUST_PID_LEN = 5;
    private static final int CUST_NAME_OFF = 5,  CUST_NAME_LEN = 25;
    private static final int CUST_STATE_OFF = 139, CUST_STATE_LEN = 2;
    private static final int CUST_EMAIL_OFF = 159, CUST_EMAIL_LEN = 30;

    // BNKACC record layout
    private static final int ACC_PID_OFF = 0,     ACC_PID_LEN = 5;
    private static final int ACC_ACCNO_OFF = 5,   ACC_ACCNO_LEN = 9;
    private static final int ACC_TYPE_OFF = 14,   ACC_TYPE_LEN = 1;
    private static final int ACC_BALANCE_OFF = 15, ACC_BALANCE_LEN = 5; // S9(7)V99 COMP-3

    private static final String SEPARATOR = "=".repeat(72);

    public static void main(String[] args) {
        try {
            run(args);
        } catch (Throwable t) {
            System.err.println("FATAL: " + t.getClass().getName() + ": " + t.getMessage());
            t.printStackTrace(System.err);
            System.exit(16);
        }
    }

    private static void run(String[] args) throws IOException {
        if (args.length < 1) {
            System.err.println("ERROR: Missing step argument (FILTER or REPORT)");
            System.exit(12);
        }

        String step = args[0].toUpperCase();
        logJobContext(step);

        switch (step) {
            case "FILTER":
                runFilter(args.length > 1 ? args[1] : ".*");
                break;
            case "REPORT":
                int maxRecords = args.length > 1 ? Integer.parseInt(args[1]) : 50;
                runReport(maxRecords, readControlCards());
                break;
            default:
                System.err.println("ERROR: Unknown step '" + step + "'. Use FILTER or REPORT.");
                System.exit(12);
        }
    }

    private static void logJobContext(String step) {
        System.err.printf("Job: %s (ID: %s)  Step: %s  User: %s%n",
            ZUtil.getCurrentJobname(), ZUtil.getCurrentJobId(),
            ZUtil.getCurrentStepname(), ZUtil.getCurrentUser());
        System.err.printf("Mode: %s  Encoding: %s%n", step, ZUtil.getDefaultPlatformEncoding());
    }

    // -------------------------------------------------------------------------
    // FILTER step
    // -------------------------------------------------------------------------

    private static void runFilter(String pattern) throws IOException {
        try (ZFile outFile = new ZFile("//'MFI01V.MFIDEMO.CUST.FILTER'", "wb,lrecl=132,type=record")) {
            writeLine(outFile, "=== Customer Filter Step ===");
            writeLine(outFile, "Filter pattern: " + pattern);
            System.out.println("=== Customer Filter Step ===");
            System.out.println("Filter pattern: " + pattern);

            try (ZFile custFile = new ZFile("//DD:CUSTDATA", "rb,type=record")) {
                System.err.printf("DIAG: Opened DD:CUSTDATA  LRECL=%d  RECFM=%s  BLKSIZE=%d%n",
                    custFile.getLrecl(), custFile.getRecfm(), custFile.getBlksize());

                byte[] record = new byte[custFile.getLrecl()];
                int totalRead = 0, matched = 0;

                while (custFile.read(record) >= 0) {
                    totalRead++;
                    String pid = extractField(record, CUST_PID_OFF, CUST_PID_LEN);

                    if (pid.matches(pattern)) {
                        matched++;
                        String line = String.format("  MATCH: PID=%-5s  Name=%-25s  State=%-2s  Email=%s",
                            pid,
                            extractField(record, CUST_NAME_OFF, CUST_NAME_LEN),
                            extractField(record, CUST_STATE_OFF, CUST_STATE_LEN),
                            extractField(record, CUST_EMAIL_OFF, CUST_EMAIL_LEN));
                        System.out.println(line);
                        writeLine(outFile, line);
                    }
                }

                String summary = String.format("Filter complete: %d/%d customers matched.", matched, totalRead);
                System.out.println(summary);
                writeLine(outFile, summary);
                System.err.printf("DIAG: Processed %d records, %d matched '%s'%n",
                    totalRead, matched, pattern);
            }
        }
    }

    // -------------------------------------------------------------------------
    // REPORT step
    // -------------------------------------------------------------------------

    private static void runReport(int maxRecords, Map<String, String> controlCards)
            throws IOException {
        String title = controlCards.getOrDefault("REPORT_TITLE", "Bank Account Summary");

        try (ZFile outFile = new ZFile("//'MFI01V.MFIDEMO.ACCT.SUMMARY'", "wb,lrecl=132,type=record")) {
            printBoth(outFile, SEPARATOR);
            printBoth(outFile, "  " + title);
            printBoth(outFile, String.format("  Generated by: %s / %s",
                ZUtil.getCurrentJobname(), ZUtil.getCurrentStepname()));
            printBoth(outFile, SEPARATOR);
            printBoth(outFile, String.format("  %-5s  %-9s  %-4s  %12s", "PID", "Account", "Type", "Balance"));
            printBoth(outFile, "  " + "-".repeat(38));

            try (ZFile accFile = new ZFile("//DD:ACCDATA", "rb,type=record")) {
                System.err.printf("DIAG: Opened DD:ACCDATA  LRECL=%d  RECFM=%s  BLKSIZE=%d%n",
                    accFile.getLrecl(), accFile.getRecfm(), accFile.getBlksize());

                byte[] record = new byte[accFile.getLrecl()];
                int count = 0;
                BigDecimal totalBalance = BigDecimal.ZERO;

                while (accFile.read(record) >= 0 && count < maxRecords) {
                    String pid = extractField(record, ACC_PID_OFF, ACC_PID_LEN);
                    String accNo = extractField(record, ACC_ACCNO_OFF, ACC_ACCNO_LEN);
                    String accType = extractField(record, ACC_TYPE_OFF, ACC_TYPE_LEN);
                    BigDecimal balance = unpackDecimal(record, ACC_BALANCE_OFF, ACC_BALANCE_LEN, 2);

                    String line = String.format("  %-5s  %-9s  %-4s  %12s",
                        pid, accNo, accType, balance.toPlainString());
                    printBoth(outFile, line);

                    totalBalance = totalBalance.add(balance);
                    count++;
                }

                printBoth(outFile, "  " + "-".repeat(38));
                printBoth(outFile, String.format("  Records: %d   Total Balance: %s",
                    count, totalBalance.toPlainString()));
                printBoth(outFile, SEPARATOR);
                System.err.printf("DIAG: Report displayed %d records%n", count);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Utilities
    // -------------------------------------------------------------------------

    private static String extractField(byte[] record, int offset, int length) {
        return new String(record, offset, length).trim();
    }

    private static void writeLine(ZFile file, String text) throws IOException {
        file.write(String.format("%-132s", text).getBytes());
    }

    private static void printBoth(ZFile file, String text) throws IOException {
        System.out.println(text);
        writeLine(file, text);
    }

    private static Map<String, String> readControlCards() {
        Map<String, String> cards = new LinkedHashMap<>();
        try {
            BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
            String line;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                if (line.isEmpty() || line.startsWith("*")) continue;
                int eq = line.indexOf('=');
                if (eq > 0) {
                    cards.put(line.substring(0, eq).trim(), line.substring(eq + 1).trim());
                }
            }
        } catch (IOException e) {
            System.err.println("WARN: Could not read control cards: " + e.getMessage());
        }
        System.err.printf("DIAG: Read %d control cards from STDIN%n", cards.size());
        return cards;
    }

    private static BigDecimal unpackDecimal(byte[] data, int offset, int length, int scale) {
        StringBuilder digits = new StringBuilder();
        for (int i = 0; i < length; i++) {
            int b = data[offset + i] & 0xFF;
            digits.append((b >> 4) & 0x0F);
            if (i < length - 1) {
                digits.append(b & 0x0F);
            }
        }

        int signNibble = data[offset + length - 1] & 0x0F;
        BigDecimal value = new BigDecimal(digits.toString()).movePointLeft(scale);
        return (signNibble == 0x0D) ? value.negate() : value;
    }
}
