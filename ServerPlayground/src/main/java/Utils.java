import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * Created by barthap on 2019-03-11.
 */
public class Utils {
    private static final char[] _nibbleToHex = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };

    static byte[] intToByteArrayLittleEndian(int value, int arrayLength) {

       /* byte[] array = new byte[arrayLength];
        for(int i = 0; i < arrayLength; i++) {
            array[i] = (byte)(value >>> (8*i));
        }
        return array;*/
       return ByteBuffer.allocate(arrayLength).order(ByteOrder.LITTLE_ENDIAN).putInt(value).array();
    }

    static int byteArrayToIntLittleEndian(byte[] array) {
        return ByteBuffer.wrap(array).order(ByteOrder.LITTLE_ENDIAN).getInt();
        /*int value = 0;
        for (int i = 0; i < array.length; i++) {
            value |= (array[i] << (8*i));
        }
        return value;*/
    }

    static String readline(InputStream stream) throws IOException {
        int ch;
        StringBuilder sb = new StringBuilder();
        while ((ch = stream.read()) != '\n') {
            sb.append((char)ch);
        }
        return sb.toString();
    }

    private static String toHex(char[] code) {
        StringBuilder result = new StringBuilder(3 * code.length);

        for (char c : code) {
            int b = c & 0xFF;
            result.append(_nibbleToHex[b >>> 4]);
            result.append(_nibbleToHex[b % 16]);
            result.append(' ');
        }

        return result.toString();
    }

    static String toHex(byte[] code) {
        StringBuilder result = new StringBuilder(3 * code.length);

        for (byte c : code) {
            int b = c & 0xFF;
            result.append(_nibbleToHex[b >>> 4]);
            result.append(_nibbleToHex[b % 16]);
            result.append(' ');
        }

        return result.toString();
    }

    private static byte[] charArrayToByteArray(char[] chAr) {
        byte[] bytes = new byte[chAr.length];
        for(int i = 0; i < chAr.length; i++)
            bytes[i] = (byte)chAr[i];
        return bytes;
    }
}
