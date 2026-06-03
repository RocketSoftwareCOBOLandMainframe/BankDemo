import com.rocketsoftware.jzos.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;

/**
 * Demonstrates JVMLDM batch processing with multiple DD inputs.
 * Reads control parameters from STDIN DD and processes bank
 * transaction data, producing a formatted report on STDOUT.
 *
 * Usage via JCL Procedure:
 *   //STEP00   EXEC PROC=JVMPRC86,
 *   //             JAVACLS='BankTxnReport'
 *   //STDIN     DD *
 *   REPORT_TITLE=Monthly Transaction Summary
 *   MAX_RECORDS=100
 *   /*
 *   //TXNDATA   DD DSN=MFI01V.MFIDEMO.BNKTXN,DISP=SHR
 *
 * Reads configuration from System.in (STDIN DD) and transaction
 * data from the TXNDATA DD via ZFile.
 */
public class BankTxnReport {
    private static String reportTitle = "Transaction Report";
    private static int maxRecords = Integer.MAX_VALUE;

    public static void main(String[] args) {
        System.out.println("=== Bank Transaction Report Generator ===");

        // Read configuration from STDIN (control cards)
        readControlCards();

        System.out.println("Title:       " + reportTitle);
        System.out.println("Max Records: " + (maxRecords == Integer.MAX_VALUE ? "ALL" : maxRecords));
        System.out.println();

        // Process transaction data from TXNDATA DD
        processTransactions();

        System.out.println("=== Report Generation Complete ===");
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
                        case "REPORT_TITLE": reportTitle = val; break;
                        case "MAX_RECORDS": maxRecords = Integer.parseInt(val); break;
                        default:
                            System.out.println("  WARN: Unknown parameter: " + key);
                    }
                }
            }
        } catch (Exception e) {
            // STDIN may be DUMMY or empty - that's OK
            System.out.println("  (No control cards provided, using defaults)");
        }
    }

    private static void processTransactions() {
        ZFile zFile = null;
        try {
            zFile = new ZFile("//DD:TXNDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];
            int bytesRead;
            int count = 0;

            System.out.println("--- " + reportTitle + " ---");
            System.out.printf("%-12s %-10s %-8s %-6s %-12s%n",
                "TXN-ID", "DATE", "ACCT-ID", "TYPE", "AMOUNT");
            System.out.println(
                "------------ ---------- -------- ------ ------------");

            while ((bytesRead = zFile.read(record)) >= 0 && count < maxRecords) {
                count++;
                String txnId = new String(record, 0, 9).trim();
                String date = new String(record, 9, 10).trim();
                String acctId = new String(record, 19, 9).trim();
                String txnType = new String(record, 28, 3).trim();
                String amount = new String(record, 31, 12).trim();

                System.out.printf("%-12s %-10s %-8s %-6s %-12s%n",
                    txnId, date, acctId, txnType, amount);
            }

            System.out.println();
            System.out.printf("Total transactions listed: %d%n", count);
        } catch (Exception e) {
            System.err.println("ERROR processing transactions: " + e.getMessage());
            e.printStackTrace(System.err);
            throw new RuntimeException("Fatal error");
        } finally {
            if (zFile != null) {
                try { zFile.close(); } catch (Exception ignored) {}
            }
        }
    }
}
