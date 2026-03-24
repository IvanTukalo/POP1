import java.util.Random;

public class Main {

    private final int dim = 2000000000;
    private int[] arr;

    private int completedThreads;
    private final Object locker = new Object();

    public static void main(String[] args) {
        Main program = new Main();
        program.run();
    }

    public void run() {
        System.out.println("Генерація масиву...");
        arr = new int[dim];
        Random rnd = new Random();

        for (int i = 0; i < dim; i++) {
            arr[i] = rnd.nextInt(100) + 1;
        }

        int randomIndex = rnd.nextInt(dim);
        int minV = -1;
        arr[randomIndex] = minV;
        System.out.println("Масив згенеровано.");

        long startTime = System.currentTimeMillis();

        int[] seqResult = findMinInRange(0, dim);

        long sequentialTimeMs = System.currentTimeMillis() - startTime;
        System.out.println("Послідовний пошук: знайдено значення " + seqResult[0] + " (індекс " + seqResult[1] + "), за " + sequentialTimeMs + " мс");

        long fastestTimeMs = Long.MAX_VALUE;
        int fastestThreadCount = 0;

        for (int treadNumber = 2; treadNumber <= 20; treadNumber += 2) {

            completedThreads = 0;
            int[][] results = new int[treadNumber][2];
            int chunkSize = dim / treadNumber;

            startTime = System.currentTimeMillis();

            for (int i = 0; i < treadNumber; i++) {
                final int start = i * chunkSize;
                final int end = (i == treadNumber - 1) ? dim : start + chunkSize;
                final int localThreadIndex = i;

                Thread thread = new Thread(() -> {
                    // 1. Абсолютно чисте обчислення без блокувань
                    results[localThreadIndex] = findMinInRange(start, end);

                    // 2. Сигналізація про завершення роботи потоку
                    synchronized (locker) {
                        completedThreads++;
                        locker.notify();
                    }
                });

                thread.start();
            }

            // Головний потік чекає на сигнали від усіх дочірніх потоків
            synchronized (locker) {
                while (completedThreads < treadNumber) {
                    try {
                        locker.wait();
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                }
            }

            // Агрегація результатів після того, як всі відзвітували
            int globalMin = Integer.MAX_VALUE;
            int globalMinIndex = -1;

            for (int i = 0; i < treadNumber; i++) {
                if (results[i][0] < globalMin) {
                    globalMin = results[i][0];
                    globalMinIndex = results[i][1];
                }
            }

            long currentElapsed = System.currentTimeMillis() - startTime;

            if (currentElapsed < fastestTimeMs) {
                fastestTimeMs = currentElapsed;
                fastestThreadCount = treadNumber;
            }

            System.out.println(treadNumber + " потоки(ів) знайшли мінімальний елемент: значення " + globalMin + " (індекс " + globalMinIndex + "), за " + currentElapsed + " мс");
        }

        double speedup = (double) sequentialTimeMs / fastestTimeMs;
        System.out.printf("Пошук з %d потоками найшвидший – %d мс в %.2fx швидше", fastestThreadCount, fastestTimeMs, speedup);
    }

    // Чистий метод пошуку (тільки обчислення)
    private int[] findMinInRange(int startIndex, int endIndex) {
        int localMin = Integer.MAX_VALUE;
        int localMinIndex = -1;

        for (int i = startIndex; i < endIndex; i++) {
            if (arr[i] < localMin) {
                localMin = arr[i];
                localMinIndex = i;
            }
        }

        return new int[]{localMin, localMinIndex};
    }
}