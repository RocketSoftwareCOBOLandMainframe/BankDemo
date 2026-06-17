import com.rocketsoftware.jzos.*;
import java.util.Arrays;

/**
 * Demonstrates VSAM KSDS operations on the BankDemo customer dataset.
 *
 * Operations:
 *   LOOKUP  <custId>          - Locate and display a single customer by key
 *   BROWSE  <startKey> <count> - Browse records starting from a key
 *   UPDATE  <custId>          - Locate a customer and toggle the SendMail flag
 *
 * Dataset: MFI01V.MFIDEMO.BNKCUST (KSDS, key at offset 0, length 5)
 *
 * Usage via JVMLDM:
 *   PARM='... VsamAccountOps LOOKUP B0001'
 *   PARM='... VsamAccountOps BROWSE B0001 10'
 *   PARM='... VsamAccountOps UPDATE B0001'
 */
public class VsamAccountOps {

    // BNKCUST record layout (from CBANKVCS.CPY)
    private static final int REC_LEN = 250;
    private static final int PID_OFF = 0,        PID_LEN = 5;
    private static final int NAME_OFF = 5,       NAME_LEN = 25;
    private static final int NAMEFF_OFF = 30,    NAMEFF_LEN = 25;
    private static final int SIN_OFF = 55,       SIN_LEN = 9;
    private static final int ADDR1_OFF = 64,     ADDR1_LEN = 25;
    private static final int ADDR2_OFF = 89,     ADDR2_LEN = 25;
    private static final int STATE_OFF = 114,    STATE_LEN = 2;
    private static final int COUNTRY_OFF = 116,  COUNTRY_LEN = 6;
    private static final int POSTCODE_OFF = 122, POSTCODE_LEN = 6;
    private static final int TEL_OFF = 128,      TEL_LEN = 12;
    private static final int EMAIL_OFF = 140,    EMAIL_LEN = 30;
    private static final int SENDMAIL_OFF = 170, SENDMAIL_LEN = 1;
    private static final int SENDEMAIL_OFF = 171, SENDEMAIL_LEN = 1;

    private static final String SEPARATOR = "-".repeat(60);

    public static void main(String[] args) {
        try {
            run(args);
        } catch (Throwable t) {
            System.err.println("FATAL: " + t.getClass().getName() + ": " + t.getMessage());
            t.printStackTrace(System.err);
            System.exit(16);
        }
    }

    private static void run(String[] args) throws ZFileException {
        if (args.length < 1) {
            System.err.println("ERROR: Missing operation (LOOKUP, BROWSE, or UPDATE)");
            System.exit(12);
        }

        String op = args[0].toUpperCase();
        System.err.printf("Job: %s  Step: %s  Operation: %s%n",
            ZUtil.getCurrentJobname(), ZUtil.getCurrentStepname(), op);
        System.err.printf("DEBUG: args.length=%d  args=%s%n", args.length, Arrays.toString(args));

        switch (op) {
            case "LOOKUP":
                if (args.length < 2) {
                    System.err.println("ERROR: LOOKUP requires a customer ID argument");
                    System.exit(12);
                }
                doLookup(args[1]);
                break;
            case "BROWSE":
                String startKey = args.length > 1 ? args[1] : "";
                int count = args.length > 2 ? Integer.parseInt(args[2]) : 10;
                doBrowse(startKey, count);
                break;
            case "UPDATE":
                if (args.length < 2) {
                    System.err.println("ERROR: UPDATE requires a customer ID argument");
                    System.exit(12);
                }
                doUpdate(args[1]);
                break;
            default:
                System.err.println("ERROR: Unknown operation '" + op + "'");
                System.exit(12);
        }
    }

    // -------------------------------------------------------------------------
    // LOOKUP: Locate a single record by primary key (customer ID)
    // -------------------------------------------------------------------------

