import java.util.Scanner;
import java.util.concurrent.Semaphore;

public class Main {

    public static void main(String[] args) {
        Main program = new Main();
        program.run();
    }

    public void run() {
        Scanner scanner = new Scanner(System.in);
        while (true) {
            System.out.println("Оберіть метод вирішення проблеми взаємного блокування");
            System.out.println("1 - Асиметричний філософ (зміна порядку вилок для 5-го)");
            System.out.println("2 - Обмеження доступу (не більше 4 філософів за столом)");
            System.out.println("3 - Офіціанти (лише 2 філософи можуть їсти одночасно)");
            System.out.println("4 - Відмова від очікування (покласти вилку, якщо друга зайнята)");
            System.out.println("0 - Вихід");

            int mode = -1;
            while (true) {
                String input = scanner.nextLine().trim();
                try {
                    mode = Integer.parseInt(input);
                    if (mode >= 0 && mode <= 4) {
                        break;
                    }
                } catch (NumberFormatException ignored) {}
                System.out.println("Помилка вводу. Введіть число від 0 до 4.");
            }

            if (mode == 0) {
                return;
            }

            System.out.println("\nЗапуск Рішення " + mode + " (15 ітерацій)...\n");
            for (int test = 1; test <= 15; test++) {
                System.out.println("--- Ітерація " + test + " ---");

                if (mode == 1) runAsymmetricPhilosopher();
                else if (mode == 2) runLimitedAccess();
                else if (mode == 3) runWaiters();
                else if (mode == 4) runTryLock();

                System.out.println("--- Ітерація " + test + " успішно завершена ---\n");
            }
        }
    }

    private void runAsymmetricPhilosopher() {
        int numPhilosophers = 5;
        Semaphore[] forks = new Semaphore[numPhilosophers];
        for (int i = 0; i < numPhilosophers; i++) {
            forks[i] = new Semaphore(1, true);
        }

        Semaphore completionSemaphore = new Semaphore(0, true);

        for (int i = 0; i < numPhilosophers; i++) {
            final int localId = i;
            new Thread(() -> taskAsymmetric(localId, forks, completionSemaphore)).start();
        }

        try {
            completionSemaphore.acquire(numPhilosophers);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void taskAsymmetric(int id, Semaphore[] forks, Semaphore completionSemaphore) {
        try {
            int rightFork = id;
            int leftFork = (id + 1) % 5;

            for (int i = 0; i < 10; i++) {
                System.out.println("Філософ " + (id + 1) + " думає " + (i + 1) + " раз");
                Thread.sleep(10);

                if (id == 4) {
                    forks[leftFork].acquire();
                    forks[rightFork].acquire();
                } else {
                    forks[rightFork].acquire();
                    forks[leftFork].acquire();
                }

                System.out.println("Філософ " + (id + 1) + " їсть " + (i + 1) + " раз");
                Thread.sleep(10);

                if (id == 4) {
                    forks[rightFork].release();
                    forks[leftFork].release();
                } else {
                    forks[leftFork].release();
                    forks[rightFork].release();
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } finally {
            completionSemaphore.release();
        }
    }

    private void runLimitedAccess() {
        int numPhilosophers = 5;
        Semaphore[] forks = new Semaphore[numPhilosophers];
        for (int i = 0; i < numPhilosophers; i++) {
            forks[i] = new Semaphore(1, true);
        }

        Semaphore completionSemaphore = new Semaphore(0, true);
        Semaphore limitSemaphore = new Semaphore(numPhilosophers - 1, true);

        for (int i = 0; i < numPhilosophers; i++) {
            final int localId = i;
            new Thread(() -> taskWithLimit(localId, forks, completionSemaphore, limitSemaphore)).start();
        }

        try {
            completionSemaphore.acquire(numPhilosophers);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void taskWithLimit(int id, Semaphore[] forks, Semaphore completionSemaphore, Semaphore limitSemaphore) {
        try {
            int rightFork = id;
            int leftFork = (id + 1) % 5;

            for (int i = 0; i < 10; i++) {
                System.out.println("Філософ " + (id + 1) + " думає " + (i + 1) + " раз");
                Thread.sleep(10);

                limitSemaphore.acquire();
                forks[rightFork].acquire();
                forks[leftFork].acquire();

                System.out.println("Філософ " + (id + 1) + " їсть " + (i + 1) + " раз");
                Thread.sleep(10);

                forks[leftFork].release();
                forks[rightFork].release();
                limitSemaphore.release();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } finally {
            completionSemaphore.release();
        }
    }

    private void runWaiters() {
        int numPhilosophers = 5;
        Semaphore[] forks = new Semaphore[numPhilosophers];
        for (int i = 0; i < numPhilosophers; i++) {
            forks[i] = new Semaphore(1, true);
        }

        Semaphore completionSemaphore = new Semaphore(0, true);
        Semaphore waitersSemaphore = new Semaphore(2, true);

        for (int i = 0; i < numPhilosophers; i++) {
            final int localId = i;
            new Thread(() -> taskWithWaiters(localId, forks, completionSemaphore, waitersSemaphore)).start();
        }

        try {
            completionSemaphore.acquire(numPhilosophers);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void taskWithWaiters(int id, Semaphore[] forks, Semaphore completionSemaphore, Semaphore waitersSemaphore) {
        try {
            int rightFork = id;
            int leftFork = (id + 1) % 5;

            for (int i = 0; i < 10; i++) {
                System.out.println("Філософ " + (id + 1) + " думає " + (i + 1) + " раз");
                Thread.sleep(10);

                waitersSemaphore.acquire();
                forks[rightFork].acquire();
                forks[leftFork].acquire();

                System.out.println("Філософ " + (id + 1) + " їсть " + (i + 1) + " раз");
                Thread.sleep(10);

                forks[leftFork].release();
                forks[rightFork].release();
                waitersSemaphore.release();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } finally {
            completionSemaphore.release();
        }
    }

    private void runTryLock() {
        int numPhilosophers = 5;
        Semaphore[] forks = new Semaphore[numPhilosophers];
        for (int i = 0; i < numPhilosophers; i++) {
            forks[i] = new Semaphore(1, true);
        }

        Semaphore completionSemaphore = new Semaphore(0, true);

        for (int i = 0; i < numPhilosophers; i++) {
            final int localId = i;
            new Thread(() -> taskTryLock(localId, forks, completionSemaphore)).start();
        }

        try {
            completionSemaphore.acquire(numPhilosophers);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void taskTryLock(int id, Semaphore[] forks, Semaphore completionSemaphore) {
        try {
            int rightFork = id;
            int leftFork = (id + 1) % 5;

            for (int i = 0; i < 10; i++) {
                System.out.println("Філософ " + (id + 1) + " думає " + (i + 1) + " раз");
                Thread.sleep(10);

                while (true) {
                    forks[rightFork].acquire();

                    if (forks[leftFork].tryAcquire()) {
                        break;
                    } else {
                        forks[rightFork].release();
                        Thread.sleep(5);
                    }
                }

                System.out.println("Філософ " + (id + 1) + " їсть " + (i + 1) + " раз");
                Thread.sleep(10);

                forks[leftFork].release();
                forks[rightFork].release();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } finally {
            completionSemaphore.release();
        }
    }
}