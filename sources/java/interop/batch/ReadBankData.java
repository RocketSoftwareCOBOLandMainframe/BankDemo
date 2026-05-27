import com.rocketsoftware.jzos.*;

/**
 * Reads bank account data from a dataset allocated via JCL DD.
 * Demonstrates using ZFile to access VSAM/sequential datasets
 * from Java in a batch environment.
 *
 * Usage: CALL "Java.ReadBankData.run" from COBOL
 *        Requires DD ACCDATA to be allocated in the JCL.
 */
class ReadBankData {
    public static void run() {
        System.setProperty("com.microfocus.cobol.allowLoadLibrary", "true");

        System.out.println("=== Reading Bank Account Data ===");
        readAccountFile();
        System.out.println("=== Complete ===");
    }

    private static void readAccountFile() {
        ZFile zFile = new ZFile("//DD:ACCDATA", "rb,type=record");
        try {
            byte[] record = new byte[zFile.getLrecl()];
            int bytesRead;
            int count = 0;

            while ((bytesRead = zFile.read(record)) >= 0) {
                count++;
                String accountId = new String(record, 0, 9).trim();
                String custId = new String(record, 9, 5).trim();
                String accountType = new String(record, 14, 1).trim();

                System.out.printf("  Account: %s  Customer: %s  Type: %s%n",
                    accountId, custId, accountType);

                if (count >= 5) {
                    System.out.println("  ... (showing first 5 records)");
                    break;
                }
            }

            System.out.printf("  Total records shown: %d%n", count);
        } finally {
            zFile.close();
        }
    }
}
