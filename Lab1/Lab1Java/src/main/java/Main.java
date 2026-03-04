import java.math.BigInteger;
import java.util.Scanner;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;

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
            WorkerThread[] workers = new WorkerThread[numThreads];
            Thread[] stoppers = new Thread[numThreads];

            for (int i = 0; i < numThreads; i++) {
                int timeLimit = times[i];
                workers[i] = new WorkerThread(i + 1, step, timeLimit);
                final WorkerThread worker = workers[i];

                stoppers[i] = new Thread(() -> {
                    try {
                        Thread.sleep(timeLimit * 1000L);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                    worker.stopThread();
                });
            }

            for (int i = 0; i < numThreads; i++) {
                workers[i].start();
                stoppers[i].start();
            }

            int maxTime = 0;
            for (int t : times) {
                if (t > maxTime) {
                    maxTime = t;
                }
            }

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

class WorkerThread extends Thread {
    private final int id;
    private final int step;
    private final int timeLimit;
    private volatile boolean canStop = false;

    public WorkerThread(int id, int step, int timeLimit) {
        this.id = id;
        this.step = step;
        this.timeLimit = timeLimit;
    }

    public void stopThread() {
        this.canStop = true;
    }

    @Override
    public void run() {
        BigInteger sum = BigInteger.ZERO;
        BigInteger elementsCount = BigInteger.ZERO;
        BigInteger stepBig = BigInteger.valueOf(step);

        while (!canStop) {
            sum = sum.add(stepBig);
            elementsCount = elementsCount.add(BigInteger.ONE);
        }

        System.out.println(id + " - " + sum + ", " + step + " - " + elementsCount + " разів за " + timeLimit + " сек.");
    }
}