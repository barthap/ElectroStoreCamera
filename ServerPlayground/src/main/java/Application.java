
import javax.jmdns.JmDNS;
import javax.jmdns.ServiceEvent;
import javax.jmdns.ServiceInfo;
import javax.jmdns.ServiceListener;
import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Created by barthap on 2019-02-21.
 */
public class Application implements Runnable, ServiceListener {
    private static final int HEADER_LENGTH = 4;

    public static void main(String[] args) {
        System.out.println("Some testing");
        int n = 1245391901;
        System.out.println("Number: " + n + " hex: 0x4A3B2C1D");
        byte[] b = Utils.intToByteArrayLittleEndian(n, 4);
        System.out.println("Converted to bytes: " + Utils.toHex(b));
        System.out.println("Back to int:" + Utils.byteArrayToIntLittleEndian(b));

        ExecutorService executor = Executors.newSingleThreadExecutor();
        executor.submit(new Application());
        executor.shutdown();
    }

    private static void send(OutputStream out, String message) throws IOException {
        byte[] data = message.getBytes();

        int size = data.length;
        byte[] headerBytes = Utils.intToByteArrayLittleEndian(size, HEADER_LENGTH);



        out.write(headerBytes, 0, HEADER_LENGTH);
        out.flush();
        out.write(data, 0, size);
        out.flush();
    }


    @Override
    public void run() {
        try {
            ServerSocket server = new ServerSocket(0);

            OutputStream output = null;
            boolean _running = true;
            try {
                // Create a JmDNS instance
                JmDNS jmdns = JmDNS.create();
                jmdns.addServiceListener("_hapex._tcp.local.", this);


                // Register a service
                ServiceInfo serviceInfo = ServiceInfo.create("_hapex._tcp.local.", "example", server.getLocalPort(), "description");
                jmdns.registerService(serviceInfo);
                System.out.println(serviceInfo);

                while (_running) {


                    System.out.println("Waiting for connection...");
                    final Socket socket = server.accept();
                    output = socket.getOutputStream();
                    System.out.println("Accepted connection from " + socket.getRemoteSocketAddress().toString());

                    final BufferedInputStream inputStream = new BufferedInputStream(socket.getInputStream());
                    //final BufferedReader br = new BufferedReader(new InputStreamReader(inputStream));

                    send(output, "Hi, I accepted your connection :)\n");

                    int dataSize = 0;
                    int currentSize = 0;
                    byte[] data = null;

                    while (_running) {

                        if (inputStream.available() > 0) {

                            byte[] header = new byte[HEADER_LENGTH];
                            if (inputStream.read(header, 0, HEADER_LENGTH) > 0) {
                                int contentSize = Utils.byteArrayToIntLittleEndian((header));
                                System.out.print("Header contains: ");
                                System.out.println(Utils.toHex(header));
                                System.out.println("Content size: " + contentSize);


                                //BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
                                String line = Utils.readline(inputStream);

                                System.out.println(line);
                                if (line.contains("stop"))
                                    _running = false;
                                if (line.contains("exit"))
                                    break;
                                if (line.contains("raw")) {
                                    dataSize = Integer.parseInt(line.substring(line.indexOf(':')+1));

                                    System.out.println("Next message will be " + dataSize + " bytes of data");

                                    //read header again - this time for binary message
                                    if (inputStream.read(header, 0, HEADER_LENGTH) > 0) {
                                        int imgLen = Utils.byteArrayToIntLittleEndian((header));
                                        System.out.println("According to header, img size: " + imgLen);
                                        assert imgLen == dataSize;
                                    }

                                    String filename = "img.raw";
                                    if(line.contains("jpg"))
                                        filename = "img.jpg";
                                    else if(line.contains("png"))
                                        filename = "img.png";

                                    OutputStream fstream = new FileOutputStream(filename);

                                    data = new byte[dataSize];
                                    currentSize = 0;
                                    int count;

                                    while ((count = inputStream.read(data)) > 0)
                                    {
                                        System.out.println("Received " + count + " bytes of data");

                                        currentSize += count;
                                        //System.out.println(toHex(data));
                                        System.out.println(String.format("Written %d of %d total bytes of data", currentSize, dataSize));

                                        fstream.write(data, 0, count);
                                        fstream.flush();

                                        if(currentSize >= dataSize) {
                                            break;
                                        }
                                    }
                                    System.out.println("Done?");
                                    fstream.close();
                                    send(output,"done\n");

                                }

                                send(output, "Server responded with: " + line + "\n");
                            }

                        }

                    }

                    socket.close();

                }

                System.out.println("Finishing");

                // Unregister all services
                jmdns.unregisterAllServices();
                jmdns.close();

            } catch (Exception e) {
                System.out.println(e.getMessage());
                e.printStackTrace();
            } finally {
                if (output != null) {
                    output.close();
                }

                System.out.println("Closing Socket");
                if (!server.isClosed()) {
                    server.close();
                }
                _running = false;
            }
        } catch (Exception e) {
            System.out.println(e.getMessage());
            e.printStackTrace();
        }
    }

    @Override
    public void serviceAdded(ServiceEvent event) {
        System.out.println("Service added   : " + event.getName() + "." + event.getType());
    }

    @Override
    public void serviceRemoved(ServiceEvent event) {
        System.out.println("Service removed : " + event.getName() + "." + event.getType());
    }

    @Override
    public void serviceResolved(ServiceEvent event) {
        System.out.println("Service resolved: " + event.getName() + "." + event.getType() + "\n" + event.getInfo());
    }

}
