import com.rocketsoftware.jzos.*;
import java.util.*;

/**
 * Step 10: JSON/API-Ready Data Export Pipeline
 *
 * Transforms BankDemo VSAM data into structured JSON output.
 * This represents the "modernization bridge" pattern — where legacy
 * batch data is made accessible to REST APIs, data lakes, or
 * event-driven architectures without touching the COBOL source.
 *
 * Output formats:
 *   JSON_LINES - One JSON object per line (for streaming/Kafka)
 *   JSON_ARRAY - Wrapped in array (for REST API bulk endpoints)
 *   NDJSON     - Newline-delimited JSON (for jq, data pipelines)
 *
 * When entity_type is SCHEMA_ONLY, outputs the JSON Schema
 * definition instead of data — useful for API contract validation.
 *
 * Uses ZUtil.getEnv() to read export metadata from STDENV.
 */
public class BankJsonExport {

    private static String entityType = "FULL";
    private static String format = "JSON_LINES";
    private static int maxRecords = Integer.MAX_VALUE;
    private static String exportVersion = "1.0";
    private static String exportTimestamp = "";
    private static boolean includeMetadata = true;

    public static void main(String[] args) {
        // Parse MAINARGS
        if (args.length >= 1) entityType = args[0].toUpperCase();
        if (args.length >= 2) format = args[1].toUpperCase();
        if (args.length >= 3) {
            String maxStr = args[2].toUpperCase();
            maxRecords = maxStr.equals("ALL") ? Integer.MAX_VALUE : Integer.parseInt(maxStr);
        }

        // Read STDENV environment variables
        try {
            String v = ZUtil.getEnv("EXPORT_VERSION");
            if (v != null) exportVersion = v;
            String t = ZUtil.getEnv("EXPORT_TIMESTAMP");
            if (t != null) exportTimestamp = t;
            String m = ZUtil.getEnv("INCLUDE_METADATA");
            if (m != null) includeMetadata = m.equalsIgnoreCase("true");
        } catch (Exception e) {
            exportTimestamp = new Date().toString();
        }

        if (entityType.equals("SCHEMA_ONLY")) {
            outputSchema();
            return;
        }

        System.err.println("BankJsonExport: entity=" + entityType +
            " format=" + format + " max=" +
            (maxRecords == Integer.MAX_VALUE ? "ALL" : maxRecords));

        if (format.equals("JSON_ARRAY")) System.out.println("{");

        if (includeMetadata) {
            outputMetadata();
        }

        boolean first = true;
        if (entityType.equals("FULL") || entityType.equals("CUSTOMERS")) {
            if (format.equals("JSON_ARRAY") && !first) System.out.println(",");
            exportCustomers();
            first = false;
        }
        if (entityType.equals("FULL") || entityType.equals("ACCOUNTS")) {
            if (format.equals("JSON_ARRAY") && !first) System.out.println(",");
            exportAccounts();
            first = false;
        }
        if (entityType.equals("FULL") || entityType.equals("TRANSACTIONS")) {
            if (format.equals("JSON_ARRAY") && !first) System.out.println(",");
            exportTransactions();
        }

        if (format.equals("JSON_ARRAY")) System.out.println("}");

        System.err.println("BankJsonExport: complete RC=0");
    }

    private static void outputMetadata() {
        if (format.equals("JSON_LINES") || format.equals("NDJSON")) {
            System.out.printf("{\"_meta\":{\"version\":\"%s\",\"timestamp\":\"%s\",\"source\":\"BANKDEMO-VSAM\",\"entity\":\"%s\"}}%n",
                exportVersion, exportTimestamp, entityType);
        } else {
            System.out.printf("  \"_meta\": {\"version\":\"%s\",\"timestamp\":\"%s\",\"source\":\"BANKDEMO-VSAM\"},%n",
                exportVersion, exportTimestamp);
        }
    }

