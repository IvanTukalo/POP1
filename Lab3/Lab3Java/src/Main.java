import java.util.Scanner;
import java.util.concurrent.Semaphore;
import java.util.Random;

public class Main {

    private Semaphore accessMutex;
    private Semaphore emptySlots;
    private Semaphore filledSlots;

    private int currentStorageCount;
    private int globalConsumed;
    private int totalItems;
    private int numConsumers;

    public static void main(String[] args) {
        Main program = new Main();
        program.run();
    }

    public void run() {
        Scanner scanner = new Scanner(System.in);

        while (true) {
            currentStorageCount = 0;
            globalConsumed = 0;
            totalItems = 0;
            numConsumers = 0;

            int numProducers = 0;
            int capacity = 0;
            int[] producerItems;

            System.out.println("Оберіть режим роботи (1 - Випадкова генерація, 2 - Ручне введення)");
            int mode = 0;
            while (true) {
                String input = scanner.nextLine().trim();
                try {
                    mode = Integer.parseInt(input);
                    if (mode == 0 || mode == 1 || mode == 2) {
                        break;
                    }
                } catch (NumberFormatException ignored) {}
                System.out.println("Помилка вводу. Введіть 0, 1 або 2.");
            }

            if (mode == 2) {
                while (true) {
                    System.out.println("Введіть кількість Виробників, Споживачів та максимальну місткість сховища через пробіл");
                    String inputLine = scanner.nextLine().trim();
                    String[] inputs = inputLine.split("\\s+");

                    if (inputs.length == 3) {
                        try {
                            numProducers = Integer.parseInt(inputs[0]);
                            numConsumers = Integer.parseInt(inputs[1]);
                            capacity = Integer.parseInt(inputs[2]);

                            if (numProducers > 0 && numConsumers > 0 && capacity > 0) {
                                break;
                            }
                        } catch (NumberFormatException ignored) {}
                    }
                    System.out.println("Помилка. Необхідно ввести три додатні цілі числа через пробіл.");
                }

                producerItems = new int[numProducers];
                while (true) {
                    System.out.println("Введіть кількість товарів яку створюватимуть Виробники в кількості " + numProducers + " через пробіл");
                    String inputLine = scanner.nextLine().trim();
                    String[] itemsInput = inputLine.split("\\s+");

                    if (itemsInput.length == numProducers) {
                        boolean allValid = true;
                        try {
                            for (int i = 0; i < numProducers; i++) {
                                producerItems[i] = Integer.parseInt(itemsInput[i]);
                                if (producerItems[i] <= 0) {
                                    allValid = false;
                                    break;
                                }
                            }
                            if (allValid) {
                                break;
                            }
                        } catch (NumberFormatException e) {
                            allValid = false;
                        }
                    }
                    System.out.println("Помилка. Необхідно ввести рівно " + numProducers + " додатних цілих чисел.");
                }
            }
            else if (mode == 0) {
                return;
            }
            else {
                Random rnd = new Random();
                numProducers = rnd.nextInt(5) + 1;
                numConsumers = rnd.nextInt(5) + 1;
                capacity = rnd.nextInt(16) + 5;

                producerItems = new int[numProducers];
                for (int i = 0; i < numProducers; i++) {
                    producerItems[i] = rnd.nextInt(50) + 1;
                }
            }

            for (int i = 0; i < numProducers; i++) {
                totalItems += producerItems[i];
            }

            System.out.println();
            System.out.println("Вмістимість сховища - " + capacity);
            System.out.println("Кількість споживачів - " + numConsumers);
            System.out.println("Загальна кількість товарів що будуть створені і спожиті - " + totalItems);
            for (int i = 0; i < numProducers; i++) {
                System.out.println((i + 1) + " виробник - " + producerItems[i] + " товарів");
            }
            System.out.println();

            this.numConsumers = numConsumers;

            // Активація справедливого режиму (FIFO) для всіх семафорів
            accessMutex = new Semaphore(1, true);
            emptySlots = new Semaphore(capacity, true);
            filledSlots = new Semaphore(0, true);

            Thread[] producers = new Thread[numProducers];
            for (int i = 0; i < numProducers; i++) {
                final int localIndex = i + 1;
                final int itemsToProduce = producerItems[i];
                producers[i] = new Thread(() -> produce(localIndex, itemsToProduce));
                producers[i].start();
            }

            Thread[] consumers = new Thread[numConsumers];
            for (int i = 0; i < numConsumers; i++) {
                final int localIndex = i + 1;
                consumers[i] = new Thread(() -> consume(localIndex));
                consumers[i].start();
            }

            try {
                for (int i = 0; i < numProducers; i++) {
                    producers[i].join();
                }
                for (int i = 0; i < numConsumers; i++) {
                    consumers[i].join();
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

            System.out.println("Усі потоки успішно завершили роботу.\n");
        }
    }

    private void produce(int producerIndex, int itemsToProduce) {
        int personalProduced = 0;
        try {
            while (personalProduced < itemsToProduce) {
                emptySlots.acquire();
                accessMutex.acquire();

                currentStorageCount++;
                personalProduced++;

                if (personalProduced == itemsToProduce) {
                    System.out.println(producerIndex + " Виробник завершив свою роботу, створено " + personalProduced + " товарів, заповненість " + currentStorageCount);
                } else {
                    System.out.println(producerIndex + " Виробник поклав свій " + personalProduced + " товар на склад, заповненість " + currentStorageCount);
                }

                accessMutex.release();
                filledSlots.release();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void consume(int consumerIndex) {
        int personalConsumed = 0;
        try {
            while (true) {
                filledSlots.acquire();
                accessMutex.acquire();

                if (globalConsumed >= totalItems) {
                    accessMutex.release();
                    filledSlots.release();
                    break;
                }

                currentStorageCount--;
                globalConsumed++;
                personalConsumed++;

                System.out.println(consumerIndex + " Споживач спожив свій " + personalConsumed + " товар на складі, заповненість " + currentStorageCount);

                boolean finishedAll = (globalConsumed == totalItems);

                accessMutex.release();
                emptySlots.release();

                if (finishedAll) {
                    filledSlots.release(numConsumers);
                    break;
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}