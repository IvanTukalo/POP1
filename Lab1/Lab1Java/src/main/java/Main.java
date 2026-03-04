import java.math.BigInteger;
import java.util.Scanner;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Comparator;
import java.util.concurrent.atomic.AtomicBoolean;

public class Main {
    public static void main(String[] args) {
        System.setOut(new PrintStream(System.out, true, StandardCharsets.UTF_8));
        Scanner scanner = new Scanner(System.in, StandardCharsets.UTF_8);

        while (true) {
            int step = 0;
            while (true) {
                System.out.println("Введіть крок роботи потоків (0 для виходу)");
                String stepInput = scanner.nextLine();
                try {
                    step = Integer.parseInt(stepInput.trim());
                    if (step == 0) {
                        System.out.println("Програма завершує роботу.");
                        return;
                    }
                    if (step > 0) {
                        break;
                    }
                } catch (NumberFormatException e) {

                }
                System.out.println("Помилка вводу. Будь ласка, введіть ціле додатне число або 0 для виходу.");
            }

            int[] times;
            while (true) {
                System.out.println("Введіть час роботи потоків у секундах через пробіл");
                String input = scanner.nextLine();

                if (input == null || input.trim().isEmpty()) {
                    continue;
                }

                String[] timesStr = input.trim().split("\\s+");
                times = new int[timesStr.length];
                boolean allValid = true;

                for (int i = 0; i < timesStr.length; i++) {
                    try {
                        times[i] = Integer.parseInt(timesStr[i]);
                        if (times[i] <= 0) {
                            allValid = false;
                            break;
                        }
                    } catch (NumberFormatException e) {
                        allValid = false;
                        break;
                    }
                }

                if (allValid) {
                    break;
                }
                System.out.println("Помилка вводу. Переконайтеся, що ви ввели лише цілі додатні числа через пробіл.");
            }

            int numThreads = times.length;
            int maxTime = 0;
            for (int t : times) {
                if (t > maxTime) {
                    maxTime = t;
                }
            }

            AtomicBoolean[] stopFlags = new AtomicBoolean[numThreads];
            Thread[] threads = new Thread[numThreads];

            for (int i = 0; i < numThreads; i++) {
                stopFlags[i] = new AtomicBoolean(false);
                final int localIndex = i;
                final int timeLimit = times[i];
                final int threadId = i + 1;
                final int currentStep = step;

                threads[i] = new Thread(() -> {
                    BigInteger sum = BigInteger.ZERO;
                    BigInteger elementsCount = BigInteger.ZERO;
                    BigInteger stepBig = BigInteger.valueOf(currentStep);

                    while (!stopFlags[localIndex].get()) {
                        sum = sum.add(stepBig);
                        elementsCount = elementsCount.add(BigInteger.ONE);
                    }

                    System.out.println(threadId + " - " + sum + ", " + currentStep + " - " + elementsCount + " разів за " + timeLimit + " сек.");
                });
                threads[i].start();
            }

            final int[] finalTimes = times;
            Thread masterStopper = new Thread(() -> {
                int[][] events = new int[numThreads][2];
                for (int i = 0; i < numThreads; i++) {
                    events[i][0] = finalTimes[i];
                    events[i][1] = i;
                }
                Arrays.sort(events, Comparator.comparingInt(a -> a[0]));

                int elapsed = 0;
                for (int i = 0; i < numThreads; i++) {
                    int sleepTime = events[i][0] - elapsed;
                    if (sleepTime > 0) {
                        try {
                            Thread.sleep(sleepTime * 1000L);
                        } catch (InterruptedException e) {
                            Thread.currentThread().interrupt();
                        }
                        elapsed += sleepTime;
                    }
                    stopFlags[events[i][1]].set(true);
                }
            });
            masterStopper.start();

            try {
                Thread.sleep((maxTime + 1) * 1000L);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

            System.out.println("Усі потоки завершили роботу. Починаємо новий цикл.");
            System.out.println();
        }
    }
}