    private static void doLookup(String custId) throws ZFileException {
        System.out.println("=== VSAM LOOKUP ===");
        System.out.println("Searching for customer: '" + custId + "' (length=" + custId.length() + ")");
        System.out.println(SEPARATOR);

        System.err.printf("LOOKUP: custId='%s' len=%d bytes=%s%n",
            custId, custId.length(), Arrays.toString(custId.getBytes()));

        ZFile vsam = new ZFile("//DD:CUSTDATA", "type=record,rb");
        try {
            System.err.printf("LOOKUP: Opened. VsamType=%d  KeyLen=%d  LRECL=%d%n",
                vsam.getVsamType(), vsam.getVsamKeyLength(), vsam.getLrecl());

            byte[] key = makeKey(custId, vsam.getVsamKeyLength());
            System.err.printf("LOOKUP: key bytes=%s (len=%d)%n", Arrays.toString(key), key.length);

            boolean found = vsam.locate(key, ZFileConstants.LOCATE_KEY_EQ);
            System.err.printf("LOOKUP: locate(KEY_EQ) returned %b%n", found);

            if (found) {
                byte[] record = new byte[vsam.getLrecl()];
                int bytesRead = vsam.read(record);
                System.err.printf("LOOKUP: read() returned %d bytes%n", bytesRead);
                System.err.printf("LOOKUP: record[0..40]='%s'%n",
                    new String(record, 0, Math.min(40, bytesRead)));
                System.err.printf("LOOKUP: record hex[0..20]=%s%n", bytesToHex(record, 0, 20));
                if (bytesRead >= 0) {
                    printCustomerRecord(record);
                } else {
                    System.out.println("  Record not found (read returned " + bytesRead + ")");
                }
            } else {
                System.out.println("  Record not found for key: " + custId);
                // Try KEY_GE as fallback diagnostic
                boolean geFound = vsam.locate(key, ZFileConstants.LOCATE_KEY_GE);
                System.err.printf("LOOKUP: locate(KEY_GE) returned %b%n", geFound);
                if (geFound) {
                    byte[] record = new byte[vsam.getLrecl()];
                    int bytesRead = vsam.read(record);
                    System.err.printf("LOOKUP: GE read %d bytes, first 40='%s'%n",
                        bytesRead, new String(record, 0, Math.min(40, bytesRead)));
                }
            }
        } finally {
            vsam.close();
        }

        System.out.println(SEPARATOR);
    }

    // -------------------------------------------------------------------------
    // BROWSE: Sequential read starting from a key (KEY_GE)
    // -------------------------------------------------------------------------

    private static void doBrowse(String startKey, int maxCount) throws ZFileException {
        System.out.println("=== VSAM BROWSE ===");
        System.out.printf("Start key: '%s'  Max records: %d%n", startKey, maxCount);
        System.out.println(SEPARATOR);
        System.out.printf("  %-5s  %-25s  %-12s  %-30s  %s%n",
            "PID", "Name", "Phone", "Email", "Mail");
        System.out.println("  " + "-".repeat(80));

        ZFile vsam = new ZFile("//DD:CUSTDATA", "type=record,rb");
        try {
            System.err.printf("BROWSE: Opened. VsamType=%d  KeyLen=%d  LRECL=%d%n",
                vsam.getVsamType(), vsam.getVsamKeyLength(), vsam.getLrecl());
            if (!startKey.isEmpty()) {
                byte[] key = makeKey(startKey, vsam.getVsamKeyLength());
                System.err.printf("BROWSE: locate KEY_GE key=%s%n", Arrays.toString(key));
                boolean found = vsam.locate(key, ZFileConstants.LOCATE_KEY_GE);
                System.err.printf("BROWSE: locate returned %b%n", found);
            } else {
                byte[] key = new byte[vsam.getVsamKeyLength()];
                System.err.printf("BROWSE: locate KEY_FIRST key=%s%n", Arrays.toString(key));
                boolean found = vsam.locate(key, ZFileConstants.LOCATE_KEY_FIRST);
                System.err.printf("BROWSE: locate returned %b%n", found);
            }

            byte[] record = new byte[vsam.getLrecl()];
            int count = 0;

            while (vsam.read(record) >= 0 && count < maxCount) {
                if (count == 0) {
                    System.err.printf("BROWSE: first record hex[0..20]=%s%n", bytesToHex(record, 0, 20));
                    System.err.printf("BROWSE: first record text[0..40]='%s'%n",
                        new String(record, 0, Math.min(40, record.length)));
                }
                String pid = field(record, PID_OFF, PID_LEN);
                String name = field(record, NAME_OFF, NAME_LEN);
                String tel = field(record, TEL_OFF, TEL_LEN);
                String email = field(record, EMAIL_OFF, EMAIL_LEN);
                String sendMail = field(record, SENDMAIL_OFF, SENDMAIL_LEN);

                System.out.printf("  %-5s  %-25s  %-12s  %-30s  %s%n",
                    pid, name, tel, email, sendMail);
                count++;
            }

            System.out.println("  " + "-".repeat(80));
            System.out.printf("  Browsed %d records%n", count);
            System.err.printf("BROWSE: returned %d records from key '%s'%n", count, startKey);
        } catch (ZFileException e) {
            System.out.println("  No records found from key: " + startKey);
            System.err.println("BROWSE exception: " + e);
            e.printStackTrace(System.err);
        } finally {
            vsam.close();
        }

        System.out.println(SEPARATOR);
    }