    private static void exportCustomers() {
        ZFile zFile = null;
        int count = 0;

        if (format.equals("JSON_ARRAY")) System.out.println("  \"customers\": [");

        try {
            zFile = new ZFile("//DD:CUSTDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];

            while (zFile.read(record) >= 0 && count < maxRecords) {
                count++;
                String pid = new String(record, 0, 5).trim();
                String name = new String(record, 5, 25).trim();
                String nameFF = new String(record, 30, 25).trim();
                String sin = new String(record, 55, 9).trim();
                String addr1 = new String(record, 64, 25).trim();
                String addr2 = new String(record, 89, 25).trim();
                String state = new String(record, 114, 2).trim();
                String country = new String(record, 116, 6).trim();
                String postCode = new String(record, 122, 6).trim();
                String phone = new String(record, 128, 12).trim();
                String email = new String(record, 140, 30).trim();

                String json = String.format(
                    "{\"type\":\"customer\",\"pid\":\"%s\",\"name\":\"%s\",\"sortName\":\"%s\"," +
                    "\"address\":{\"line1\":\"%s\",\"line2\":\"%s\",\"state\":\"%s\"," +
                    "\"country\":\"%s\",\"postCode\":\"%s\"},\"contact\":{\"phone\":\"%s\",\"email\":\"%s\"}}",
                    escJson(pid), escJson(name), escJson(nameFF),
                    escJson(addr1), escJson(addr2), escJson(state),
                    escJson(country), escJson(postCode),
                    escJson(phone), escJson(email));

                if (format.equals("JSON_ARRAY")) {
                    System.out.print("    " + json);
                    System.out.println(count < maxRecords ? "," : "");
                } else {
                    System.out.println(json);
                }
            }
        } catch (Exception e) {
            System.err.println("ERROR exporting customers: " + e.getMessage());
            throw new RuntimeException("Fatal error");
        } finally {
            if (zFile != null) zFile.close();
        }

        if (format.equals("JSON_ARRAY")) System.out.println("  ],");
        System.err.printf("  Customers exported: %d%n", count);
    }

    private static void exportAccounts() {
        ZFile zFile = null;
        int count = 0;

        if (format.equals("JSON_ARRAY")) System.out.println("  \"accounts\": [");

        try {
            zFile = new ZFile("//DD:ACCTDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];

            while (zFile.read(record) >= 0 && count < maxRecords) {
                count++;
                String pid = new String(record, 0, 5).trim();
                String accNo = new String(record, 5, 9).trim();
                String type = new String(record, 14, 1).trim();
                long balanceCents = decodePackedDecimal(record, 15, 5);
                String lastStmtDate = new String(record, 20, 10).trim();
                long lastStmtBalCents = decodePackedDecimal(record, 30, 5);
                String atmEnabled = new String(record, 35, 2).trim();

                String typeName = type.equals("1") ? "CHECKING" :
                                  type.equals("2") ? "SAVINGS" :
                                  type.equals("3") ? "LOAN" : "OTHER";

                String json = String.format(
                    "{\"type\":\"account\",\"accountNo\":\"%s\",\"customerId\":\"%s\"," +
                    "\"accountType\":\"%s\",\"balance\":%.2f," +
                    "\"lastStatement\":{\"date\":\"%s\",\"balance\":%.2f}," +
                    "\"atm\":{\"enabled\":%s}}",
                    escJson(accNo), escJson(pid), typeName,
                    balanceCents / 100.0, escJson(lastStmtDate),
                    lastStmtBalCents / 100.0,
                    atmEnabled.equalsIgnoreCase("Y") ? "true" : "false");

                if (format.equals("JSON_ARRAY")) {
                    System.out.print("    " + json);
                    System.out.println(count < maxRecords ? "," : "");
                } else {
                    System.out.println(json);
                }
            }
        } catch (Exception e) {
            System.err.println("ERROR exporting accounts: " + e.getMessage());
            throw new RuntimeException("Fatal error");
        } finally {
            if (zFile != null) zFile.close();
        }

        if (format.equals("JSON_ARRAY")) System.out.println("  ],");
        System.err.printf("  Accounts exported: %d%n", count);
    }

    private static void exportTransactions() {
        ZFile zFile = null;
        int count = 0;

        if (format.equals("JSON_ARRAY")) System.out.println("  \"transactions\": [");

        try {
            zFile = new ZFile("//DD:TXNDATA", "rb,type=record");
            byte[] record = new byte[zFile.getLrecl()];

            while (zFile.read(record) >= 0 && count < maxRecords) {
                count++;
                String pid = new String(record, 0, 5).trim();
                String txnType = new String(record, 5, 1).trim();
                String subType = new String(record, 6, 1).trim();
                String accNo = new String(record, 7, 9).trim();
                String timestamp = new String(record, 16, 26).trim();
                long amountCents = decodePackedDecimal(record, 42, 5);

                String txnTypeName = txnType.equals("C") ? "CREDIT" :
                                     txnType.equals("D") ? "DEBIT" :
                                     txnType.equals("T") ? "TRANSFER" : txnType;

                String json = String.format(
                    "{\"type\":\"transaction\",\"accountNo\":\"%s\",\"customerId\":\"%s\"," +
                    "\"txnType\":\"%s\",\"subType\":\"%s\",\"timestamp\":\"%s\"," +
                    "\"amount\":%.2f}",
                    escJson(accNo), escJson(pid), txnTypeName, escJson(subType),
                    escJson(timestamp), amountCents / 100.0);

                if (format.equals("JSON_ARRAY")) {
                    System.out.print("    " + json);
                    System.out.println(count < maxRecords ? "," : "");
                } else {
                    System.out.println(json);
                }
            }
        } catch (Exception e) {
            System.err.println("ERROR exporting transactions: " + e.getMessage());
            throw new RuntimeException("Fatal error");
        } finally {
            if (zFile != null) zFile.close();
        }

        if (format.equals("JSON_ARRAY")) System.out.println("  ]");
        System.err.printf("  Transactions exported: %d%n", count);
    }

    private static void outputSchema() {
        System.out.println("{");
        System.out.println("  \"$schema\": \"https://json-schema.org/draft/2020-12/schema\",");
        System.out.println("  \"title\": \"BankDemo Export Schema v" + exportVersion + "\",");
        System.out.println("  \"description\": \"Schema for VSAM-to-JSON export pipeline\",");
        System.out.println("  \"oneOf\": [");
        System.out.println("    {");
        System.out.println("      \"properties\": {");
        System.out.println("        \"type\": {\"const\": \"customer\"},");
        System.out.println("        \"pid\": {\"type\": \"string\", \"pattern\": \"^[0-9]{5}$\"},");
        System.out.println("        \"name\": {\"type\": \"string\", \"maxLength\": 25},");
        System.out.println("        \"address\": {\"type\": \"object\"},");
        System.out.println("        \"contact\": {\"type\": \"object\"}");
        System.out.println("      }, \"required\": [\"type\",\"pid\",\"name\"]");
        System.out.println("    },");
        System.out.println("    {");
        System.out.println("      \"properties\": {");
        System.out.println("        \"type\": {\"const\": \"account\"},");
        System.out.println("        \"accountNo\": {\"type\": \"string\", \"pattern\": \"^[0-9]{9}$\"},");
        System.out.println("        \"customerId\": {\"type\": \"string\"},");
        System.out.println("        \"accountType\": {\"enum\": [\"CHECKING\",\"SAVINGS\",\"LOAN\",\"OTHER\"]},");
        System.out.println("        \"balance\": {\"type\": \"number\"}");
        System.out.println("      }, \"required\": [\"type\",\"accountNo\",\"customerId\"]");
        System.out.println("    },");
        System.out.println("    {");
        System.out.println("      \"properties\": {");
        System.out.println("        \"type\": {\"const\": \"transaction\"},");
        System.out.println("        \"accountNo\": {\"type\": \"string\"},");
        System.out.println("        \"txnType\": {\"enum\": [\"CREDIT\",\"DEBIT\",\"TRANSFER\"]},");
        System.out.println("        \"amount\": {\"type\": \"number\"}");
        System.out.println("      }, \"required\": [\"type\",\"accountNo\",\"txnType\",\"amount\"]");
        System.out.println("    }");
        System.out.println("  ]");
        System.out.println("}");
        System.err.println("Schema output complete. RC=0");
    }

    /** Escape a string for safe JSON embedding. */
    private static String escJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
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
}
