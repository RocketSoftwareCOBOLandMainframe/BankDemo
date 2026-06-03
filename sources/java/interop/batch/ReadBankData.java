import com.rocketsoftware.jzos.*;

/**
 * Reads bank account data from a dataset allocated via JCL DD.
 * Demonstrates using ZFile to access VSAM/sequential datasets
 * from Java in a batch environment.
 */
public class ReadBankData {
    public static void main(String[] args) {
        if(args.length != 1) {
            throw new IllegalArgumentException("Number of passed arguments do not meet the minimum of 1.");
        }

        int recordsToShow = Integer.parseInt(args[0]); // Can throw if argument is not args[0] a parsable integer.

        System.out.println("=== Reading Bank Account Data ===");
        readAccountFile(recordsToShow);
        System.out.println("=== Complete ===");
    }

    public static void readAccountFile(int displayN) {
        // Open the dataset allocated to DD name ACCDATA
        ZFile zFile = new ZFile("//DD:ACCDATA", "rb,type=record");

        try {
            byte[] record = new byte[zFile.getLrecl()];
            int bytesRead;
            int count = 0;

            while ((bytesRead = zFile.read(record)) >= 0) {
                // Extract fields from fixed-length record
                String accountId = new String(record, 0, 9).trim();
                String custId = new String(record, 9, 5).trim();
                String accountType = new String(record, 14, 1).trim();

                count++;
                if (count <= displayN) {
                    System.out.printf("  Account: %s  Customer: %s  Type: %s%n", accountId, custId, accountType);

                    if (count == displayN) {
                        System.out.println("  ... (showing first " + displayN + " records)");
                    }
                }
            }

            System.out.printf("  Total records: %d%n", count);
        } finally {
            zFile.close();
        }
    }
}