    // -------------------------------------------------------------------------
    // UPDATE: Locate a record and toggle the SendMail flag
    // -------------------------------------------------------------------------

    private static void doUpdate(String custId) throws ZFileException {
        System.out.println("=== VSAM UPDATE ===");
        System.out.println("Updating customer: " + custId);
        System.out.println(SEPARATOR);

        System.err.printf("UPDATE: custId='%s' len=%d%n", custId, custId.length());

        ZFile vsam = new ZFile("//DD:CUSTDATA", "type=record,rb+");
        try {
            System.err.printf("UPDATE: Opened. VsamType=%d  KeyLen=%d  LRECL=%d%n",
                vsam.getVsamType(), vsam.getVsamKeyLength(), vsam.getLrecl());
            byte[] key = makeKey(custId, vsam.getVsamKeyLength());
            System.err.printf("UPDATE: key bytes=%s%n", Arrays.toString(key));
            boolean found = vsam.locate(key, ZFileConstants.LOCATE_KEY_EQ);
            System.err.printf("UPDATE: locate(KEY_EQ) returned %b%n", found);

            if (!found) {
                System.out.println("  Record not found for key: " + custId);
                return;
            }

            byte[] record = new byte[vsam.getLrecl()];
            int bytesRead = vsam.read(record);
            System.err.printf("UPDATE: read() returned %d bytes%n", bytesRead);
            System.err.printf("UPDATE: record[0..40]='%s'%n",
                new String(record, 0, Math.min(40, bytesRead >= 0 ? bytesRead : 0)));

            System.out.println("  Before update:");
            printCustomerRecord(record);

            // Toggle SendMail: "Y" <-> "N"
            String currentMail = field(record, SENDMAIL_OFF, SENDMAIL_LEN);
            String newMail = currentMail.equals("Y") ? "N" : "Y";
            System.arraycopy(newMail.getBytes(), 0, record, SENDMAIL_OFF, SENDMAIL_LEN);

            vsam.update(record, 0, record.length);
            System.err.printf("UPDATE: update() completed successfully%n");

            System.out.println("  After update:");
            printCustomerRecord(record);
            System.err.printf("UPDATE: Toggled SendMail: '%s' -> '%s'%n", currentMail, newMail);
        } catch (ZFileException e) {
            System.out.println("  Update failed: " + e.getMessage());
            System.err.println("UPDATE exception: " + e);
            e.printStackTrace(System.err);
        } finally {
            vsam.close();
        }

        System.out.println(SEPARATOR);
    }

    // -------------------------------------------------------------------------
    // Utilities
    // -------------------------------------------------------------------------

    private static void printCustomerRecord(byte[] record) {
        String pid = field(record, PID_OFF, PID_LEN);
        String name = field(record, NAME_OFF, NAME_LEN);
        String addr1 = field(record, ADDR1_OFF, ADDR1_LEN);
        String state = field(record, STATE_OFF, STATE_LEN);
        String postcode = field(record, POSTCODE_OFF, POSTCODE_LEN);
        String tel = field(record, TEL_OFF, TEL_LEN);
        String email = field(record, EMAIL_OFF, EMAIL_LEN);
        String sendMail = field(record, SENDMAIL_OFF, SENDMAIL_LEN);
        String sendEmail = field(record, SENDEMAIL_OFF, SENDEMAIL_LEN);

        System.out.printf("  PID: %s  Name: %s%n", pid, name);
        System.out.printf("  Address: %s, %s %s%n", addr1, state, postcode);
        System.out.printf("  Phone: %s  Email: %s%n", tel, email);
        System.out.printf("  SendMail: %s  SendEmail: %s%n", sendMail, sendEmail);
    }

    private static String field(byte[] record, int offset, int length) {
        return new String(record, offset, length).trim();
    }

    private static byte[] makeKey(String value, int keyLength) {
        byte[] key = new byte[keyLength];
        byte[] src = value.getBytes();
        System.arraycopy(src, 0, key, 0, Math.min(src.length, keyLength));
        return key;
    }

    private static String bytesToHex(byte[] data, int offset, int length) {
        StringBuilder sb = new StringBuilder();
        int end = Math.min(offset + length, data.length);
        for (int i = offset; i < end; i++) {
            sb.append(String.format("%02X ", data[i] & 0xFF));
        }
        return sb.toString().trim();
    }
}
