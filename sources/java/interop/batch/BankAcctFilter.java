import com.rocketsoftware.jzos.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

/**
 * Demonstrates JVMLDM batch processing with MAINARGS DD.
 * Reads bank account data and filters by a regex pattern
 * supplied via MAINARGS.
 *
 * Usage via JCL Procedure:
 *   //STEP00   EXEC PROC=JVMPRC86,
 *   //             JAVACLS='BankAcctFilter'
 *   //MAINARGS  DD *
 *   'MFI01V.MFIDEMO.BNKACC' '[0-9]{5}'
 *   /*
 *
 * MAINARGS format: 'dataset_name' 'filter_regex'
 *   arg[0] = Dataset name to read
 *   arg[1] = Regex pattern to filter account IDs
 */
public class BankAcctFilter {
    public static void main(String[] args) {
        System.out.println("=== Bank Account Filter ===");
        System.out.println("Arguments received: " + args.length);

        for (int i = 0; i < args.length; i++) {
            System.out.println("  arg[" + i + "] = " + args[i]);
        }

        if (args.length < 1) {
            System.err.println("ERROR: Missing dataset name argument");
            System.err.println("Usage: BankAcctFilter <dataset> [filter_regex]");
            throw new RuntimeException("Fatal error");
        }

        String datasetName = args[0];
        String filterPattern = args.length > 1 ? args[1] : ".*";

        System.out.println("Dataset: " + datasetName);
        System.out.println("Filter:  " + filterPattern);
        System.out.println();

        Pattern regex = Pattern.compile(filterPattern);
        processAccounts(datasetName, regex);

        System.out.println("=== Filter Complete. RC=0 ===");
    }

    private static void processAccounts(String datasetName, Pattern filter) {
        String ddPath = "//'" + datasetName + "'";
        ZFile zFile = null;
        try {
            zFile = new ZFile(ddPath, "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];
            int bytesRead;
            int total = 0;
            int matched = 0;

            System.out.printf("%-12s %-8s %-6s %-12s%n",
                "ACCOUNT-ID", "CUST-ID", "TYPE", "BALANCE");
            System.out.println("------------ -------- ------ ------------");

            while ((bytesRead = zFile.read(record)) >= 0) {
                total++;
                String accountId = new String(record, 0, 9).trim();
                String custId = new String(record, 9, 5).trim();
                String accountType = new String(record, 14, 1).trim();
                String balance = new String(record, 15, 12).trim();

                Matcher m = filter.matcher(accountId);
                if (m.find()) {
                    matched++;
                    System.out.printf("%-12s %-8s %-6s %-12s%n",
                        accountId, custId, accountType, balance);
                }
            }

            System.out.println();
            System.out.printf("Records read: %d, Matched: %d%n", total, matched);
        } catch (Exception e) {
            System.err.println("ERROR reading dataset: " + e.getMessage());
            e.printStackTrace(System.err);
            throw new RuntimeException("Fatal error");
        } finally {
            if (zFile != null) {
                try { zFile.close(); } catch (Exception ignored) {}
            }
        }
    }
}
